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
## Colunas 13+ são de dentro das casas (paredes e pisos, sem transição).
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
    "c": 10, # chão de caverna
    "r": 11, # parede de rocha (sólida)
    "u": 12, # piso de ruína
    "T": 13, # teto / topo da parede (sólido)
    "A": 14, # parede caiada, parte de cima (sólida)
    "a": 15, # parede caiada com barrado azul (sólida)
    "E": 16, # parede de taipa ocre, cima
    "e": 17, # parede de taipa ocre, baixo
    "K": 18, # tijolinho aparente, cima
    "k": 19, # tijolinho aparente, baixo
    "V": 20, # parede de tábua, cima
    "v": 21, # parede de tábua, baixo
    "G": 22, # parede branca, cima
    "g": 23, # parede branca com barrado verde
    "w": 24, # assoalho de madeira
    "o": 25, # lajota de barro (cozinha)
    "q": 26, # ladrilho hidráulico
    "h": 27, # cimento queimado vermelho
    "X": 28, # vazio (fora da casa; sólido, não desenha nada)
}
## Colunas do atlas que bloqueiam passagem.
const SOLID_TILES := [5, 7, 11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 28]
## Colunas de dentro de casa: desenhadas direto, sem a camada de transição.
const INDOOR_FIRST := 13

@export_file("*.txt") var map_path: String = "res://data/maps/fazenda_pequi.txt"

var map_size := Vector2i.ZERO
## Chão bonito por cima (transições suaves entre os terrenos).
var _visual := GroundVisual.new()


func _ready() -> void:
    tile_set = _build_tile_set()
    _visual.name = "Visual"
    add_child(_visual)
    load_map(map_path)


func load_map(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("FarmGround: não consegui abrir o mapa '%s' (erro %d)" % [path, FileAccess.get_open_error()])
        return
    load_from_text(file.get_as_text())


## Monta o chão a partir de texto ASCII (usado também pela mina, gerada na hora).
func load_from_text(text: String) -> void:
    clear()
    var lines := text.strip_edges(false, true).split("\n")
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
    _visual.build(self, lines)


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
