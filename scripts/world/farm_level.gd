class_name FarmLevel
extends Node2D
## Região "Fazenda do Pequi". Expõe o que a cena principal precisa saber
## (onde nasce o jogador, onde ficam as entidades, tamanho do mundo) sem que
## main.gd precise conhecer a estrutura interna da cena.

@onready var ground: FarmGround = $Ground
@onready var entities: Node2D = $Entities
@onready var player_spawn: Marker2D = $PlayerSpawn


func _ready() -> void:
    _build_world_bounds()


func get_entities_root() -> Node2D:
    return entities


func get_spawn_position() -> Vector2:
    return player_spawn.position


func get_world_rect() -> Rect2:
    return ground.get_world_rect()


## Paredes invisíveis nas bordas do mapa.
## TODO(Fase 3): a borda leste vira a saída para a Vila de Santa Pequiria.
func _build_world_bounds() -> void:
    var rect := get_world_rect()
    var thickness := 32.0
    var bounds := StaticBody2D.new()
    bounds.name = "WorldBounds"
    bounds.collision_layer = 1
    bounds.collision_mask = 0
    var walls := [
        Rect2(rect.position.x - thickness, rect.position.y - thickness, rect.size.x + thickness * 2, thickness),
        Rect2(rect.position.x - thickness, rect.end.y, rect.size.x + thickness * 2, thickness),
        Rect2(rect.position.x - thickness, rect.position.y, thickness, rect.size.y),
        Rect2(rect.end.x, rect.position.y, thickness, rect.size.y),
    ]
    for wall: Rect2 in walls:
        var shape := CollisionShape2D.new()
        var box := RectangleShape2D.new()
        box.size = wall.size
        shape.shape = box
        shape.position = wall.get_center()
        bounds.add_child(shape)
    add_child(bounds)
