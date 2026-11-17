class_name InspectSpot
extends Node2D
## Ponto simples para ler com E (pegadas na mata, etc.). Criado por código.

signal inspected

var text: String = ""


func setup(prompt: String, message: String, texture: Texture2D, radius: float = 10.0) -> InspectSpot:
    text = message
    if texture:
        var s := Sprite2D.new()
        s.texture = texture
        add_child(s)
    var it := Interactable.new()
    var shape := CollisionShape2D.new()
    var c := CircleShape2D.new()
    c.radius = radius
    shape.shape = c
    it.add_child(shape)
    add_child(it)
    it.prompt = prompt
    it.interacted.connect(func(_a: Node) -> void:
        EventBus.show_message(text, 3.0)
        inspected.emit())
    return self
