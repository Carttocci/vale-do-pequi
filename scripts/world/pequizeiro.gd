class_name Pequizeiro
extends StaticBody2D
## Pé de pequi. O pequi não se colhe no galho: o fruto cai maduro e se cata
## no chão. Aqui os frutos caídos aparecem embaixo da árvore e voltam a cair
## depois de um tempo.
##
## PROVISÓRIO: o reabastecimento usa segundos reais. Na Fase 3 (calendário)
## passa a depender do dia e da época de safra (aprox. outubro a janeiro).

@export var fruits_on_ground: int = 3
## Segundos até cair pequi de novo.
@export var regrow_seconds: float = 20.0

var _available: int = 0

@onready var interactable: Interactable = $Interactable
@onready var fallen_root: Node2D = $Fallen
@onready var regrow_timer: Timer = $RegrowTimer


func _ready() -> void:
    regrow_timer.wait_time = regrow_seconds
    regrow_timer.one_shot = true
    regrow_timer.timeout.connect(_on_regrow)
    interactable.interacted.connect(_on_interacted)
    _set_available(fruits_on_ground)


func get_available() -> int:
    return _available


func _on_interacted(_actor: Node) -> void:
    if _available <= 0:
        EventBus.show_message("Não tem pequi no chão agora. Espera cair mais.", 2.0)
        return
    var amount := _available
    var total := GameState.add_item(&"pequi", amount)
    _set_available(0)
    regrow_timer.start()
    EventBus.show_message("Catou %d pequi (total: %d). Cuidado com o espinho!" % [amount, total], 2.5)


func _on_regrow() -> void:
    _set_available(fruits_on_ground)


func _set_available(value: int) -> void:
    _available = value
    var i := 0
    for child in fallen_root.get_children():
        (child as CanvasItem).visible = i < _available
        i += 1
    interactable.prompt = "Catar pequi" if _available > 0 else "Pé de pequi"
