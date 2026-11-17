class_name Inspectable
extends StaticBody2D
## Objeto sólido que mostra uma mensagem ao interagir (placa, poço, porta...).
## Reutilizável: basta trocar sprite, colisão e os textos no Inspector.

@export var prompt: String = "Olhar"
## Uma linha é sorteada a cada interação, para não ficar repetitivo.
@export_multiline var messages: PackedStringArray = PackedStringArray(["..."])
@export var message_duration: float = 3.0

var _next_index: int = 0

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
    interactable.prompt = prompt
    interactable.interacted.connect(_on_interacted)


func _on_interacted(_actor: Node) -> void:
    if messages.is_empty():
        return
    # Alterna as falas em ordem; mais previsível que aleatório e fácil de testar.
    EventBus.show_message(messages[_next_index], message_duration)
    _next_index = (_next_index + 1) % messages.size()
