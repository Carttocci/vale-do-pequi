class_name Decor
extends StaticBody2D
## Objeto de decoração colocado pelo jogador (banco, vaso, lampião...).
## Um só .tscn para todos: o item define a textura. E recolhe de volta.

@export var item_id: StringName = &""

var sprite: Sprite2D
var interactable: Interactable
var _glow: Sprite2D


func _ready() -> void:
    collision_layer = 1
    collision_mask = 0
    var shape := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(12, 6)
    shape.shape = r
    shape.position = Vector2(0, -3)
    add_child(shape)
    sprite = Sprite2D.new()
    add_child(sprite)
    interactable = Interactable.new()
    var area := CollisionShape2D.new()
    var c := CircleShape2D.new()
    c.radius = 10.0
    area.shape = c
    area.position = Vector2(0, -6)
    interactable.add_child(area)
    add_child(interactable)
    interactable.interacted.connect(func(_a: Node) -> void: pick_up())
    Clock.time_changed.connect(func(_m: int) -> void: _update_light())
    _apply()


## Chamado pela Placement antes de entrar na árvore.
func setup_from_item(item: ItemData) -> void:
    item_id = item.id
    if is_inside_tree():
        _apply()


func _apply() -> void:
    if item_id == &"" or sprite == null:
        return
    var tex := load("res://assets/environments/%s_placeholder.png" % item_id) as Texture2D
    sprite.texture = tex
    sprite.offset = Vector2(0, -tex.get_height() / 2.0 + 2)
    var item := ItemDB.get_item(item_id)
    interactable.prompt = "Recolher " + (item.display_name.to_lower() if item else String(item_id))
    _update_light()


func _update_light() -> void:
    if item_id != &"lampiao" or sprite == null:
        return
    var night := Clock.hour() >= 18 or Clock.hour() < 6 or Clock.hour() >= 24
    sprite.modulate = Color(1.6, 1.4, 0.9) if night else Color.WHITE
    if get_node_or_null("NightLight") == null:
        NightLight.attach(self, Vector2(0, -12), 80.0, Color(1.0, 0.8, 0.45), 1.2)
    else:
        ($NightLight as NightLight).refresh()


func pick_up() -> void:
    if GameState.space_for(item_id) <= 0:
        EventBus.show_message("Mochila cheia.", 1.5)
        return
    GameState.add_item(item_id, 1)
    queue_free()


func get_save_data() -> Dictionary:
    return {"item": String(item_id)}


func load_save_data(d: Dictionary) -> void:
    item_id = StringName(d.get("item", ""))
    _apply()
