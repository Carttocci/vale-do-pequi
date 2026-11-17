class_name Pickup
extends Node2D
## Item no chão para pegar com E (ovo no galinheiro, leite no curral...).

signal picked(pickup: Pickup)

var item_id: StringName
var amount: int = 1
var skill: StringName = &""
var xp: int = 0

var _sprite: Sprite2D
var interactable: Interactable


func setup(id: StringName, n: int = 1, xp_skill: StringName = &"", xp_amount: int = 0) -> Pickup:
    item_id = id
    amount = n
    skill = xp_skill
    xp = xp_amount
    return self


func _ready() -> void:
    var item := ItemDB.get_item(item_id)
    _sprite = Sprite2D.new()
    _sprite.texture = item.icon if item else null
    _sprite.offset = Vector2(0, -6)
    add_child(_sprite)
    interactable = Interactable.new()
    interactable.target_priority = 2
    var shape := CollisionShape2D.new()
    var c := CircleShape2D.new()
    c.radius = 9.0
    shape.shape = c
    shape.position = Vector2(0, -4)
    interactable.add_child(shape)
    add_child(interactable)
    interactable.prompt = "Pegar " + (item.display_name.to_lower() if item else "item")
    interactable.interacted.connect(func(_a: Node) -> void: pick())


func pick() -> bool:
    if GameState.space_for(item_id) < amount:
        EventBus.show_message("Mochila cheia!", 1.5)
        return false
    GameState.add_item(item_id, amount)
    if skill != &"":
        GameState.add_xp(skill, xp)
    picked.emit(self)
    queue_free()
    return true
