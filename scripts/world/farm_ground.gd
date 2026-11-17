class_name FarmGround
extends TileMapLayer
## Chão da região, lido de um mapa ASCII em data/maps/.
##
## Motivo: o layout fica versionável, legível e editável em qualquer editor
## de texto; trocar o tileset provisório pelo final não exige redesenhar o mapa.
## Quando o tileset final existir com autotile (terrains), este loader pode
## ser substituído por um TileMapLayer pintado no editor sem afetar o resto.

const TILE_SIZE := 16
const TILESET_TEXTURE: Texture2D = preload("res://assets/tilesets/farm_tiles_placeholder.png")

## Caractere -> coluna no atlas (farm_tiles_placeholder.png).
const LEGEND := {
    ".": 0,  # grama
    ",": 1,  # grama com flores
    "\"": 2, # capim seco / dourado
    "=": 3,  # terra vermelha (estrada)
    "#": 4,  # terra arada
    "~": 5,  # água
    "m": 6,  # grama escura (mata)
    "^": 7,  # água com margem
    "p": 8,  # calçamento de pedra (praça)
    "b": 9,  # ponte de madeira
}
## Colunas do atlas que bloqueiam passagem.
const SOLID_TILES := [5, 7]

@export_file("*.txt") var map_path: String = "res://data/maps/fazenda_pequi.txt"

var map_size := Vector2i.ZERO


func _ready() -> void:
    tile_set = _build_tile_set()
    load_map(map_path)


func load_map(path: String) -> void:
    clear()
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("FarmGround: não consegui abrir o mapa '%s' (erro %d)" % [path, FileAccess.get_open_error()])
        return
    var lines := file.get_as_text().strip_edges(false, true).split("\n")
    map_size = Vector2i(0, lines.size())
    for y in lines.size():
        var line := lines[y].strip_edges(false, true)
        map_size.x = maxi(map_size.x, line.length())
        for x in line.length():
            var ch := line[x]
            if not LEGEND.has(ch):
                push_warning("FarmGround: caractere desconhecido '%s' em (%d, %d); usando grama." % [ch, x, y])
                ch = "."
            set_cell(Vector2i(x, y), 0, Vector2i(LEGEND[ch], 0))


## Retângulo do mundo em pixels (usado para limites da câmera e bordas).
func get_world_rect() -> Rect2:
    return Rect2(Vector2.ZERO, Vector2(map_size * TILE_SIZE))


func is_solid_at(world_pos: Vector2) -> bool:
    var coords := get_cell_atlas_coords(local_to_map(to_local(world_pos)))
    return coords.x in SOLID_TILES


func _build_tile_set() -> TileSet:
    var ts := TileSet.new()
    ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
    ts.add_physics_layer()
    ts.set_physics_layer_collision_layer(0, 1)  # camada "mundo"
    ts.set_physics_layer_collision_mask(0, 0)

    var source := TileSetAtlasSource.new()
    source.texture = TILESET_TEXTURE
    source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
    ts.add_source(source, 0)

    var columns := TILESET_TEXTURE.get_width() / TILE_SIZE
    var h := TILE_SIZE / 2.0
    for col in columns:
        var coords := Vector2i(col, 0)
        source.create_tile(coords)
        if col in SOLID_TILES:
            var data := source.get_tile_data(coords, 0)
            data.add_collision_polygon(0)
            data.set_collision_polygon_points(0, 0, PackedVector2Array([
                Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]))
    return ts
