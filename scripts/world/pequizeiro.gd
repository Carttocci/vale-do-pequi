class_name Pequizeiro
extends StaticBody2D
## Pé de pequi. O pequi não se colhe no galho: o fruto cai maduro e se cata
## no chão. Os frutos caídos aparecem embaixo da árvore e caem de novo a
## cada dia, só na safra (outubro a janeiro — Calendar.PEQUI_MONTHS).

@export var fruits_on_ground: int = 3

var _available: int = 0

@onready var interactable: Interactable = $Interactable
@onready var fallen_root: Node2D = $Fallen


func _ready() -> void:
    add_to_group("persistent")
    interactable.interacted.connect(_on_interacted)
    GameState.day_advanced.connect(func(d: int) -> void: _set_available(fruits_on_ground if Calendar.is_pequi_season(d) else 0))
    _set_available(fruits_on_ground if Calendar.is_pequi_season(GameState.day) else 0)


func get_available() -> int:
    return _available


func _on_interacted(_actor: Node) -> void:
    if _available <= 0:
        if Calendar.is_pequi_season(GameState.day):
            EventBus.show_message("Não tem pequi no chão agora. Amanhã cai mais.", 2.0)
        else:
            EventBus.show_message("Fora da safra. O pequi volta a cair em outubro.", 2.5)
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
    if _available > 0:
        interactable.prompt = "Catar pequi"
    elif Calendar.is_pequi_season(GameState.day):
        interactable.prompt = "Pé de pequi"
    else:
        interactable.prompt = "Pé de pequi (fora da safra)"


func get_save_data() -> Dictionary:
    return {"available": _available}


func load_save_data(data: Dictionary) -> void:
    _set_available(clampi(int(data.get("available", fruits_on_ground)), 0, fruits_on_ground))
