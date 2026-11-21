class_name Ranch
extends Node2D
## Criação da fazenda: galinheiro (galinhas → ovos) e curral (vacas → leite).
##
## Criar aos poucos: a Mariana vende **filhotes** (pintinho, bezerro) e o touro.
## Filhote cresce (pintinho 5 dias, bezerro 10) e só adulto produz.
## Cada cercado tem comedouro (ração/milho), bebedouro (regador; a chuva enche)
## e porteira. Bicho alimentado, com água e carinho fica feliz e produz mais.
## Galinhas felizes às vezes chocam um pintinho; vaca feliz com touro no curral
## às vezes tem bezerro.
##
## Ataques: em algumas noites (mais em tempestade, na lua nova e depois do Ato 1)
## criaturas do Silêncio vêm da mata atrás do rebanho. Na fazenda você defende
## no braço; longe (ou dormindo), conta a defesa: porteira fechada, lampiões
## perto do cercado e o cachorro. O que acontece com o bicho varia: pode só se
## assustar, sair ferido, fugir ferido pra mata (dá pra buscar em 3 dias) ou morrer.

signal raid_started(pen: StringName)
signal raid_ended(won: bool)

const FEED_MAX := 20
const WATER_MAX := 10
const FEED_ITEMS := [&"racao", &"milho"]
const ANIMALS := {
    &"galinha": {"name": "Galinha", "price": 120, "product": &"ovo", "pen": &"galinheiro", "capacity": 6, "grow": 5,
        "sprite": "res://assets/animals/galinha_placeholder.png", "young_sprite": "res://assets/animals/pintinho_placeholder.png",
        "young_name": "Pintinho"},
    &"vaca": {"name": "Vaca", "price": 600, "product": &"leite", "pen": &"curral", "capacity": 4, "grow": 10,
        "sprite": "res://assets/animals/vaca_placeholder.png", "young_sprite": "res://assets/animals/bezerro_placeholder.png",
        "young_name": "Bezerro"},
    &"touro": {"name": "Touro", "price": 900, "product": &"", "pen": &"curral", "capacity": 4, "grow": 0,
        "sprite": "res://assets/animals/touro_placeholder.png"},
}
## O que a Mariana vende (filhotes e touro).
const BUYABLE := {
    &"pintinho": {"kind": &"galinha", "young": true, "price": 60, "name": "Pintinho"},
    &"bezerro": {"kind": &"vaca", "young": true, "price": 300, "name": "Bezerro"},
    &"touro": {"kind": &"touro", "young": false, "price": 900, "name": "Touro"},
}
const NAMES := {
    &"galinha": ["Penosa", "Cocó", "Pintada", "Carijó", "Galega", "Branquinha", "Ruiva", "Chiquinha", "Clotilde", "Fofinha", "Zefa", "Nega"],
    &"vaca": ["Mimosa", "Estrela", "Malhada", "Flor", "Boneca", "Jabuticaba", "Princesa", "Malhadinha"],
    &"touro": ["Valente", "Trovão", "Bravo", "Sultão"],
}
const GATE_POS := {&"galinheiro": Vector2(600, 140), &"curral": Vector2(756, 138)}
const GATE_HP := 40
const RAID_SIZES := {
    &"pequeno": {"strength": 2, "enemies": [&"raiz_torta", &"lodo_cinza"]},
    &"medio": {"strength": 4, "enemies": [&"raiz_torta", &"lobo_sombra", &"coruja_sombra"]},
    &"grande": {"strength": 6, "enemies": [&"lobo_sombra", &"javali_corrompido", &"raiz_torta", &"coruja_sombra"]},
}

@export var chicken_pen := Rect2(572, 96, 120, 28)
@export var cow_pen := Rect2(736, 64, 180, 56)
@export var chicken_feeder_path: NodePath
@export var cow_feeder_path: NodePath
@export var coop_path: NodePath

## [{"kind", "name", "young", "age", "happiness", "pet_day", "health", "status", "status_days"}]
## status: "ok", "ferido" (cura sozinho, não produz), "assustado" (não produz uns dias)
var animals: Array = []
## Bichos que fugiram pra mata: registro + "lost_day", "x", "y".
var lost: Array = []
var feed := {&"galinheiro": 0, &"curral": 0}
var water := {&"galinheiro": 0, &"curral": 0}
var gates := {&"galinheiro": {"closed": false, "hp": GATE_HP}, &"curral": {"closed": false, "hp": GATE_HP}}
var pickups: Array = []   # [{"item", "x", "y"}]
## Ataque planejado pra noite: {"day", "time", "size", "pen", "warned", "started", "resolved"}
var raid: Dictionary = {}
var report := ""          # notícia da noite, mostrada de manhã
var dog_pet_day := 0

## Testes: desligar sorteios (reprodução e ataques).
var breeding_enabled := true
var raids_enabled := true

var dog: Dog
var gate_props := {}
var trough_props := {}
var _raiders: Array = []
var _raid_hits := 0
var _rng := RandomNumberGenerator.new()
@onready var chicken_feeder: Node2D = get_node(chicken_feeder_path)
@onready var cow_feeder: Node2D = get_node(cow_feeder_path)
@onready var coop: Node2D = get_node(coop_path)


func _ready() -> void:
    add_to_group("persistent")
    add_to_group("item_target")
    add_to_group("ranch")
    y_sort_enabled = true
    _rng.randomize()
    GameState.day_advanced.connect(func(_d: int) -> void: advance_day())
    Clock.day_started.connect(func(_d: int, _w: int) -> void: _on_day_started())
    Clock.time_changed.connect(_on_time_changed)
    for feeder in [chicken_feeder, cow_feeder]:
        var it: Interactable = feeder.get_node("Interactable")
        it.interacted.connect(_on_feeder_interacted.bind(feeder))
    coop.get_node("Interactable").interacted.connect(func(_a: Node) -> void: show_status())
    _build_props()
    dog = Dog.new()
    dog.name = "Cachorro"
    dog.ranch = self
    dog.position = coop.position + Vector2(-60, 40)
    get_parent().add_child.call_deferred(dog)
    _rebuild()


func _build_props() -> void:
    for pen: StringName in GATE_POS:
        var g := Prop.new().setup("porteira_aberta", Vector2.ZERO, "Fechar porteira", 14.0)
        g.name = "Porteira_" + String(pen)
        g.position = GATE_POS[pen]
        g.used.connect(func(_a: Node) -> void: toggle_gate(pen))
        get_parent().add_child.call_deferred(g)
        gate_props[pen] = g
        var t := Prop.new().setup("bebedouro", Vector2.ZERO, "Ver bebedouro", 12.0)
        t.name = "Bebedouro_" + String(pen)
        t.position = feeder_for(pen).position + Vector2(22, 0)
        t.used.connect(func(_a: Node) -> void:
            EventBus.show_message("Bebedouro: %d/%d. Encha com o regador na mão (a chuva também enche)." % [water[pen], WATER_MAX], 2.5))
        get_parent().add_child.call_deferred(t)
        trough_props[pen] = t


# --- consulta -------------------------------------------------------------------

func pen_of(kind: StringName) -> StringName:
    return ANIMALS[kind].pen


func pen_rect(pen: StringName) -> Rect2:
    return chicken_pen if pen == &"galinheiro" else cow_pen


## Lugares no cercado (obras da fazenda aumentam). Touro divide o curral com as vacas.
func capacity(kind: StringName) -> int:
    var pen := pen_of(kind)
    if pen == &"galinheiro":
        return 10 if GameState.has_flag(&"obra_galinheiro_maior") else int(ANIMALS[&"galinha"].capacity)
    return 6 if GameState.has_flag(&"obra_curral_maior") else int(ANIMALS[&"vaca"].capacity)


func count(kind: StringName) -> int:
    return animals.filter(func(a: Dictionary) -> bool: return a.kind == kind).size()


func pen_count(pen: StringName) -> int:
    return animals.filter(func(a: Dictionary) -> bool: return pen_of(a.kind) == pen).size()


func can_buy(kind: StringName) -> bool:
    var k: StringName = BUYABLE[kind].kind if BUYABLE.has(kind) else kind
    return ANIMALS.has(k) and pen_count(pen_of(k)) < capacity(k)


func display_name_of(a: Dictionary) -> String:
    var info: Dictionary = ANIMALS[a.kind]
    return "%s (%s)" % [a.name, (info.young_name if a.young else info.name).to_lower()]


## Compra (já pago) ou nascimento: o animal aparece no cercado.
## `kind` pode ser um tipo (galinha, vaca, touro) ou um item da Mariana (pintinho, bezerro).
func add_animal(kind: StringName, young: bool = false) -> bool:
    if BUYABLE.has(kind) and not ANIMALS.has(kind):
        young = BUYABLE[kind].young
        kind = BUYABLE[kind].kind
    if not can_buy(kind):
        return false
    animals.append(_new_record(kind, young))
    _rebuild()
    return true


func _new_record(kind: StringName, young: bool) -> Dictionary:
    return {"kind": kind, "name": _pick_name(kind), "young": young, "age": 0, "happiness": 50, "pet_day": 0,
        "health": 100, "status": "ok", "status_days": 0}


func _pick_name(kind: StringName) -> String:
    var used := animals.map(func(a: Dictionary) -> String: return a.name)
    for n in NAMES[kind]:
        if not n in used:
            return n
    return "%s %d" % [NAMES[kind][0], animals.size() + 1]


func feeder_for(pen: StringName) -> Node2D:
    return chicken_feeder if pen == &"galinheiro" else cow_feeder


# --- o dia a dia ------------------------------------------------------------------

func advance_day() -> void:
    _resolve_pending_raid()
    var born := {&"galinheiro": false, &"curral": false}
    for a: Dictionary in animals.duplicate():
        var info: Dictionary = ANIMALS[a.kind]
        var pen: StringName = info.pen
        a.age = int(a.age) + 1
        var was_young: bool = a.young
        if a.young and a.age >= int(info.grow):
            a.young = false
            report += "%s cresceu e virou %s! " % [a.name, info.name.to_lower()]
        var fed: bool = feed[pen] > 0
        var drank: bool = water[pen] > 0
        if fed:
            feed[pen] -= 1
            a.happiness = mini(100, int(a.happiness) + 5)
        else:
            a.happiness = maxi(0, int(a.happiness) - 15)
        if drank:
            water[pen] -= 1
            a.happiness = mini(100, int(a.happiness) + 3)
        else:
            a.happiness = maxi(0, int(a.happiness) - 10)
        match String(a.status):
            "ferido":
                a.health = mini(100, int(a.health) + 20)
                if a.health >= 100:
                    a.status = "ok"
            "assustado":
                a.status_days = int(a.status_days) - 1
                if a.status_days <= 0:
                    a.status = "ok"
        var producer: bool = info.product != &"" and not was_young
        if producer and fed and drank and a.status == "ok" \
                and _rng.randf() < 0.6 + int(a.happiness) * 0.004:
            var rect := pen_rect(pen)
            pickups.append({"item": String(info.product),
                "x": _rng.randf_range(rect.position.x, rect.end.x), "y": _rng.randf_range(rect.position.y, rect.end.y)})
        if breeding_enabled and not born[pen] and _try_breed(a):
            born[pen] = true
    _rebuild()


## Galinha feliz choca (precisa de outra galinha); vaca feliz com touro tem bezerro.
func _try_breed(a: Dictionary) -> bool:
    if a.young or a.status != "ok" or int(a.happiness) < 70:
        return false
    var pen := pen_of(a.kind)
    if pen_count(pen) >= capacity(a.kind):
        return false
    var adults := animals.filter(func(b: Dictionary) -> bool: return b.kind == a.kind and not b.young).size()
    if a.kind == &"galinha" and adults >= 2 and _rng.randf() < 0.06:
        animals.append(_new_record(&"galinha", true))
        report += "%s chocou: nasceu um pintinho! " % a.name
        return true
    if a.kind == &"vaca" and count(&"touro") > 0 and _rng.randf() < 0.04:
        animals.append(_new_record(&"vaca", true))
        report += "Nasceu um bezerro da %s! " % a.name
        return true
    return false


func _on_day_started() -> void:
    if Clock.is_raining():
        for pen in water:
            water[pen] = WATER_MAX
    for pen in gates:
        if gates[pen].hp > 0:
            gates[pen].closed = false  # de manhã os bichos saem pro pasto
    _expire_lost()
    _plan_raid()
    _update_props()
    if report != "":
        EventBus.show_message(report.strip_edges(), 6.0)
        report = ""


# --- comedouro e bebedouro (grupo item_target) ----------------------------------------

func get_item_action(item: ItemData, target_pos: Vector2, _actor: Node) -> Dictionary:
    if item == null:
        return {}
    if item.tool_type == ItemData.ToolType.WATERING_CAN:
        var tp := _trough_near(target_pos)
        if tp != &"" and water[tp] < WATER_MAX:
            return {"prompt": "Encher bebedouro (%d/%d)" % [water[tp], WATER_MAX], "priority": 22}
        return {}
    if item.id == &"madeira":
        var gp := _gate_near(target_pos)
        if gp != &"" and gates[gp].hp <= 0:
            return {"prompt": "Consertar porteira (2 madeiras)", "priority": 22}
        return {}
    if not item.id in FEED_ITEMS:
        return {}
    var pen := _pen_near(target_pos)
    if pen == &"" or feed[pen] >= FEED_MAX:
        return {}
    return {"prompt": "Pôr no comedouro (%d/%d)" % [feed[pen], FEED_MAX], "priority": 22}


func use_item(item: ItemData, target_pos: Vector2, _actor: Node) -> bool:
    if get_item_action(item, target_pos, null).is_empty():
        return false
    if item.tool_type == ItemData.ToolType.WATERING_CAN:
        if not GameState.use_water():
            EventBus.show_message("O regador está vazio. Encha no poço.", 2.0)
            return false
        var tp := _trough_near(target_pos)
        water[tp] = WATER_MAX
        Audio.play(&"regar")
        _update_props()
        return true
    if item.id == &"madeira":
        if GameState.get_item_count(&"madeira") < 2:
            EventBus.show_message("Precisa de 2 madeiras.", 2.0)
            return false
        GameState.inventory.remove(&"madeira", 2)
        var gp := _gate_near(target_pos)
        gates[gp].hp = GATE_HP
        gates[gp].closed = false
        _update_props()
        EventBus.show_message("Porteira consertada.", 2.0)
        return true
    var pen := _pen_near(target_pos)
    if not GameState.consume_selected(1):
        return false
    feed[pen] += 1
    _update_props()
    return true


func _pen_near(pos: Vector2) -> StringName:
    if not chicken_feeder.is_visible_in_tree():
        return &""  # jogador em outra região
    if pos.distance_to(chicken_feeder.global_position + Vector2(0, -4)) < 16.0:
        return &"galinheiro"
    if pos.distance_to(cow_feeder.global_position + Vector2(0, -4)) < 16.0:
        return &"curral"
    return &""


func _trough_near(pos: Vector2) -> StringName:
    if not chicken_feeder.is_visible_in_tree():
        return &""
    for pen: StringName in trough_props:
        if is_instance_valid(trough_props[pen]) and pos.distance_to(trough_props[pen].global_position + Vector2(0, -4)) < 16.0:
            return pen
    return &""


func _gate_near(pos: Vector2) -> StringName:
    if not chicken_feeder.is_visible_in_tree():
        return &""
    for pen: StringName in gate_props:
        if is_instance_valid(gate_props[pen]) and pos.distance_to(gate_props[pen].global_position + Vector2(0, -6)) < 18.0:
            return pen
    return &""


func _on_feeder_interacted(_a: Node, feeder: Node2D) -> void:
    var pen := &"galinheiro" if feeder == chicken_feeder else &"curral"
    EventBus.show_message("Comedouro: %d porções. Ponha ração ou milho (com o item na mão, E)." % feed[pen], 2.5)


## Galinheiro (E): lista os bichos, como estão e o que falta.
func show_status() -> void:
    var lines := PackedStringArray()
    if animals.is_empty():
        lines.append("Ninguém aqui ainda. A Mariana (clínica da vila) vende pintinho, bezerro e touro.")
    for a: Dictionary in animals:
        var st := "feliz" if int(a.happiness) >= 70 else ("ok" if int(a.happiness) >= 40 else "triste")
        if a.status == "ferido":
            st += ", ferido (%d%%)" % int(a.health)
        elif a.status == "assustado":
            st += ", assustado"
        if a.young:
            st += ", cresce em %d dias" % maxi(0, int(ANIMALS[a.kind].grow) - int(a.age))
        lines.append("%s: %s" % [display_name_of(a), st])
    for l: Dictionary in lost:
        lines.append("%s: fugiu pra Mata dos Ipês!" % l.name)
    lines.append("Galinheiro: comida %d, água %d. Curral: comida %d, água %d." % [
        feed[&"galinheiro"], water[&"galinheiro"], feed[&"curral"], water[&"curral"]])
    EventBus.dialogue_requested.emit("Criação", lines, PackedStringArray(), Callable())


# --- porteiras ----------------------------------------------------------------------

func toggle_gate(pen: StringName) -> void:
    if gates[pen].hp <= 0:
        EventBus.show_message("Porteira quebrada! Com 2 madeiras na mão, E pra consertar.", 2.5)
        return
    gates[pen].closed = not gates[pen].closed
    Audio.play(&"porta")
    _update_props()


func _update_props() -> void:
    for pen: StringName in gate_props:
        var g: Prop = gate_props[pen]
        if not is_instance_valid(g) or g.sprite == null:
            continue
        var broken: bool = gates[pen].hp <= 0
        g.set_texture("porteira_quebrada" if broken else ("porteira_fechada" if gates[pen].closed else "porteira_aberta"))
        g.interactable.prompt = "Porteira quebrada" if broken else ("Abrir porteira" if gates[pen].closed else "Fechar porteira")
    for pen: StringName in trough_props:
        var t: Prop = trough_props[pen]
        if is_instance_valid(t) and t.sprite:
            t.set_texture("bebedouro_cheio" if water[pen] > 0 else "bebedouro")
    for pen in [&"galinheiro", &"curral"]:
        var spr: Sprite2D = feeder_for(pen).get_node("Sprite")
        spr.texture = load("res://assets/environments/comedouro_cheio_placeholder.png" if feed[pen] > 0
            else "res://assets/environments/comedouro_placeholder.png")


# --- ataques ------------------------------------------------------------------------

## Sorteia se hoje à noite vem ataque, de que tamanho, em que hora e em que cercado.
func _plan_raid() -> void:
    raid = {}
    if not raids_enabled or animals.is_empty() or GameState.day < 4:
        return
    var adults := animals.size()
    var chance := 0.08 + 0.02 * mini(adults, 10)
    if GameState.has_flag(&"ato1_completo"):
        chance += 0.08
    if Clock.weather == Clock.Weather.TEMPESTADE:
        chance += 0.15
    if Calendar.day_of_month(GameState.day) == 1:
        chance += 0.1  # lua nova
    if _rng.randf() >= chance:
        return
    plan_raid_now()


## Marca ataque pra esta noite (testes também usam).
func plan_raid_now(size: StringName = &"", pen: StringName = &"", time: int = -1) -> void:
    var pens := [&"galinheiro", &"curral"].filter(func(p: StringName) -> bool: return pen_count(p) > 0)
    if pens.is_empty():
        return
    if size == &"":
        var r := _rng.randf()
        size = &"pequeno" if r < 0.6 else (&"medio" if r < 0.9 else &"grande")
    raid = {"day": GameState.day, "time": time if time >= 0 else _rng.randi_range(20 * 60, 25 * 60),
        "size": String(size), "pen": String(pen if pen != &"" else pens[_rng.randi() % pens.size()]),
        "warned": false, "started": false, "resolved": false}


func _on_time_changed(minutes: int) -> void:
    if raid.is_empty() or raid.resolved or raid.started or int(raid.day) != GameState.day:
        return
    var on_farm := _player_on_farm()
    if not raid.warned and minutes >= int(raid.time) - 30:
        raid.warned = true
        if on_farm:
            if dog:
                dog.bark()
            EventBus.show_message("O Pipoca está latindo pra mata... tem alguma coisa vindo atrás da criação!", 4.0)
    if minutes >= int(raid.time):
        if on_farm:
            start_live_raid()
        else:
            simulate_raid()


func _player_on_farm() -> bool:
    var main := get_tree().get_first_node_in_group("save_root")
    return main != null and "level" in main and main.level != null and main.level.is_ancestor_of(self)


## Ataque com você na fazenda: as criaturas saem da mata e vão atrás do cercado.
func start_live_raid() -> void:
    raid.started = true
    _raid_hits = 0
    var pen := StringName(raid.pen)
    var level := _level()
    var center := pen_rect(pen).get_center()
    var info: Dictionary = RAID_SIZES[StringName(raid.size)]
    var n: int = int(info.strength) / 2 + 1
    _raiders.clear()
    for i in n:
        var kind: StringName = info.enemies[i % info.enemies.size()]
        var pos := _spawn_point(level, center)
        var e := Enemy.new().setup(kind, pos, level, 1.0)
        e.raid_ranch = self
        e.raid_pen = pen
        e.died.connect(func(_x: Enemy) -> void: _on_raider_died())
        get_parent().add_child(e)
        _raiders.append(e)
    Audio.play(&"chefe")
    EventBus.show_message("Criaturas do Silêncio atacando o %s! Defenda a criação!" % String(pen), 3.5)
    raid_started.emit(pen)


func _spawn_point(level: Level, center: Vector2) -> Vector2:
    var player := get_tree().get_first_node_in_group("player") as Node2D
    for i in 40:
        var p := center + Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(150.0, 230.0)
        if level == null or (level.get_world_rect().has_point(p) and level.is_walkable(p)):
            if player == null or player.global_position.distance_to(p) > 90.0:
                return p
    return center + Vector2(0, -180)


func _level() -> Level:
    var n := get_parent()
    while n and not n is Level:
        n = n.get_parent()
    return n as Level


## Alvo de um atacante: a porteira (se fechada e inteira); senão um bicho do cercado.
func raid_target(pen: StringName) -> Node2D:
    if gates[pen].closed and gates[pen].hp > 0 and is_instance_valid(gate_props.get(pen)):
        return gate_props[pen]
    var list := get_children().filter(func(c: Node) -> bool: return c is FarmAnimal and pen_of(c.kind) == pen)
    if list.is_empty():
        return null
    return list[_rng.randi() % list.size()]


## Um atacante acertou a porteira ou um bicho.
func raid_hit(target: Node2D, damage: int) -> void:
    if target is Prop:
        for pen: StringName in gate_props:
            if gate_props[pen] == target:
                gates[pen].hp = maxi(0, int(gates[pen].hp) - damage)
                FX.burst(get_parent(), target.position + Vector2(0, -6), FX.WOOD, 5)
                Audio.play(&"acerto")
                if gates[pen].hp <= 0:
                    gates[pen].closed = false
                    EventBus.show_message("Quebraram a porteira do %s!" % String(pen), 2.5)
                _update_props()
        return
    if target is FarmAnimal:
        var a: Dictionary = target.record
        _raid_hits += 1
        a.health = maxi(0, int(a.health) - damage)
        FX.damage_number(self, target.position, damage, Color(1, 0.6, 0.5))
        target.flash()
        if a.health <= 0:
            _harm(a, true)
            _rebuild()


## O bicho levou a pior: varia entre morrer, fugir ferido ou ficar ferido.
func _harm(a: Dictionary, knocked_out: bool) -> void:
    var r := _rng.randf()
    var die := 0.3 if knocked_out else 0.25
    var flee := die + (0.45 if knocked_out else 0.4)
    if r < die:
        animals.erase(a)
        report += "%s não resistiu ao ataque. " % a.name
        EventBus.show_message("%s não resistiu..." % a.name, 3.0)
    elif r < flee:
        animals.erase(a)
        a.status = "ferido"
        a.health = 30
        var spot := _lost_spot()
        a.lost_day = GameState.day
        a.x = spot.x
        a.y = spot.y
        lost.append(a)
        report += "%s fugiu ferido(a) pra Mata dos Ipês. " % a.name
        EventBus.show_message("%s fugiu assustado(a) pra mata!" % a.name, 3.0)
        _spawn_lost_nodes()
    else:
        a.status = "ferido"
        a.health = maxi(10, int(a.health))
        report += "%s ficou ferido(a). " % a.name


func _on_raider_died() -> void:
    _raiders = _raiders.filter(func(e: Variant) -> bool: return is_instance_valid(e) and not e.is_dead())
    if not _raiders.is_empty() or raid.is_empty() or raid.resolved:
        return
    raid.resolved = true
    var pen := StringName(raid.pen)
    for a: Dictionary in animals:
        if pen_of(a.kind) == pen:
            if _raid_hits > 0 and a.status == "ok":
                a.status = "assustado"
                a.status_days = 1
            a.happiness = mini(100, int(a.happiness) + 5)
    GameState.add_xp(&"combate", 15)
    EventBus.show_message("Você defendeu a criação! ✦", 3.0)
    _rebuild()
    raid_ended.emit(true)


## Ataque sem você por perto: decide pela defesa (porteira, lampiões, cachorro).
func simulate_raid() -> void:
    if raid.is_empty() or raid.resolved:
        return
    raid.started = true
    raid.resolved = true
    var pen := StringName(raid.pen)
    var strength := int(RAID_SIZES[StringName(raid.size)].strength)
    var defense := defense_of(pen)
    if defense >= strength:
        report += "De noite, criaturas rondaram o %s, mas a defesa segurou (porteira, lampiões e o Pipoca). " % String(pen)
        raid_ended.emit(true)
        return
    if gates[pen].closed:
        gates[pen].hp = 0
        gates[pen].closed = false
    var p := clampf(0.15 * (strength - defense), 0.0, 0.75)
    var harmed := 0
    for a: Dictionary in animals.duplicate():
        if pen_of(a.kind) != pen:
            continue
        if _rng.randf() < p:
            harmed += 1
            _harm(a, false)
        else:
            a.status = "assustado"
            a.status_days = 2
            a.happiness = maxi(0, int(a.happiness) - 20)
    report = "Atacaram o %s de noite! " % String(pen) + report
    if harmed == 0:
        report += "Por sorte ninguém se machucou, mas a bicharada ficou assustada. "
    _rebuild()
    _update_props()
    raid_ended.emit(false)


func _resolve_pending_raid() -> void:
    if raid.is_empty() or raid.resolved:
        return
    if raid.started:
        # dormiu ou saiu no meio do ataque: as criaturas que sobraram fazem o estrago
        for e in _raiders:
            if is_instance_valid(e):
                e.queue_free()
        _raiders.clear()
        raid.started = false
    simulate_raid()


## Pontos de defesa de um cercado: porteira fechada 2, lampiões por perto 1 cada (até 2), cachorro 2.
func defense_of(pen: StringName) -> int:
    var d := 0
    if gates[pen].closed and gates[pen].hp > 0:
        d += 2
    var center := pen_rect(pen).get_center()
    var lamps := 0
    for n in get_tree().get_nodes_in_group("persistent"):
        if n is Decor and n.item_id == &"lampiao" and (n as Node2D).global_position.distance_to(center) < 110.0:
            lamps += 1
    d += mini(lamps, 2)
    if dog:
        d += 2
    return d


# --- bichos fugidos ----------------------------------------------------------------

func _lost_spot() -> Vector2:
    var mata := _mata()
    if mata:
        for i in 30:
            var p := Vector2(_rng.randf_range(80, 560), _rng.randf_range(80, 300))
            if mata.is_walkable(p):
                return p
    return Vector2(300, 200)


func _mata() -> Level:
    var main := get_tree().get_first_node_in_group("save_root")
    return main.get_region(&"mata") if main and main.has_method("get_region") else null


func _spawn_lost_nodes() -> void:
    var mata := _mata()
    if mata == null:
        return
    for n in mata.get_entities_root().get_children():
        if n is LostAnimal:
            n.queue_free()
    for a: Dictionary in lost:
        var la := LostAnimal.new().setup(self, a)
        mata.get_entities_root().add_child(la)


## Trouxe o bicho de volta da mata.
func rescue(a: Dictionary) -> bool:
    if not a in lost:
        return false
    if pen_count(pen_of(a.kind)) >= capacity(a.kind):
        EventBus.show_message("Não tem lugar no cercado pra %s!" % a.name, 2.5)
        return false
    lost.erase(a)
    a.erase("lost_day")
    a.erase("x")
    a.erase("y")
    a.status = "ferido"
    animals.append(a)
    GameState.add_xp(&"criacao", 10)
    EventBus.show_message("%s voltou pra casa! Ainda ferido(a), mas a salvo." % a.name, 3.0)
    _spawn_lost_nodes()
    _rebuild()
    return true


func _expire_lost() -> void:
    for a: Dictionary in lost.duplicate():
        if GameState.day - int(a.lost_day) > 3:
            lost.erase(a)
            report += "%s não voltou da mata... " % a.name
    _spawn_lost_nodes.call_deferred()


# --- cachorro -----------------------------------------------------------------------

func pet_dog() -> void:
    if dog_pet_day == GameState.day:
        EventBus.show_message("O Pipoca abana o rabo. (já ganhou carinho hoje)", 1.5)
        return
    dog_pet_day = GameState.day
    GameState.add_xp(&"criacao", 2)
    EventBus.show_message("♥ O Pipoca deita de barriga pra cima!", 2.0)


# --- visual -------------------------------------------------------------------------

func _rebuild() -> void:
    for c in get_children():
        if c is FarmAnimal or c is Pickup:
            remove_child(c)
            c.queue_free()
    for a: Dictionary in animals:
        add_child(FarmAnimal.new().setup(a.kind, a, pen_rect(pen_of(a.kind)), ANIMALS[a.kind]))
    for p: Dictionary in pickups:
        var pk := Pickup.new().setup(StringName(p.item), 1, &"criacao", 4)
        pk.position = Vector2(float(p.x), float(p.y))
        pk.set_meta("record", p)
        pk.picked.connect(func(n: Pickup) -> void: pickups.erase(n.get_meta("record")))
        add_child(pk)
    _update_props()


# --- save ---------------------------------------------------------------------------

func _record_to_data(a: Dictionary) -> Dictionary:
    var d := {}
    for k in a:
        d[k] = String(a[k]) if a[k] is StringName else a[k]
    return d


func _record_from_data(a: Dictionary) -> Dictionary:
    var kind := StringName(a.get("kind", ""))
    var r := _new_record(kind, bool(a.get("young", false)))
    r.name = String(a.get("name", r.name))
    r.age = int(a.get("age", 99 if not r.young else 0))
    r.happiness = clampi(int(a.get("happiness", 50)), 0, 100)
    r.pet_day = int(a.get("pet_day", 0))
    r.health = clampi(int(a.get("health", 100)), 0, 100)
    r.status = String(a.get("status", "ok"))
    r.status_days = int(a.get("status_days", 0))
    for k in ["lost_day", "x", "y"]:
        if a.has(k):
            r[k] = a[k]
    return r


func get_save_data() -> Dictionary:
    return {"animals": animals.map(_record_to_data), "lost": lost.map(_record_to_data),
        "feed": {"galinheiro": feed[&"galinheiro"], "curral": feed[&"curral"]},
        "water": {"galinheiro": water[&"galinheiro"], "curral": water[&"curral"]},
        "gates": {"galinheiro": gates[&"galinheiro"].duplicate(), "curral": gates[&"curral"].duplicate()},
        "pickups": pickups.duplicate(true), "raid": raid.duplicate(), "report": report, "dog_pet_day": dog_pet_day}


func load_save_data(d: Dictionary) -> void:
    animals = []
    lost = []
    for a in d.get("animals", []):
        if ANIMALS.has(StringName(a.get("kind", ""))):
            animals.append(_record_from_data(a))
    for a in d.get("lost", []):
        if ANIMALS.has(StringName(a.get("kind", ""))):
            lost.append(_record_from_data(a))
    var f: Dictionary = d.get("feed", {})
    feed = {&"galinheiro": clampi(int(f.get("galinheiro", 0)), 0, FEED_MAX), &"curral": clampi(int(f.get("curral", 0)), 0, FEED_MAX)}
    var w: Dictionary = d.get("water", {})
    # save antigo (sem bebedouro): começa cheio pra ninguém passar sede de surpresa
    var full := WATER_MAX if not d.has("water") and d.has("animals") else 0
    water = {&"galinheiro": clampi(int(w.get("galinheiro", full)), 0, WATER_MAX), &"curral": clampi(int(w.get("curral", full)), 0, WATER_MAX)}
    var g: Dictionary = d.get("gates", {})
    for pen in [&"galinheiro", &"curral"]:
        var gd: Dictionary = g.get(String(pen), {})
        gates[pen] = {"closed": bool(gd.get("closed", false)), "hp": clampi(int(gd.get("hp", GATE_HP)), 0, GATE_HP)}
    pickups = []
    for p in d.get("pickups", []):
        if ItemDB.has_item(StringName(p.get("item", ""))):
            pickups.append({"item": p.item, "x": float(p.x), "y": float(p.y)})
    raid = d.get("raid", {}).duplicate()
    report = String(d.get("report", ""))
    dog_pet_day = int(d.get("dog_pet_day", 0))
    _rebuild()
    _spawn_lost_nodes.call_deferred()
