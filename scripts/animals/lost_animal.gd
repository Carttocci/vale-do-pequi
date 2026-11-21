class_name LostAnimal
extends Node2D
## Bicho que fugiu num ataque e está perdido na Mata dos Ipês. E pra levar de volta.

var ranch: Ranch
var record: Dictionary


func setup(r: Ranch, rec: Dictionary) -> LostAnimal:
    ranch = r
    record = rec
    position = Vector2(float(rec.get("x", 300)), float(rec.get("y", 200)))
    var info: Dictionary = Ranch.ANIMALS[rec.kind]
    var sprite := Sprite2D.new()
    sprite.texture = load(info.young_sprite if rec.get("young", false) and info.has("young_sprite") else info.sprite)
    sprite.hframes = 4
    sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 1)
    sprite.modulate = Color(1, 0.75, 0.75)
    add_child(sprite)
    var it := Interactable.new()
    var shape := CollisionShape2D.new()
    var c := CircleShape2D.new()
    c.radius = 12.0
    shape.shape = c
    shape.position = Vector2(0, -6)
    it.add_child(shape)
    add_child(it)
    it.prompt = "Levar %s pra casa" % rec.get("name", "o bicho")
    it.interacted.connect(func(_a: Node) -> void: ranch.rescue(record))
    return self
