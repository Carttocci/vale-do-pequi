class_name Pequizeiro
extends StaticBody2D
## Pé de pequi. O pequi não se colhe no galho: o fruto cai maduro e se cata
## no chão. Os frutos caídos aparecem embaixo da árvore e caem de novo a
## cada dia que passa.
##
## TODO(Fase 3): só produzir na safra (aprox. outubro a janeiro).

@export var fruits_on_ground: int = 3

var _available: int = 0

@onready var interactable: Interactable = $Interactable
@onready var fallen_root: Node2D = $Fallen


func _ready() -> void:
    add_to_group("persistent")
    interactable.interacted.connect(_on_interacted)
    GameState.day_advanced.connect(func(_d: int) -> void: _set_available(fruits_on_ground))
    _set_available(fruits_on_ground)


func get_available() -> int:
    return _available


func _on_interacted(_actor: Node) -> void:
    if _available <= 0:
        EventBus.show_message("Não tem pequi no chão agora. Amanhã cai mais.", 2.0)
        return
    var amount := mini(_available, GameState.space_for(&"pequi"))
    if amount <= 0:
        EventBus.show_message("Mochila cheia! Guarde coisas no baú.", 2.0)
        return
    var total := GameState.add_item(&"pequi", amount)
    _set_available(_available - amount)
    EventBus.show_message("Catou %d pequi (total: %d). Cuidado com o espinho!" % [amount, total], 2.5)


func _set_available(value: int) -> void:
    _available = value
    var i := 0
    for child in fallen_root.get_children():
        (child as CanvasItem).visible = i < _available
        i += 1
    interactable.prompt = "Catar pequi" if _available > 0 else "Pé de pequi"


func get_save_data() -> Dictionary:
    return {"available": _available}


func load_save_data(data: Dictionary) -> void:
    _set_available(clampi(int(data.get("available", fruits_on_ground)), 0, fruits_on_ground))
