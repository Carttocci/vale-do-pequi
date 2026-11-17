class_name Level
extends Node2D
## Uma região do mundo (Fazenda, Vila...). Contrato usado pela cena principal:
## onde ficam as entidades, pontos de chegada, tamanho do mundo, ativar/desativar.
##
## Regiões ficam todas carregadas; só a ativa aparece e processa. Assim o
## estado de cada uma (plantas, baús, moradores) continua vivo enquanto o
## jogador está em outra, e o save usa caminhos estáveis ("Farm/...", "Vila/...").
##
## Estrutura esperada: Ground (FarmGround), Entities (y-sort), PlayerSpawn
## (Marker2D, chegada padrão) e opcionalmente Markers/ (pontos nomeados para
## chegadas e rotinas dos moradores).

@export var region_id: StringName = &"farm"
@export var display_name: String = "Fazenda do Pequi"
## Tipo de água para a pesca: "lagoa" ou "rio".
@export var water_habitat: String = "lagoa"
## Regiões "de passagem" (mina, ruínas) salvam o jogador do lado de fora.
@export var save_as_region: StringName = &""
@export var save_as_spawn: StringName = &""

@onready var ground: FarmGround = $Ground
@onready var entities: Node2D = $Entities
@onready var player_spawn: Marker2D = $PlayerSpawn

var active: bool = true
var _nav: AStarGrid2D


func _ready() -> void:
    add_to_group("level")
    _build_world_bounds()


func get_entities_root() -> Node2D:
    return entities


func get_spawn_position(spawn_name: StringName = &"") -> Vector2:
    if spawn_name != &"":
        var m := get_marker(spawn_name)
        if m:
            return m.global_position
    return player_spawn.global_position


func get_marker(marker_name: StringName) -> Marker2D:
    return get_node_or_null("Markers/" + String(marker_name)) as Marker2D


func get_world_rect() -> Rect2:
    return ground.get_world_rect()


## Liga/desliga a região inteira (visual, processamento, física).
func set_active(value: bool) -> void:
    active = value
    visible = value
    process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
    ground.enabled = value
    for child in get_children():
        if child is TileMapLayer:
            (child as TileMapLayer).enabled = value
    if value:
        for npc in get_tree().get_nodes_in_group("npc"):
            if is_ancestor_of(npc):
                npc.snap_to_schedule()


# --- navegação dos moradores ------------------------------------------------

## Caminho (em pontos do mundo) entre duas posições, desviando de prédios,
## árvores, cercas e água. Vazio se não houver caminho.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
    var nav := _get_nav()
    var a := _clamp_cell(ground.local_to_map(ground.to_local(from)))
    var b := _clamp_cell(ground.local_to_map(ground.to_local(to)))
    if nav.is_point_solid(b):
        return PackedVector2Array()
    var cells := nav.get_id_path(a, b)
    var out := PackedVector2Array()
    for c in cells:
        out.append(ground.to_global(ground.map_to_local(c)))
    if not out.is_empty():
        out[out.size() - 1] = to
    return out


## Descarta a grade de navegação (algo que bloqueava passagem sumiu ou mudou).
func invalidate_nav() -> void:
    _nav = null


func is_walkable(world_pos: Vector2) -> bool:
    var c := ground.local_to_map(ground.to_local(world_pos))
    return _get_nav().is_in_boundsv(c) and not _get_nav().is_point_solid(c)


func _get_nav() -> AStarGrid2D:
    if _nav:
        return _nav
    _nav = AStarGrid2D.new()
    _nav.region = Rect2i(Vector2i.ZERO, ground.map_size)
    _nav.cell_size = Vector2(FarmGround.TILE_SIZE, FarmGround.TILE_SIZE)
    _nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
    _nav.update()
    var space := get_world_2d().direct_space_state
    var query := PhysicsPointQueryParameters2D.new()
    query.collision_mask = 1
    for x in ground.map_size.x:
        for y in ground.map_size.y:
            var cell := Vector2i(x, y)
            var center := ground.to_global(ground.map_to_local(cell))
            var solid := ground.is_solid_at(center)
            if not solid:
                for offset in [Vector2.ZERO, Vector2(-5, -5), Vector2(5, -5), Vector2(-5, 5), Vector2(5, 5)]:
                    query.position = center + offset
                    # Só conta o que é desta região (as outras ficam no mesmo
                    # espaço de coordenadas e podem demorar 1 quadro para sair da física).
                    for hit in space.intersect_point(query, 8):
                        if is_ancestor_of(hit.collider):
                            solid = true
                            break
                    if solid:
                        break
            _nav.set_point_solid(cell, solid)
    return _nav


func _clamp_cell(c: Vector2i) -> Vector2i:
    return c.clamp(Vector2i.ZERO, ground.map_size - Vector2i.ONE)


## Paredes invisíveis nas bordas do mapa.
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
