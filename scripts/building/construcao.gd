class_name Construcao
extends StaticBody2D
## Peça construída no modo construção (caminho, cerca, poço, cerca de espinhos,
## totem). Fica em Entities/Placed e salva pela Placement ({"id": ...}).

var id: StringName = &""
var sprite: Sprite2D
var _hurt := 0.0


func setup(build_id: StringName) -> Construcao:
    id = build_id
    if is_inside_tree():
        _apply()
    return self


func _ready() -> void:
    collision_mask = 0
    _apply()


func _apply() -> void:
    if id == &"" or not Construcoes.ALL.has(id) or sprite != null:
        return
    var info: Dictionary = Construcoes.ALL[id]
    add_to_group("construcao")
    add_to_group("construcao_" + String(id))
    sprite = Sprite2D.new()
    sprite.texture = load("res://assets/environments/%s_placeholder.png" % id)
    add_child(sprite)
    if info.get("floor", false):
        add_to_group("piso")
        z_index = -1  # embaixo de gente e bicho
        sprite.offset = Vector2(0, -7)
        collision_layer = 0
    else:
        sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 2)
        collision_layer = 1 if info.get("solid", false) else 0
        if info.get("solid", false):
            var shape := CollisionShape2D.new()
            var r := RectangleShape2D.new()
            r.size = Vector2(16, 8) if id != &"poco" else Vector2(22, 10)
            shape.shape = r
            shape.position = Vector2(0, -4)
            add_child(shape)
    if id == &"poco":
        add_to_group("water_source")
    if id == &"totem_protecao":
        add_to_group("protetor")
        NightLight.attach(self, Vector2(0, -20), 50.0, Color(0.6, 0.9, 1.0), 0.8)


func _process(delta: float) -> void:
    if id != &"cerca_espinhos":
        return
    _hurt -= delta
    if _hurt > 0.0:
        return
    _hurt = 0.6
    for n in get_tree().get_nodes_in_group("enemy"):
        var e := n as Enemy
        if e and not e.is_dead() and e.global_position.distance_to(global_position) < 16.0:
            e.take_hit(4, e.global_position - global_position, 80.0, 0.1)


func get_save_data() -> Dictionary:
    return {"id": String(id)}


func load_save_data(d: Dictionary) -> void:
    setup(StringName(d.get("id", "")))
