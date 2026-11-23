class_name HouseEntrance
extends StaticBody2D
## Porta de uma casa da vila: entra na casa (interior com quarto, cozinha...).
## De noite a porta fica trancada (o povo tá dormindo).

@export var prompt: String = "Entrar"
@export var target_region: StringName = &""
## Horário em que a porta fica aberta (minutos do dia).
@export var open_from: int = 7 * 60
@export var open_to: int = 20 * 60
@export var closed_message: String = "A porta tá trancada. O povo daqui já foi dormir."

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
    interactable.prompt = prompt
    interactable.interacted.connect(_on_interacted)


func is_open() -> bool:
    return Clock.minutes >= open_from and Clock.minutes < open_to


func _on_interacted(_actor: Node) -> void:
    if not is_open():
        EventBus.show_message(closed_message, 3.0)
        return
    Audio.play(&"porta")
    EventBus.region_change_requested.emit(target_region, &"entrada")
