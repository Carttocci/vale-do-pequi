class_name RegionExit
extends Area2D
## Saída para outra região: quando o jogador entra na área, a cena principal
## leva ele para `target_region`, no marcador `target_spawn`.

@export var target_region: StringName = &"vila"
@export var target_spawn: StringName = &""


func _ready() -> void:
    collision_layer = 0
    collision_mask = 2  # jogador
    monitorable = false
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
    if body is Player:
        EventBus.region_change_requested.emit(target_region, target_spawn)
