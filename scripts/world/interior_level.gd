class_name InteriorLevel
extends Level
## Dentro de uma casa: quarto, cozinha, cama... Cada casa tem o seu jeito.
##
## A planta (paredes e pisos) fica em data/maps/interior_<layout>.txt e os
## móveis em data/interiores.json (os dois gerados por tools/arte/interiores.py).
## Uma cena só (scenes/interior/interior.tscn)
## serve para todas: a cena principal instancia uma vez por casa, mudando
## `layout`. A porta (embaixo) leva de volta para fora, no marcador `porta`.
##
## Móvel: [textura, [x, y] da base (px), [largura, altura] do corpo sólido, dica do E, ação]
##   ação "dormir"  -> cama do jogador (passa o dia e salva)
##   ação "cozinha" -> fogão a lenha (receitas)
##   outro texto    -> mensagem curta ao apertar E

@export var layout: StringName = &"casa"

## Planta e móveis de todas as casas (gerado por tools/arte/interiores.py).
const DATA_PATH := "res://data/interiores.json"

static var _all: Dictionary = {}


static func layouts() -> Dictionary:
    if _all.is_empty():
        var f := FileAccess.open(DATA_PATH, FileAccess.READ)
        if f:
            _all = JSON.parse_string(f.get_as_text())
    return _all


var bed: Prop
var stove: Prop
## Tapetes e capacho: ficam no chão, sempre embaixo de quem passa.
var _floor_decor: Node2D


func _enter_tree() -> void:
    var info: Dictionary = layouts()[String(layout)]
    region_id = layout
    display_name = info.name
    indoor = true
    if info.save_outside:
        save_as_region = StringName(info.outside)
        save_as_spawn = StringName(info.outside_spawn)
    var g := get_node_or_null("Ground") as FarmGround
    if g:
        g.map_path = "res://data/maps/interior_%s.txt" % layout


func _ready() -> void:
    super._ready()
    var info: Dictionary = layouts()[String(layout)]
    _build_backdrop()
    _floor_decor = Node2D.new()
    _floor_decor.name = "Tapetes"
    add_child(_floor_decor)
    move_child(_floor_decor, ground.get_index() + 1)
    var door := Vector2i(int(info.door[0]), int(info.door[1]))
    var door_pos := Vector2(door.x * FarmGround.TILE_SIZE + 8, door.y * FarmGround.TILE_SIZE + 8)
    _marker(&"entrada", door_pos + Vector2(0, -18), 4)
    player_spawn.position = door_pos + Vector2(0, -18)
    if info.has("bed_spot"):
        _marker(&"cama", Vector2(info.bed_spot[0], info.bed_spot[1]), 4)
    # capacho e saída
    var mat := Prop.new().setup("capacho", Vector2.ZERO, "")
    mat.position = door_pos + Vector2(0, -6)
    _floor_decor.add_child(mat)
    var exit := RegionExit.new()
    exit.name = "Saida"
    exit.target_region = StringName(info.outside)
    exit.target_spawn = StringName(info.outside_spawn)
    exit.position = door_pos + Vector2(0, 4)
    var shape := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(16, 8)
    shape.shape = r
    exit.add_child(shape)
    add_child(exit)
    for it: Array in info.items:
        _add_item(it)


func _add_item(it: Array) -> void:
    var body := Vector2(it[2][0], it[2][1])
    var p := Prop.new().setup(it[0], body, it[3], 14.0)
    p.position = Vector2(it[1][0], it[1][1])
    if String(it[0]).begins_with("tapete"):
        _floor_decor.add_child(p)
    else:
        get_entities_root().add_child(p)
    var action: String = it[4]
    match action:
        "":
            pass
        "dormir":
            bed = p
            p.used.connect(func(_a: Node) -> void: HouseDoor.sleep_and_save())
        "cozinha":
            stove = p
            p.used.connect(func(_a: Node) -> void: EventBus.craft_requested.emit("cozinha"))
        _:
            p.used.connect(func(_a: Node) -> void: EventBus.show_message(action, 3.0))


func _marker(n: StringName, pos: Vector2, facing: int) -> void:
    var markers := get_node_or_null("Markers")
    if markers == null:
        markers = Node2D.new()
        markers.name = "Markers"
        add_child(markers)
    var m := Marker2D.new()
    m.name = n
    m.position = pos
    m.set_meta("facing", facing)
    markers.add_child(m)


## Fundo escuro em volta da casa (a câmera mostra além das paredes).
func _build_backdrop() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.1, 0.07, 0.06)
    bg.position = Vector2(-1000, -1000)
    bg.size = Vector2(2000 + get_world_rect().size.x, 2000 + get_world_rect().size.y)
    bg.z_index = -20
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    move_child(bg, 0)
