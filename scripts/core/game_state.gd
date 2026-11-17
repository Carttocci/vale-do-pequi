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

## Versão do formato dos dados salvos (ver SaveManager.migrate).
const DATA_VERSION := 1
const INVENTORY_SIZE := 27
const HOTBAR_SIZE := 9
const WATER_MAX := 20

const STARTING_ITEMS := [
    ["enxada", 1], ["regador", 1], ["semente_milho", 12], ["semente_feijao", 8],
]

var inventory := Inventory.new(INVENTORY_SIZE)
var selected_slot: int = 0
var day: int = 1
var water: int = WATER_MAX


func _ready() -> void:
    new_game()


## Estado de um jogo novo (mochila inicial, dia 1).
func new_game() -> void:
    inventory.clear()
    for entry: Array in STARTING_ITEMS:
        inventory.add(StringName(entry[0]), entry[1])
    day = 1
    water = WATER_MAX
    select_slot(0)
    water_changed.emit(water)
    day_changed.emit(day)


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

func use_water() -> bool:
    if water <= 0:
        return false
    water -= 1
    water_changed.emit(water)
    return true


func refill_water() -> void:
    water = WATER_MAX
    water_changed.emit(water)


# --- tempo -----------------------------------------------------------------

## Dormir: avança um dia. Quem cuida do crescimento escuta `day_advanced`.
## PROVISÓRIO: o relógio de verdade (horas, cansaço) entra na Fase 3.
func sleep() -> void:
    day += 1
    day_advanced.emit(day)
    day_changed.emit(day)


# --- save ------------------------------------------------------------------

func to_data() -> Dictionary:
    return {
        "day": day,
        "water": water,
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
    water = clampi(int(data.get("water", WATER_MAX)), 0, WATER_MAX)
    inventory.from_data(data.get("inventory", []))
    select_slot(int(data.get("selected_slot", 0)))
    water_changed.emit(water)
    day_changed.emit(day)


func reset() -> void:
    new_game()
