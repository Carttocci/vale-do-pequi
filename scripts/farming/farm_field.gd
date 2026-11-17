class_name FarmField
extends Node
## Terra cultivável de uma região: capinar, regar, plantar, crescer, colher.
##
## Estado por célula (Vector2i do mapa):
##   {"watered": bool, "crop": StringName ou &"", "age": int (dias regados)}
## Visual: tiles no TileMapLayer "Soil" + um Sprite2D por planta dentro das
## entidades (para o jogador passar na frente/atrás das plantas).
##
## Recebe pedidos de uso de item e de interação em células pelos grupos
## "item_target" e "cell_interaction" (o Player não conhece esta classe).

signal cell_changed(cell: Vector2i)

const TILE := 16
const SOIL_TEXTURE: Texture2D = preload("res://assets/tilesets/soil_placeholder.png")
const CURSOR_TEXTURE: Texture2D = preload("res://assets/ui/tile_cursor_placeholder.png")
## Colunas do chão (farm_ground.gd) onde dá para capinar: grama, grama com flor,
## capim seco e terra arada.
const TILLABLE_GROUND := [0, 1, 2, 4]
const SOIL_DRY := Vector2i(0, 0)
const SOIL_WET := Vector2i(1, 0)
## Distância (px) de uma fonte de água ("water_source") que permite encher o regador.
const WATER_SOURCE_REACH := 24.0

@export var ground_path: NodePath
@export var soil_path: NodePath
@export var crops_root_path: NodePath

var cells: Dictionary = {}
var _crop_sprites: Dictionary = {}
var _rng := RandomNumberGenerator.new()

@onready var ground: FarmGround = get_node(ground_path)
@onready var soil: TileMapLayer = get_node(soil_path)
@onready var crops_root: Node2D = get_node(crops_root_path)
var cursor: Sprite2D


func _ready() -> void:
    add_to_group("persistent")
    add_to_group("item_target")
    add_to_group("cell_interaction")
    soil.tile_set = _build_soil_tileset()
    cursor = Sprite2D.new()
    cursor.texture = CURSOR_TEXTURE
    cursor.z_index = 0  # por baixo das plantas e do jogador
    cursor.visible = false
    soil.add_child(cursor)
    GameState.day_advanced.connect(func(_d: int) -> void: advance_day())


func _process(_delta: float) -> void:
    _update_cursor()


# --- consultas -------------------------------------------------------------

func cell_at(world_pos: Vector2) -> Vector2i:
    return ground.local_to_map(ground.to_local(world_pos))


func cell_center(cell: Vector2i) -> Vector2:
    return ground.to_global(ground.map_to_local(cell))


func is_tilled(cell: Vector2i) -> bool:
    return cells.has(cell)


func get_crop_id(cell: Vector2i) -> StringName:
    return cells[cell].crop if cells.has(cell) else &""


func is_watered(cell: Vector2i) -> bool:
    return cells.has(cell) and cells[cell].watered


func is_ripe(cell: Vector2i) -> bool:
    var crop := ItemDB.get_crop(get_crop_id(cell))
    return crop != null and crop.is_mature(cells[cell].age)


func can_till(cell: Vector2i) -> bool:
    if cells.has(cell):
        return false
    if ground.get_cell_source_id(cell) == -1:
        return false
    if not ground.get_cell_atlas_coords(cell).x in TILLABLE_GROUND:
        return false
    return not _is_blocked(cell_center(cell))


# --- ações -----------------------------------------------------------------

func till(cell: Vector2i) -> bool:
    if not can_till(cell):
        return false
    cells[cell] = {"watered": false, "crop": &"", "age": 0}
    _refresh(cell)
    return true


func water(cell: Vector2i) -> bool:
    if not cells.has(cell) or cells[cell].watered:
        return false
    cells[cell].watered = true
    _refresh(cell)
    return true


func plant(cell: Vector2i, crop_id: StringName) -> bool:
    if not cells.has(cell) or cells[cell].crop != &"" or ItemDB.get_crop(crop_id) == null:
        return false
    cells[cell].crop = crop_id
    cells[cell].age = 0
    _refresh(cell)
    return true


## Colhe se estiver maduro. Retorna {"item": id, "amount": n} ou {} se nada.
## Só colhe se couber na mochila.
func harvest(cell: Vector2i) -> Dictionary:
    if not is_ripe(cell):
        return {}
    var crop := ItemDB.get_crop(cells[cell].crop)
    var amount := _rng.randi_range(crop.harvest_min, crop.harvest_max)
    if GameState.space_for(crop.harvest_item) < amount:
        EventBus.show_message("Mochila cheia! Guarde coisas no baú.", 2.0)
        return {}
    GameState.add_item(crop.harvest_item, amount)
    if crop.regrow_days > 0:
        cells[cell].age = crop.days_to_mature() - crop.regrow_days
    else:
        cells[cell].crop = &""
        cells[cell].age = 0
    _refresh(cell)
    return {"item": crop.harvest_item, "amount": amount}


## Passa um dia: o que foi regado cresce; a terra seca de novo.
func advance_day() -> void:
    for cell: Vector2i in cells:
        var c: Dictionary = cells[cell]
        if c.watered and c.crop != &"":
            c.age += 1
        c.watered = false
        _refresh(cell)


# --- integração com o jogador ---------------------------------------------

## Grupo "item_target": usa o item selecionado na célula à frente do jogador.
func use_item(item: ItemData, target_pos: Vector2, _actor: Node) -> bool:
    if item == null:
        return false
    var cell := cell_at(target_pos)
    match item.category:
        ItemData.Category.TOOL:
            match item.tool_type:
                ItemData.ToolType.HOE:
                    if till(cell):
                        return true
                    if not cells.has(cell):
                        EventBus.show_message("Aqui não dá pra capinar.", 1.5)
                    return false
                ItemData.ToolType.WATERING_CAN:
                    if _near_water(target_pos):
                        GameState.refill_water()
                        EventBus.show_message("Regador cheio! (%d)" % GameState.WATER_MAX, 1.5)
                        return true
                    if not cells.has(cell):
                        EventBus.show_message("Só dá pra regar terra capinada.", 1.5)
                        return false
                    if is_watered(cell):
                        return false
                    if not GameState.use_water():
                        EventBus.show_message("Regador vazio. Encha no poço ou na lagoa.", 2.0)
                        return false
                    return water(cell)
        ItemData.Category.SEED:
            if not cells.has(cell):
                EventBus.show_message("Capine a terra antes de plantar.", 1.5)
                return false
            if plant(cell, item.crop_id):
                GameState.consume_selected(1)
                return true
    return false


## Grupo "cell_interaction": texto da dica para a célula (vazio = nada).
func get_cell_prompt(target_pos: Vector2) -> String:
    var cell := cell_at(target_pos)
    if is_ripe(cell):
        return "Colher " + ItemDB.get_crop(cells[cell].crop).display_name.to_lower()
    return ""


func interact_cell(target_pos: Vector2, _actor: Node) -> bool:
    return not harvest(cell_at(target_pos)).is_empty()


# --- save ------------------------------------------------------------------

func get_save_data() -> Dictionary:
    var out := {}
    for cell: Vector2i in cells:
        var c: Dictionary = cells[cell]
        out["%d,%d" % [cell.x, cell.y]] = {"watered": c.watered, "crop": String(c.crop), "age": c.age}
    return {"cells": out}


func load_save_data(data: Dictionary) -> void:
    for cell: Vector2i in cells.keys():
        cells.erase(cell)
        _refresh(cell)
    var saved: Dictionary = data.get("cells", {})
    for key: String in saved:
        var parts := key.split(",")
        if parts.size() != 2:
            continue
        var cell := Vector2i(int(parts[0]), int(parts[1]))
        var c: Dictionary = saved[key]
        var crop := StringName(c.get("crop", ""))
        if crop != &"" and ItemDB.get_crop(crop) == null:
            crop = &""  # cultura removida do jogo: sobra só a terra
        cells[cell] = {"watered": bool(c.get("watered", false)), "crop": crop, "age": maxi(0, int(c.get("age", 0)))}
        _refresh(cell)


# --- interno ---------------------------------------------------------------

func _refresh(cell: Vector2i) -> void:
    if not cells.has(cell):
        soil.erase_cell(cell)
        _set_crop_sprite(cell, null)
        cell_changed.emit(cell)
        return
    var c: Dictionary = cells[cell]
    soil.set_cell(cell, 0, SOIL_WET if c.watered else SOIL_DRY)
    var crop := ItemDB.get_crop(c.crop)
    if crop:
        var stage := mini(crop.stage_for_age(c.age), crop.stage_textures.size() - 1)
        _set_crop_sprite(cell, crop.stage_textures[stage])
    else:
        _set_crop_sprite(cell, null)
    cell_changed.emit(cell)


func _set_crop_sprite(cell: Vector2i, texture: Texture2D) -> void:
    var sprite: Sprite2D = _crop_sprites.get(cell)
    if texture == null:
        if sprite:
            sprite.queue_free()
            _crop_sprites.erase(cell)
        return
    if sprite == null:
        sprite = Sprite2D.new()
        # Origem na base do tile, para o y-sort com o jogador.
        sprite.global_position = cell_center(cell) + Vector2(0, TILE / 2.0 - 1)
        crops_root.add_child(sprite)
        _crop_sprites[cell] = sprite
    sprite.texture = texture
    sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 1)


func _is_blocked(world_pos: Vector2) -> bool:
    var space := soil.get_world_2d().direct_space_state
    var query := PhysicsPointQueryParameters2D.new()
    query.position = world_pos
    query.collision_mask = 1  # camada "mundo": casas, árvores, cercas, água
    query.collide_with_bodies = true
    return not space.intersect_point(query, 1).is_empty()


func _near_water(world_pos: Vector2) -> bool:
    if ground.is_solid_at(world_pos):
        return true  # tile de água
    for source in get_tree().get_nodes_in_group("water_source"):
        if (source as Node2D).global_position.distance_to(world_pos) <= WATER_SOURCE_REACH:
            return true
    return false


func _update_cursor() -> void:
    var player := get_tree().get_first_node_in_group("player") as Player
    var item := GameState.get_selected_item()
    var show := player != null and item != null and item.is_usable_on_ground()
    cursor.visible = show
    if show:
        cursor.global_position = cell_center(cell_at(player.get_target_position()))


func _build_soil_tileset() -> TileSet:
    var ts := TileSet.new()
    ts.tile_size = Vector2i(TILE, TILE)
    var source := TileSetAtlasSource.new()
    source.texture = SOIL_TEXTURE
    source.texture_region_size = Vector2i(TILE, TILE)
    ts.add_source(source, 0)
    source.create_tile(SOIL_DRY)
    source.create_tile(SOIL_WET)
    return ts
