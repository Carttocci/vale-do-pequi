class_name Interactable
extends Area2D
## Componente de interação. Coloque como filho de qualquer objeto do mundo.
##
## O jogador detecta estas áreas (camada 3, "interagivel") com a própria
## InteractionArea e chama interact() quando o botão de interação é apertado.
## O objeto dono só precisa conectar o sinal `interacted`.

signal interacted(actor: Node)

const LAYER_INTERACTABLE := 1 << 2  # camada 3

## Texto mostrado no HUD, sem a tecla (o HUD adiciona "[E]").
@export var prompt: String = "Interagir":
    set(value):
        prompt = value
        prompt_dirty = true
@export var enabled: bool = true

## Marcado quando o texto muda enquanto o jogador já está mirando o objeto.
var prompt_dirty: bool = false


func _ready() -> void:
    collision_layer = LAYER_INTERACTABLE
    collision_mask = 0
    monitoring = false
    monitorable = true


func get_prompt() -> String:
    return prompt


func interact(actor: Node) -> void:
    if enabled:
        interacted.emit(actor)
