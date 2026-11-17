class_name Prop
extends StaticBody2D
## Objeto simples montado por código: sprite + colisão (opcional) + E.
## Usado pela mina, serra e ruínas (escadas, totens, portal, mural...).

signal used(actor: Node)

var sprite: Sprite2D
var interactable: Interactable
var collision: CollisionShape2D


func setup(texture_name: String, body_size: Vector2, prompt: String, radius: float = 14.0, frames: int = 1) -> Prop:
    collision_layer = 1 if body_size != Vector2.ZERO else 0
    collision_mask = 0
    sprite = Sprite2D.new()
    sprite.hframes = frames
    add_child(sprite)
    set_texture(texture_name)
    if body_size != Vector2.ZERO:
        collision = CollisionShape2D.new()
        var r := RectangleShape2D.new()
        r.size = body_size
        collision.shape = r
        collision.position = Vector2(0, -body_size.y / 2.0)
        add_child(collision)
    if prompt != "":
        interactable = Interactable.new()
        var shape := CollisionShape2D.new()
        var c := CircleShape2D.new()
        c.radius = radius
        shape.shape = c
        shape.position = Vector2(0, -6)
        interactable.add_child(shape)
        add_child(interactable)
        interactable.prompt = prompt
        interactable.interacted.connect(func(a: Node) -> void: used.emit(a))
    return self


func set_texture(texture_name: String) -> void:
    sprite.texture = load("res://assets/environments/%s_placeholder.png" % texture_name)
    sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 1)


## Liga/desliga a barreira física (o selo das ruínas, por exemplo).
func set_solid(value: bool) -> void:
    collision_layer = 1 if value else 0
