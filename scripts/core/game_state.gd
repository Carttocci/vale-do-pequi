extends Node
## Estado do jogador e do tempo (autoload "GameState").
##
## Guarda o que pertence ao jogador e não a um lugar do mapa: mochila,
## slot selecionado, água do regador e o dia atual. O estado dos lugares
## (terra plantada, baús, pés de pequi) fica nos próprios nós, que o
## SaveManager coleta pelo grupo "persistent".

## Número do dia mudou (UI). Também dispara ao carregar um save.
signal day_changed(day: int)
## Um dia PASSOU de verdade (dormir). Plantas crescem só com este sinal.
signal day_advanced(day: int)
signal selected_slot_changed(index: int)
signal water_changed(amount: int)
signal money_changed(amount: int)
signal skill_changed(skill: StringName, level: int, xp: int)
signal journal_changed
signal health_changed(value: int, max_value: int)
signal energy_changed(value: int, max_value: int)
signal fainted
signal flag_set(flag: StringName)
signal buff_changed(buff: StringName)
signal memories_changed(count: int)

## Versão do formato dos dados salvos (ver SaveManager.migrate).
const DATA_VERSION := 7
const INVENTORY_SIZE := 27
const HOTBAR_SIZE := 9
const WATER_MAX := 20
const STARTING_MONEY := 200
const MAX_HEALTH := 100
const MAX_ENERGY := 100
## Habilidades (GDD §15). XP acumulada → nível 0..10.
const SKILLS := [&"agricultura", &"pesca", &"caca", &"criacao", &"combate", &"mineracao", &"coleta", &"artesanato"]
const SKILL_NAMES := {&"agricultura": "Agricultura", &"pesca": "Pesca", &"caca": "Caça e rastreio",
    &"criacao": "Criação", &"combate": "Combate", &"mineracao": "Mineração", &"coleta": "Coleta", &"artesanato": "Artesanato"}
const LEVEL_XP := [0, 50, 150, 300, 500, 800, 1200, 1700, 2300, 3000, 4000]

const STARTING_ITEMS := [
    ["enxada", 1], ["regador", 1], ["semente_milho", 12], ["semente_feijao", 8],
]

var inventory := Inventory.new(INVENTORY_SIZE)
var selected_slot: int = 0
var day: int = 1
var water: int = WATER_MAX
var money: int = STARTING_MONEY
var skill_xp: Dictionary = {}
var health: int = MAX_HEALTH
var energy: int = MAX_ENERGY
## Caminhos de combate (GDD §10.3): pontos distribuídos, redistribuíveis.
var paths := {&"guerreiro": 0, &"cacador": 0, &"explorador": 0}
## Marcos da história e do mundo (ex.: "trilha_serra_aberta", "guardiao_derrotado").
var flags: Dictionary = {}
## Peixes pescados: id -> quantidade. Caderno de campo: espécie -> true.
var fish_log: Dictionary = {}
var species_seen: Dictionary = {}
## Efeito de comida até dormir: "combate", "folego", "rapidez", "pesca" (vazio = nenhum).
var buff: StringName = &""
## Lembranças do vale: tradições vividas (receitas, festas, histórias dos moradores).
var memories: int = 0
## Receitas que o jogador sabe fazer (id -> true).
var known_recipes: Dictionary = {}


func _ready() -> void:
    new_game()


## Estado de um jogo novo (mochila inicial, dia 1).
func new_game() -> void:
    inventory.clear()
    for entry: Array in STARTING_ITEMS:
        inventory.add(StringName(entry[0]), entry[1])
    day = 1
    water = WATER_MAX
    money = STARTING_MONEY
    skill_xp = {}
    fish_log = {}
    species_seen = {}
    health = MAX_HEALTH
    energy = MAX_ENERGY
    paths = {&"guerreiro": 0, &"cacador": 0, &"explorador": 0}
    flags = {}
    buff = &""
    memories = 0
    known_recipes = {}
    for r in Recipes.starting_known():
        known_recipes[r] = true
    Clock.reset()
    var quests := get_node_or_null("/root/Quests")
    if quests:
        quests.reset()
    select_slot(0)
    water_changed.emit(water)
    money_changed.emit(money)
    health_changed.emit(health, MAX_HEALTH)
    energy_changed.emit(energy, MAX_ENERGY)
    day_changed.emit(day)


# --- vida e energia ----------------------------------------------------------

## Gasta energia de ferramenta/esquiva. Sem energia suficiente não faz nada.
func use_energy(amount: int) -> bool:
    if amount <= 0:
        return true
    if buff == &"folego":
        amount = ceili(amount / 2.0)
    if energy < amount:
        EventBus.show_message("Você está sem energia. Coma alguma coisa ou durma.", 2.0)
        return false
    energy -= amount
    energy_changed.emit(energy, MAX_ENERGY)
    return true


func restore(hp: int, en: int) -> void:
    health = clampi(health + hp, 0, MAX_HEALTH)
    energy = clampi(energy + en, 0, MAX_ENERGY)
    health_changed.emit(health, MAX_HEALTH)
    energy_changed.emit(energy, MAX_ENERGY)


func damage(amount: int) -> void:
    if health <= 0:
        return
    health = maxi(0, health - amount)
    health_changed.emit(health, MAX_HEALTH)
    if health == 0:
        fainted.emit()


# --- marcos da história -------------------------------------------------------

func set_flag(flag: StringName, value: Variant = true) -> void:
    flags[flag] = value
    flag_set.emit(flag)


func has_flag(flag: StringName) -> bool:
    return flags.has(flag) and flags[flag] != false


func get_flag(flag: StringName, default: Variant = null) -> Variant:
    return flags.get(flag, default)


# --- caminhos de combate -----------------------------------------------------

func path_points_total() -> int:
    return skill_level(&"combate")


func path_points_free() -> int:
    var used := 0
    for k in paths:
        used += int(paths[k])
    return path_points_total() - used


func add_path_point(path: StringName) -> bool:
    if not paths.has(path) or path_points_free() <= 0:
        return false
    paths[path] += 1
    journal_changed.emit()
    return true


func reset_paths() -> void:
    for k in paths:
        paths[k] = 0
    journal_changed.emit()


## Multiplicador de dano corpo a corpo: nível de combate + Guerreiro.
func melee_multiplier() -> float:
    return (1.0 + skill_level(&"combate") * 0.04 + int(paths[&"guerreiro"]) * 0.08) * (1.25 if buff == &"combate" else 1.0)


func ranged_multiplier() -> float:
    return (1.0 + skill_level(&"combate") * 0.04 + int(paths[&"cacador"]) * 0.12) * (1.25 if buff == &"combate" else 1.0)


## Defesa (fração de dano evitada).
func defense() -> float:
    return minf(0.5, int(paths[&"guerreiro"]) * 0.04)


# --- habilidades e registros ----------------------------------------------

static func level_for_xp(xp: int) -> int:
    var lvl := 0
    for i in LEVEL_XP.size():
        if xp >= LEVEL_XP[i]:
            lvl = i
    return mini(lvl, 10)


func skill_level(skill: StringName) -> int:
    return level_for_xp(int(skill_xp.get(skill, 0)))


func add_xp(skill: StringName, amount: int) -> void:
    var before := skill_level(skill)
    skill_xp[skill] = int(skill_xp.get(skill, 0)) + amount
    var after := skill_level(skill)
    skill_changed.emit(skill, after, skill_xp[skill])
    if after > before:
        EventBus.show_message("%s subiu para o nível %d!" % [SKILL_NAMES.get(skill, String(skill)), after], 3.0)


func log_fish(id: StringName) -> bool:
    var first := not fish_log.has(id)
    fish_log[id] = int(fish_log.get(id, 0)) + 1
    journal_changed.emit()
    return first


func log_species(id: StringName) -> bool:
    if species_seen.has(id):
        return false
    species_seen[id] = true
    journal_changed.emit()
    return true


# --- dinheiro --------------------------------------------------------------

func add_money(amount: int) -> void:
    money += amount
    money_changed.emit(money)


## Gasta se tiver. Retorna false (sem gastar) se não tiver o suficiente.
func spend_money(amount: int) -> bool:
    if amount > money:
        return false
    money -= amount
    money_changed.emit(money)
    return true


# --- itens -----------------------------------------------------------------

## Adiciona à mochila. Retorna o total que o jogador tem depois.
## Se não couber tudo, o que sobrou não entra (use space_for antes).
func add_item(item_id: StringName, amount: int = 1) -> int:
    assert(amount > 0, "add_item: quantidade precisa ser positiva")
    var left := inventory.add(item_id, amount)
    var added := amount - left
    var total := inventory.count_of(item_id)
    if added > 0:
        EventBus.item_collected.emit(item_id, added, total)
    if left > 0:
        EventBus.show_message("Mochila cheia!", 2.0)
    return total


func space_for(item_id: StringName) -> int:
    return inventory.space_for(item_id)


func get_item_count(item_id: StringName) -> int:
    return inventory.count_of(item_id)


func select_slot(index: int) -> void:
    selected_slot = posmod(index, HOTBAR_SIZE)
    selected_slot_changed.emit(selected_slot)


func get_selected_item() -> ItemData:
    var id := inventory.get_item_id(selected_slot)
    return ItemDB.get_item(id) if id != &"" else null


## Gasta 1 unidade do item no slot selecionado (ex.: semente plantada).
func consume_selected(count: int = 1) -> bool:
    return inventory.remove_from_slot(selected_slot, count) == count


# --- regador ---------------------------------------------------------------

## Caixa d'água (obra da fazenda) dobra a capacidade do regador.
func water_max() -> int:
    return WATER_MAX * 2 if has_flag(&"obra_caixa_dagua") else WATER_MAX


func use_water() -> bool:
    if water <= 0:
        return false
    water -= 1
    water_changed.emit(water)
    return true


func refill_water() -> void:
    water = water_max()
    water_changed.emit(water)


# --- tempo -----------------------------------------------------------------

## Dormir: avança um dia. Quem cuida do crescimento escuta `day_advanced`.
func sleep() -> void:
    day += 1
    set_buff(&"")
    health = MAX_HEALTH
    energy = MAX_ENERGY
    health_changed.emit(health, MAX_HEALTH)
    energy_changed.emit(energy, MAX_ENERGY)
    day_advanced.emit(day)   # 1º: plantas regadas ontem crescem
    Clock.start_day(day)     # 2º: 06:00, clima novo (chuva rega tudo)
    day_changed.emit(day)


# --- save ------------------------------------------------------------------

func to_data() -> Dictionary:
    return {
        "day": day,
        "water": water,
        "money": money,
        "skills": skill_xp.duplicate(),
        "health": health,
        "energy": energy,
        "paths": {"guerreiro": paths[&"guerreiro"], "cacador": paths[&"cacador"], "explorador": paths[&"explorador"]},
        "flags": _flags_to_data(),
        "fish_log": fish_log.duplicate(),
        "buff": String(buff),
        "memories": memories,
        "known_recipes": known_recipes.keys().map(func(k: StringName) -> String: return String(k)),
        "species_seen": species_seen.keys().map(func(k: StringName) -> String: return String(k)),
        "selected_slot": selected_slot,
        "inventory": inventory.to_data(),
    }


## Campos que faltarem no save ficam com o valor de jogo novo.
func from_data(data: Dictionary) -> void:
    new_game()
    if not data.has("inventory"):
        data = data.duplicate()
        data["inventory"] = inventory.to_data()
    day = maxi(1, int(data.get("day", 1)))
    money = maxi(0, int(data.get("money", STARTING_MONEY)))
    skill_xp = {}
    for k in data.get("skills", {}):
        skill_xp[StringName(k)] = int(data.skills[k])
    fish_log = {}
    for k in data.get("fish_log", {}):
        fish_log[StringName(k)] = int(data.fish_log[k])
    species_seen = {}
    for k in data.get("species_seen", []):
        species_seen[StringName(k)] = true
    health = clampi(int(data.get("health", MAX_HEALTH)), 1, MAX_HEALTH)
    energy = clampi(int(data.get("energy", MAX_ENERGY)), 0, MAX_ENERGY)
    flags = {}
    var fd: Dictionary = data.get("flags", {})
    for k in fd:
        flags[StringName(k)] = fd[k]
    water = clampi(int(data.get("water", WATER_MAX)), 0, water_max())
    buff = StringName(data.get("buff", ""))
    memories = maxi(0, int(data.get("memories", 0)))
    if data.has("known_recipes"):
        known_recipes = {}
        for k in data.known_recipes:
            known_recipes[StringName(k)] = true
    var pd: Dictionary = data.get("paths", {})
    for k in paths:
        paths[k] = maxi(0, int(pd.get(String(k), 0)))
    health_changed.emit(health, MAX_HEALTH)
    energy_changed.emit(energy, MAX_ENERGY)
    inventory.from_data(data.get("inventory", []))
    select_slot(int(data.get("selected_slot", 0)))
    water_changed.emit(water)
    money_changed.emit(money)
    day_changed.emit(day)


func reset() -> void:
    new_game()


func _flags_to_data() -> Dictionary:
    var out := {}
    for k in flags:
        out[String(k)] = flags[k]
    return out



# --- comida, efeitos e lembranças --------------------------------------------

const BUFF_NAMES := {&"combate": "Valentia (+25% de dano)", &"folego": "Fôlego (ferramentas gastam metade)",
    &"rapidez": "Pernas leves (+20% de velocidade)", &"pesca": "Paciência (peixe morde mais rápido)"}


## Come o item: recupera vida/energia e aplica o efeito (até dormir).
func eat(item: ItemData) -> bool:
    if item == null or item.category != ItemData.Category.FOOD:
        return false
    restore(item.health, item.energy)
    Audio.play(&"comer")
    if item.buff != &"":
        set_buff(item.buff)
    EventBus.show_message("Comeu %s. +%d energia%s" % [item.display_name.to_lower(), item.energy,
        ("  · " + BUFF_NAMES.get(item.buff, "")) if item.buff != &"" else ""], 2.5)
    return true


func set_buff(b: StringName) -> void:
    if buff == b:
        return
    buff = b
    buff_changed.emit(buff)


func speed_multiplier() -> float:
    return 1.2 if buff == &"rapidez" else 1.0


## Uma lembrança nova do vale (cada `key` conta uma vez só). Retorna true se for nova.
func add_memory(key: String, text: String) -> bool:
    var flag := StringName("lembranca_" + key)
    if has_flag(flag):
        return false
    flags[flag] = true
    memories += 1
    memories_changed.emit(memories)
    EventBus.show_message("✦ Lembrança do vale: %s" % text, 3.5)
    return true


func knows_recipe(id: StringName) -> bool:
    return known_recipes.has(id)


func learn_recipe(id: StringName) -> bool:
    if known_recipes.has(id):
        return false
    known_recipes[id] = true
    journal_changed.emit()
    return true
