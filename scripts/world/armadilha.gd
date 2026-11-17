class_name Armadilha
extends Node2D
## Armadilha de javali (só na Mata dos Ipês). Armada num dia, na manhã
## seguinte pode ter pegado um javali. Abrir: carne + couro e a armadilha volta
## para a mochila. Vazia: E recolhe.

const CATCH_CHANCE := 0.5

var caught: bool = false
var interactable: Interactable


func _ready() -> void:
    var s := Sprite2D.new()
    s.texture = load("res://assets/environments/armadilha_armada_placeholder.png")
    s.offset = Vector2(0, -6)
    add_child(s)
    interactable = Interactable.new()
    var shape := CollisionShape2D.new()
    var c := CircleShape2D.new()
    c.radius = 10.0
    shape.shape = c
    shape.position = Vector2(0, -4)
    interactable.add_child(shape)
    add_child(interactable)
    interactable.interacted.connect(func(_a: Node) -> void: open())
    GameState.day_advanced.connect(_on_day)
    _update()


func _on_day(_d: int) -> void:
    if not caught and randf() < CATCH_CHANCE + GameState.skill_level(&"caca") * 0.04:
        caught = true
    _update()


func open() -> void:
    if GameState.space_for(&"armadilha") <= 0:
        EventBus.show_message("Mochila cheia!", 1.5)
        return
    if caught:
        GameState.add_item(&"carne_javali", 2)
        GameState.add_item(&"couro", 1)
        GameState.add_xp(&"caca", 20)
        EventBus.show_message("Pegou um javali! (+2 carne, +1 couro). O invasor não vai mais estragar roça.", 3.0)
    GameState.add_item(&"armadilha", 1)
    queue_free()


func _update() -> void:
    interactable.prompt = "Abrir armadilha (pegou javali!)" if caught else "Recolher armadilha"


func get_save_data() -> Dictionary:
    return {"caught": caught}


func load_save_data(d: Dictionary) -> void:
    caught = bool(d.get("caught", false))
    _update()
