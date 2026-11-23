class_name GroundVisual
extends Node2D
## Desenho do chão com transições suaves ("dual-grid").
##
## O FarmGround continua sendo a fonte da verdade (colisão, o que é água, onde
## capina...). Esta camada só desenha por cima: cada tile visual fica deslocado
## meio tile e olha as 4 células do mapa que ele cobre. Para cada terreno há uma
## linha no atlas com as 16 combinações de cantos; as camadas são empilhadas na
## ordem de TERRAINS, e o terreno de cima desenha a borda (grama sobre terra,
## terra sobre água...). Atlas gerado por tools/arte/chao.py.

const ATLAS: Texture2D = preload("res://assets/tilesets/chao_cerrado.png")
const T := 16
## Mesma ordem das linhas do atlas (tools/arte/chao.py, TERRENOS).
const TERRAINS := ["agua", "terra", "caverna", "arado", "grama", "seca", "mata", "pedra", "ruina", "rocha"]
const FULL_VARIANTS := [15, 16, 17, 18, 19]
const EXTRA_ROW := 10
## Colunas da linha de enfeites (ponte, flores, tufos, pedrinhas, capim alto).
const DECO_BRIDGE := 0
const DECO_FLOWERS := [1, 2, 3, 4]
const DECO_TUFT := [5, 6, 7]
const DECO_PEBBLE := [8, 9, 10]
const DECO_TALL_GRASS := [11, 12, 13]

static var _tile_set: TileSet

var _layers: Array[TileMapLayer] = []
var _deco: TileMapLayer


## Bits de terreno de um caractere do mapa (bit i = TERRAINS[i]).
static func terrain_bits(ch: String) -> int:
    match ch:
        "~", "^", "b":
            return 1  # só água
        ".", ",":
            return _b("terra") | _b("grama")
        "\"":
            return _b("terra") | _b("grama") | _b("seca")
        "m":
            return _b("terra") | _b("grama") | _b("mata")
        "=":
            return _b("terra")
        "#":
            return _b("terra") | _b("arado")
        "p":
            return _b("terra") | _b("pedra")
        "c":
            return _b("terra") | _b("caverna")
        "r":
            return _b("terra") | _b("caverna") | _b("rocha")
        "u":
            return _b("terra") | _b("ruina")
    return 0  # dentro de casa: não desenha nada aqui


static func _b(terrain: String) -> int:
    return 1 << TERRAINS.find(terrain)


func build(ground: TileMapLayer, lines: PackedStringArray) -> void:
    if _layers.is_empty():
        _make_layers()
    for l in _layers:
        l.clear()
    _deco.clear()
    var h := lines.size()
    var w := 0
    for line in lines:
        w = maxi(w, line.strip_edges(false, true).length())
    if w == 0:
        return
    var bits := PackedInt32Array()
    bits.resize(w * h)
    var chars := PackedStringArray()
    chars.resize(w * h)
    for y in h:
        var line := lines[y].strip_edges(false, true)
        for x in w:
            var ch := line[x] if x < line.length() else "."
            if not FarmGround.LEGEND.has(ch):
                ch = "."
            chars[y * w + x] = ch
            bits[y * w + x] = terrain_bits(ch)
    # tiles visuais: (w+1) x (h+1), cada um nos 4 cantos
    for vy in h + 1:
        for vx in w + 1:
            var tl := bits[clampi(vy - 1, 0, h - 1) * w + clampi(vx - 1, 0, w - 1)]
            var tr := bits[clampi(vy - 1, 0, h - 1) * w + clampi(vx, 0, w - 1)]
            var bl := bits[clampi(vy, 0, h - 1) * w + clampi(vx - 1, 0, w - 1)]
            var br := bits[clampi(vy, 0, h - 1) * w + clampi(vx, 0, w - 1)]
            if (tl | tr | bl | br) == 0:
                continue  # parede/piso de casa
            var cell := Vector2i(vx, vy)
            _layers[0].set_cell(cell, 0, Vector2i(0, 0))  # água embaixo de tudo
            for i in range(1, TERRAINS.size()):
                var bit := 1 << i
                var mask := (1 if tl & bit else 0) | (2 if tr & bit else 0) | (4 if bl & bit else 0) | (8 if br & bit else 0)
                if mask == 0:
                    continue
                var col := mask
                if mask == 15:
                    col = FULL_VARIANTS[_hash(vx, vy, i) % FULL_VARIANTS.size()]
                _layers[i].set_cell(cell, 0, Vector2i(col, i))
    # enfeites na grade normal (flores, tufos, pedrinhas, ponte)
    for y in h:
        for x in w:
            var ch := chars[y * w + x]
            var r := _hash(x, y, 99) % 100
            var col := -1
            match ch:
                "b":
                    col = DECO_BRIDGE
                ",":
                    col = DECO_FLOWERS[_hash(x, y, 7) % DECO_FLOWERS.size()]
                ".":
                    if r < 9:
                        col = DECO_TUFT[_hash(x, y, 3) % 3]
                    elif r < 12:
                        col = DECO_PEBBLE[_hash(x, y, 4) % 3]
                "\"":
                    if r < 30:
                        col = DECO_TALL_GRASS[_hash(x, y, 5) % 3]
                "m":
                    if r < 14:
                        col = DECO_TUFT[_hash(x, y, 6) % 3]
                "=", "c":
                    if r < 10:
                        col = DECO_PEBBLE[_hash(x, y, 8) % 3]
            if col >= 0:
                _deco.set_cell(Vector2i(x, y), 0, Vector2i(col, EXTRA_ROW))


## Número "aleatório" fixo por posição (o chão sai igual toda vez).
static func _hash(x: int, y: int, salt: int) -> int:
    var n := x * 73856093 ^ y * 19349663 ^ salt * 83492791
    n = (n ^ (n >> 13)) * 1274126177
    return absi(n ^ (n >> 16))


func _make_layers() -> void:
    var ts := shared_tile_set()
    for i in TERRAINS.size():
        var l := TileMapLayer.new()
        l.name = "Camada_" + TERRAINS[i]
        l.tile_set = ts
        l.position = Vector2(-T / 2.0, -T / 2.0)
        l.collision_enabled = false
        add_child(l)
        _layers.append(l)
    _deco = TileMapLayer.new()
    _deco.name = "Enfeites"
    _deco.tile_set = ts
    _deco.collision_enabled = false
    add_child(_deco)


static func shared_tile_set() -> TileSet:
    if _tile_set:
        return _tile_set
    var ts := TileSet.new()
    ts.tile_size = Vector2i(T, T)
    var src := TileSetAtlasSource.new()
    src.texture = ATLAS
    src.texture_region_size = Vector2i(T, T)
    ts.add_source(src, 0)
    # água: 4 quadros de animação
    src.create_tile(Vector2i(0, 0))
    src.set_tile_animation_columns(Vector2i(0, 0), 4)
    src.set_tile_animation_frames_count(Vector2i(0, 0), 4)
    for f in 4:
        src.set_tile_animation_frame_duration(Vector2i(0, 0), f, 0.45)
    for row in range(1, TERRAINS.size()):
        for col in range(1, 20):
            src.create_tile(Vector2i(col, row))
    for col in range(0, 14):
        src.create_tile(Vector2i(col, EXTRA_ROW))
    _tile_set = ts
    return ts
