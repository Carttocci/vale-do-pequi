class_name Ranch
extends Node2D
## Criação da fazenda: galinheiro (galinhas → ovos) e curral (vacas → leite).
##
## Cada cercado tem comedouro. Com ração ou milho na mão, o E vira "Pôr no
## comedouro". Ao passar o dia, cada animal come 1 porção; alimentado, fica
## mais feliz e pode deixar um produto no chão (mais felicidade = mais chance).
## Sem comer, fica triste e não produz. Animais são comprados com a Mariana.

const FEED_MAX := 20
const FEED_ITEMS := [&"racao", &"milho"]
const ANIMALS := {
    &"galinha": {"name": "Galinha", "price": 120, "product": &"ovo", "pen": &"galinheiro", "capacity": 6,
        "sprite": "res://assets/animals/galinha_placeholder.png"},
    &"vaca": {"name": "Vaca", "price": 600, "product": &"leite", "pen": &"curral", "capacity": 4,
        "sprite": "res://assets/animals/vaca_placeholder.png"},
}

@export var chicken_pen := Rect2(572, 96, 120, 28)
@export var cow_pen := Rect2(736, 64, 180, 56)
@export var chicken_feeder_path: NodePath
@export var cow_feeder_path: NodePath
@export var coop_path: NodePath

## [{"kind", "happiness", "pet_day"}]
var animals: Array = []
var feed := {&"galinheiro": 0, &"curral": 0}
var pickups: Array = []   # [{"item", "x", "y"}]

var _rng := RandomNumberGenerator.new()
@onready var chicken_feeder: Node2D = get_node(chicken_feeder_path)
@onready var cow_feeder: Node2D = get_node(cow_feeder_path)
@onready var coop: Node2D = get_node(coop_path)


func _ready() -> void:
    add_to_group("persistent")
    add_to_group("item_target")
    add_to_group("ranch")
    y_sort_enabled = true
    GameState.day_advanced.connect(func(_d: int) -> void: advance_day())
    for feeder in [chicken_feeder, cow_feeder]:
        var it: Interactable = feeder.get_node("Interactable")
        it.interacted.connect(_on_feeder_interacted.bind(feeder))
    coop.get_node("Interactable").interacted.connect(func(_a: Node) -> void:
        EventBus.show_message("Galinheiro: %d/%d galinhas. Curral: %d/%d vacas." % [
            count(&"galinha"), ANIMALS[&"galinha"].capacity, count(&"vaca"), ANIMALS[&"vaca"].capacity], 2.5))
    _rebuild()


func count(kind: StringName) -> int:
    return animals.filter(func(a: Dictionary) -> bool: return a.kind == kind).size()


func can_buy(kind: StringName) -> bool:
    return ANIMALS.has(kind) and count(kind) < int(ANIMALS[kind].capacity)


## Compra (já pago): o animal aparece no cercado.
func add_animal(kind: StringName) -> bool:
    if not can_buy(kind):
        return false
    animals.append({"kind": kind, "happiness": 50, "pet_day": 0})
    _rebuild()
    return true


func feeder_for(pen: StringName) -> Node2D:
    return chicken_feeder if pen == &"galinheiro" else cow_feeder


func advance_day() -> void:
    for a: Dictionary in animals:
        var info: Dictionary = ANIMALS[a.kind]
        var pen: StringName = info.pen
        if feed[pen] > 0:
            feed[pen] -= 1
            a.happiness = mini(100, int(a.happiness) + 5)
            if _rng.randf() < 0.6 + int(a.happiness) * 0.004:
                var rect := chicken_pen if pen == &"galinheiro" else cow_pen
                pickups.append({"item": String(info.product),
                    "x": _rng.randf_range(rect.position.x, rect.end.x), "y": _rng.randf_range(rect.position.y, rect.end.y)})
        else:
            a.happiness = maxi(0, int(a.happiness) - 15)
    _rebuild()


# --- comedouro (grupo item_target) --------------------------------------------

func get_item_action(item: ItemData, target_pos: Vector2, _actor: Node) -> Dictionary:
    if item == null or not item.id in FEED_ITEMS:
        return {}
    var pen := _pen_near(target_pos)
    if pen == &"" or feed[pen] >= FEED_MAX:
        return {}
    return {"prompt": "Pôr no comedouro (%d/%d)" % [feed[pen], FEED_MAX], "priority": 22}


func use_item(item: ItemData, target_pos: Vector2, _actor: Node) -> bool:
    if get_item_action(item, target_pos, null).is_empty():
        return false
    var pen := _pen_near(target_pos)
    if not GameState.consume_selected(1):
        return false
    feed[pen] += 1
    _update_feeders()
    return true


func _pen_near(pos: Vector2) -> StringName:
    if pos.distance_to(chicken_feeder.global_position + Vector2(0, -4)) < 16.0:
        return &"galinheiro"
    if pos.distance_to(cow_feeder.global_position + Vector2(0, -4)) < 16.0:
        return &"curral"
    return &""


func _on_feeder_interacted(_a: Node, feeder: Node2D) -> void:
    var pen := &"galinheiro" if feeder == chicken_feeder else &"curral"
    EventBus.show_message("Comedouro: %d porções. Ponha ração ou milho (com o item na mão, E)." % feed[pen], 2.5)


# --- visual -------------------------------------------------------------------

func _rebuild() -> void:
    for c in get_children():
        if c is FarmAnimal or c is Pickup:
            remove_child(c)
            c.queue_free()
    for a: Dictionary in animals:
        var rect := chicken_pen if ANIMALS[a.kind].pen == &"galinheiro" else cow_pen
        add_child(FarmAnimal.new().setup(a.kind, a, rect, ANIMALS[a.kind]))
    for p: Dictionary in pickups:
        var pk := Pickup.new().setup(StringName(p.item), 1, &"criacao", 4)
        pk.position = Vector2(float(p.x), float(p.y))
        pk.set_meta("record", p)
        pk.picked.connect(func(n: Pickup) -> void: pickups.erase(n.get_meta("record")))
        add_child(pk)
    _update_feeders()


func _update_feeders() -> void:
    for pen in [&"galinheiro", &"curral"]:
        var f := feeder_for(pen)
        var spr: Sprite2D = f.get_node("Sprite")
        spr.texture = load("res://assets/environments/comedouro_cheio_placeholder.png" if feed[pen] > 0
            else "res://assets/environments/comedouro_placeholder.png")


# --- save ---------------------------------------------------------------------

func get_save_data() -> Dictionary:
    return {"animals": animals.map(func(a: Dictionary) -> Dictionary:
            return {"kind": String(a.kind), "happiness": a.happiness, "pet_day": a.pet_day}),
        "feed": {"galinheiro": feed[&"galinheiro"], "curral": feed[&"curral"]}, "pickups": pickups.duplicate(true)}


func load_save_data(d: Dictionary) -> void:
    animals = []
    for a in d.get("animals", []):
        if ANIMALS.has(StringName(a.get("kind", ""))):
            animals.append({"kind": StringName(a.kind), "happiness": clampi(int(a.get("happiness", 50)), 0, 100),
                "pet_day": int(a.get("pet_day", 0))})
    var f: Dictionary = d.get("feed", {})
    feed = {&"galinheiro": clampi(int(f.get("galinheiro", 0)), 0, FEED_MAX), &"curral": clampi(int(f.get("curral", 0)), 0, FEED_MAX)}
    pickups = []
    for p in d.get("pickups", []):
        if ItemDB.has_item(StringName(p.get("item", ""))):
            pickups.append({"item": p.item, "x": float(p.x), "y": float(p.y)})
    _rebuild()
