class_name MapUI
extends CanvasLayer
## Mapa (M / botão do mapa): à esquerda a região onde você está, desenhada a
## partir do chão, com você, os moradores, as saídas e a criação; à direita o
## vale inteiro, com as regiões que você já conheceu. Pausa o jogo.

## Vale: posição de cada região no quadro da direita e por onde se liga.
const WORLD := {
    &"farm": {"pos": Vector2(44, 150), "name": "Fazenda"},
    &"vila": {"pos": Vector2(110, 108), "name": "Vila"},
    &"mata": {"pos": Vector2(190, 150), "name": "Mata"},
    &"serra": {"pos": Vector2(190, 66), "name": "Serra"},
    &"mina": {"pos": Vector2(110, 22), "name": "Mina"},
    &"ruinas": {"pos": Vector2(230, 22), "name": "Ruínas"},
}
const LINKS := [[&"farm", &"vila"], [&"vila", &"mata"], [&"mata", &"serra"], [&"serra", &"mina"], [&"serra", &"ruinas"]]
## Cor de cada coluna do atlas do chão (FarmGround.LEGEND).
const TILE_COLORS := [
    Color(0.42, 0.66, 0.3), Color(0.5, 0.7, 0.36), Color(0.8, 0.7, 0.36), Color(0.72, 0.42, 0.26),
    Color(0.46, 0.3, 0.2), Color(0.26, 0.5, 0.82), Color(0.22, 0.42, 0.2), Color(0.32, 0.56, 0.82),
    Color(0.66, 0.62, 0.58), Color(0.6, 0.45, 0.26), Color(0.36, 0.31, 0.28), Color(0.17, 0.15, 0.15),
    Color(0.55, 0.55, 0.6),
    # dentro de casa: teto, paredes (cima/baixo de 5 tipos) e 4 pisos
    Color(0.23, 0.17, 0.13), Color(0.93, 0.9, 0.84), Color(0.25, 0.45, 0.67), Color(0.85, 0.7, 0.42),
    Color(0.65, 0.35, 0.2), Color(0.71, 0.38, 0.23), Color(0.6, 0.3, 0.18), Color(0.58, 0.4, 0.24),
    Color(0.5, 0.33, 0.2), Color(0.95, 0.94, 0.92), Color(0.35, 0.58, 0.4), Color(0.69, 0.48, 0.28),
    Color(0.72, 0.36, 0.23), Color(0.9, 0.85, 0.76), Color(0.6, 0.23, 0.17), Color(0.1, 0.07, 0.06),
]

var _panel: PanelContainer
var _title: Label
var _region_tex: TextureRect
var _marks: Control
var _world: Control
var _level: Level
var _blink := 0.0


func _ready() -> void:
    layer = 3
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    _panel.hide()
    EventBus.region_entered.connect(func(r: StringName) -> void:
        GameState.set_flag(StringName("visitou_" + String(r))))


func is_open() -> bool:
    return _panel.visible


func open() -> void:
    var main := get_tree().get_first_node_in_group("save_root")
    _level = main.level if main and "level" in main else null
    if _level == null:
        return
    GameState.set_flag(StringName("visitou_" + String(_level.region_id)))
    _title.text = "%s  ·  %s" % [_level.display_name, Calendar.format_date(GameState.day)]
    _region_tex.texture = ImageTexture.create_from_image(_render_ground(_level))
    _panel.show()
    get_tree().paused = true
    _marks.queue_redraw()
    _world.queue_redraw()


func close() -> void:
    _panel.hide()
    get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
    if not is_open():
        if event.is_action_pressed("map") and not get_tree().paused:
            open()
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("map") or event.is_action_pressed("menu") or event.is_action_pressed("journal") \
            or event.is_action_pressed("inventory"):
        close()
        get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
    if is_open():
        _blink += delta
        _marks.queue_redraw()


## Uma cor por tile do chão (com o tom da estação nas regiões a céu aberto).
func _render_ground(level: Level) -> Image:
    var g := level.ground
    var size := g.map_size if g.map_size != Vector2i.ZERO else Vector2i(1, 1)
    var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
    var tint := g.modulate
    for y in size.y:
        for x in size.x:
            var col := g.get_cell_atlas_coords(Vector2i(x, y)).x
            var c: Color = TILE_COLORS[col] if col >= 0 and col < TILE_COLORS.size() else Color(0.1, 0.1, 0.1)
            img.set_pixel(x, y, c * tint)
    return img


## Posição de um ponto do mundo dentro do desenho do mapa.
func world_to_map(p: Vector2) -> Vector2:
    var tex := _region_tex.texture
    if tex == null:
        return Vector2.ZERO
    var area := _region_tex.size
    var ts := Vector2(tex.get_size())
    var scale := minf(area.x / ts.x, area.y / ts.y)
    var offset := (area - ts * scale) / 2.0
    return offset + p / FarmGround.TILE_SIZE * scale


func _draw_marks() -> void:
    if _level == null:
        return
    var font := _marks.get_theme_default_font()
    # saídas
    for n in _level.find_children("*", "RegionExit", true, false):
        var ex := n as RegionExit
        var q := world_to_map(ex.global_position - _level.global_position)
        _marks.draw_rect(Rect2(q - Vector2(3, 3), Vector2(6, 6)), Color(1, 0.85, 0.3))
        var label: String = WORLD.get(ex.target_region, {}).get("name", String(ex.target_region))
        _marks.draw_string(font, q + Vector2(5, 4), "→ " + label, HORIZONTAL_ALIGNMENT_LEFT, -1, Settings.text_size, Color(1, 0.92, 0.6))
    # moradores (com missão: "!")
    for n in get_tree().get_nodes_in_group("npc"):
        var npc := n as Node2D
        if npc == null or not _level.is_ancestor_of(npc) or not npc.visible:
            continue
        var q := world_to_map(npc.global_position - _level.global_position)
        _marks.draw_circle(q, 2.5, Color(0.55, 0.8, 1))
        if npc.has_method("has_quest_hint") and npc.has_quest_hint():
            _marks.draw_string(font, q + Vector2(-3, -3), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, Settings.text_size, Color(1, 0.9, 0.2))
    # criação
    var ranch := get_tree().get_first_node_in_group("ranch") as Ranch
    if ranch and _level.is_ancestor_of(ranch):
        for pen in [&"galinheiro", &"curral"]:
            var r := ranch.pen_rect(pen)
            var a := world_to_map(r.position - _level.global_position + ranch.global_position)
            var b := world_to_map(r.end - _level.global_position + ranch.global_position)
            _marks.draw_rect(Rect2(a, b - a), Color(0.95, 0.85, 0.6, 0.9), false, 1.0)
    # você
    var player := get_tree().get_first_node_in_group("player") as Node2D
    if player and _level.is_ancestor_of(player):
        var q := world_to_map(player.global_position - _level.global_position)
        var on := int(_blink * 3.0) % 2 == 0
        _marks.draw_circle(q, 3.5, Color(1, 1, 1) if on else Color(0.9, 0.2, 0.2))
        _marks.draw_circle(q, 2.0, Color(0.9, 0.2, 0.2))


func _draw_world() -> void:
    var font := _world.get_theme_default_font()
    var here := _level.region_id if _level else &""
    if here == &"mina" or here == &"ruinas":
        pass
    for l in LINKS:
        if _known(l[0]) and _known(l[1]):
            _world.draw_line(WORLD[l[0]].pos, WORLD[l[1]].pos, Color(0.72, 0.47, 0.22), 2.0)
    for id: StringName in WORLD:
        var p: Vector2 = WORLD[id].pos
        var known := _known(id)
        var col := Color(0.95, 0.4, 0.3) if id == here else (Color(0.85, 0.78, 0.6) if known else Color(0.4, 0.36, 0.32))
        _world.draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), col)
        _world.draw_string(font, p + Vector2(-45, 18), WORLD[id].name if known else "???",
            HORIZONTAL_ALIGNMENT_CENTER, 90, Settings.text_size, col)


func _known(id: StringName) -> bool:
    return id == &"farm" or GameState.has_flag(StringName("visitou_" + String(id)))


func _build() -> void:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.17, 0.13, 0.11, 0.96)
    box.border_color = Color(0.72, 0.47, 0.22)
    box.set_border_width_all(1)
    box.set_corner_radius_all(4)
    box.set_content_margin_all(8)
    _panel = PanelContainer.new()
    _panel.add_theme_stylebox_override("panel", box)
    _panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    _panel.offset_left = 24
    _panel.offset_right = -24
    _panel.offset_top = 16
    _panel.offset_bottom = -16
    add_child(_panel)
    var v := VBoxContainer.new()
    _panel.add_child(v)
    var top := HBoxContainer.new()
    v.add_child(top)
    _title = Label.new()
    _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(_title)
    var x := Button.new()
    x.text = " X "
    x.focus_mode = Control.FOCUS_NONE
    x.pressed.connect(close)
    top.add_child(x)
    var h := HBoxContainer.new()
    h.size_flags_vertical = Control.SIZE_EXPAND_FILL
    h.add_theme_constant_override("separation", 10)
    v.add_child(h)
    _region_tex = TextureRect.new()
    _region_tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _region_tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _region_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _region_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _region_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    h.add_child(_region_tex)
    _marks = Control.new()
    _marks.set_anchors_preset(Control.PRESET_FULL_RECT)
    _marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _marks.draw.connect(_draw_marks)
    _region_tex.add_child(_marks)
    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(270, 0)
    h.add_child(right)
    var wt := Label.new()
    wt.text = "Vale do Pequi"
    Settings.big_font(wt)
    right.add_child(wt)
    _world = Control.new()
    _world.custom_minimum_size = Vector2(270, 180)
    _world.draw.connect(_draw_world)
    right.add_child(_world)
    var legend := Label.new()
    legend.text = "● você  ● moradores\n■ saída  ! missão  □ cercados"
    legend.add_theme_color_override("font_color", Color(0.85, 0.78, 0.6))
    right.add_child(legend)
