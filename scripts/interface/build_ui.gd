class_name BuildUI
extends CanvasLayer
## Modo construção (B / botão do martelo): menu com o que dá pra construir,
## custo e requisito; escolhe e aparece uma prévia no quadrado (verde pode,
## vermelho não pode). E/clique coloca (dá pra ir colocando vários seguidos),
## B/Esc sai. "Recolher" tira o que foi construído e devolve metade do material.
## Só na fazenda.

enum Mode { CLOSED, MENU, PLACING, REMOVING }

const REMOVE := &"_recolher"

var mode: Mode = Mode.CLOSED
var selected: StringName = &""
var _panel: PanelContainer
var _list: VBoxContainer
var _info: Label
var _hint: Label
var _ghost: Sprite2D
var _last_mouse := -100000
var _target := Vector2.ZERO


func _ready() -> void:
    layer = 3
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    _panel.hide()
    _hint.hide()


func is_open() -> bool:
    return mode != Mode.CLOSED


# --- abrir / fechar -------------------------------------------------------------

func open() -> void:
    var level := _level()
    if level == null or level.region_id != &"farm":
        EventBus.show_message("Construir só na fazenda.", 2.0)
        return
    _stop_placing()
    mode = Mode.MENU
    _panel.show()
    _info.text = ""
    get_tree().paused = true
    refresh()


func close() -> void:
    _stop_placing()
    mode = Mode.CLOSED
    _panel.hide()
    get_tree().paused = false


## Escolheu no menu: começa a colocar (o jogo volta a andar).
func choose(id: StringName) -> void:
    if id != REMOVE:
        var why := Construcoes.can_build(get_tree(), id)
        if why != "":
            _info.text = why
            return
    selected = id
    mode = Mode.REMOVING if id == REMOVE else Mode.PLACING
    _panel.hide()
    get_tree().paused = false
    _ghost = Sprite2D.new()
    _ghost.z_index = 10
    if id == REMOVE:
        _ghost.texture = _square_texture()
        _ghost.offset = Vector2(0, -7)
    else:
        _ghost.texture = load(_texture_of(id))
        _ghost.offset = Vector2(0, -7) if Construcoes.ALL[id].get("floor", false) else Vector2(0, -_ghost.texture.get_height() / 2.0 + 2)
    _level().get_entities_root().add_child(_ghost)
    _update_hint()


## Quadradinho vazado (mira do "Recolher").
func _square_texture() -> Texture2D:
    var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    for i in 16:
        for j in [0, 1, 14, 15]:
            img.set_pixel(i, j, Color.WHITE)
            img.set_pixel(j, i, Color.WHITE)
    return ImageTexture.create_from_image(img)


func _stop_placing() -> void:
    if is_instance_valid(_ghost):
        _ghost.queue_free()
    _ghost = null
    _hint.hide()


func _texture_of(id: StringName) -> String:
    match String(Construcoes.ALL[id].type):
        "bau":
            return "res://assets/environments/bau_placeholder.png"
        "decor":
            return "res://assets/environments/%s_placeholder.png" % id
    return "res://assets/environments/%s_placeholder.png" % id


# --- entrada --------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _last_mouse = Time.get_ticks_msec()
    if mode == Mode.CLOSED:
        if event.is_action_pressed("build") and not get_tree().paused:
            open()
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("build") or event.is_action_pressed("menu"):
        if mode == Mode.MENU:
            close()
        else:
            _stop_placing()
            mode = Mode.MENU
            _panel.show()
            get_tree().paused = true
            refresh()
        get_viewport().set_input_as_handled()
        return
    if mode in [Mode.PLACING, Mode.REMOVING]:
        var touch_emul := event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION
        if (event.is_action_pressed("interact") or event.is_action_pressed("use_item")) and not touch_emul:
            if event is InputEventMouseButton:
                _last_mouse = Time.get_ticks_msec()
                _update_target()
            confirm()
            get_viewport().set_input_as_handled()
        elif event.is_action_pressed("attack") or event.is_action_pressed("use_item"):
            get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
    if mode in [Mode.PLACING, Mode.REMOVING] and is_instance_valid(_ghost):
        _update_target()
        _ghost.global_position = _target
        var ok := can_place_at(_target) if mode == Mode.PLACING else _removable_at(_target) != null
        _ghost.modulate = Color(0.6, 1.0, 0.6, 0.75) if ok else Color(1.0, 0.45, 0.45, 0.6)


## Mira: o mouse (se mexeu há pouco, no PC) ou o quadrado à frente do jogador.
func _update_target() -> void:
    var level := _level()
    var player := get_tree().get_first_node_in_group("player") as Player
    if level == null or player == null:
        return
    var pos := player.get_target_position()
    if Time.get_ticks_msec() - _last_mouse < 3000 and not DisplayServer.is_touchscreen_available():
        pos = level.get_global_mouse_position()
    _target = snap(level, pos)


func snap(level: Level, pos: Vector2) -> Vector2:
    var cell := level.ground.local_to_map(level.ground.to_local(pos))
    return level.ground.to_global(level.ground.map_to_local(cell)) + Vector2(0, 7)


# --- regras ---------------------------------------------------------------------

func can_place_at(pos: Vector2) -> bool:
    return why_not_at(pos) == ""


func why_not_at(pos: Vector2) -> String:
    var level := _level()
    if level == null or level.region_id != &"farm":
        return "Só na fazenda."
    var cell := level.ground.local_to_map(level.ground.to_local(pos))
    if level.ground.get_cell_source_id(cell) == -1 or not level.get_world_rect().has_point(pos):
        return "Fora do mapa."
    if level.ground.is_solid_at(pos):
        return "Aqui é água."
    var placed := _placed(level)
    for c in placed.get_children():
        if not c.is_queued_for_deletion() and (c as Node2D).position.distance_to(placed.to_local(pos)) < 8.0:
            return "Já tem coisa aqui."
    for f in get_tree().get_nodes_in_group("debris_field"):
        if f.kind_at(f.cell_at(pos)) != &"":
            return "Limpe o mato/pedra/árvore antes."
    var field := level.get_node_or_null("FarmField") as FarmField
    if field and field.cells.has(field.cell_at(pos)):
        return "Aqui é roça."
    if not Construcoes.ALL[selected].get("floor", false):
        if not level.is_walkable(pos):
            return "Tem coisa no caminho."
        var player := get_tree().get_first_node_in_group("player") as Node2D
        if player and level.ground.local_to_map(level.ground.to_local(player.global_position)) == cell:
            return "Saia de cima primeiro."
    return ""


func confirm() -> bool:
    _update_target()
    if mode == Mode.REMOVING:
        return remove_at(_target)
    return place_at(_target)


## Constrói `selected` em `pos` (já pagando). Retorna true se construiu.
func place_at(pos: Vector2) -> bool:
    var why := Construcoes.can_build(get_tree(), selected)
    if why == "":
        why = why_not_at(pos)
    if why != "":
        EventBus.show_message(why, 1.5)
        return false
    var level := _level()
    var info: Dictionary = Construcoes.ALL[selected]
    var obj: Node2D
    match String(info.type):
        "bau":
            obj = (load("res://scenes/farm/objects/bau.tscn") as PackedScene).instantiate()
        "decor":
            obj = (load("res://scenes/decor/decor.tscn") as PackedScene).instantiate()
            obj.setup_from_item(ItemDB.get_item(selected))
        _:
            obj = (load("res://scenes/building/construcao.tscn") as PackedScene).instantiate()
            (obj as Construcao).setup(selected)
    var placed := _placed(level)
    obj.position = placed.to_local(pos)
    placed.add_child(obj)
    if info.type == "bau":
        obj.add_to_group("construcao")
        obj.add_to_group("construcao_bau")
        obj.set_meta("build_id", "bau")
    Construcoes.pay(selected)
    Audio.play(&"capinar")
    FX.burst(level.get_entities_root(), level.get_entities_root().to_local(pos) + Vector2(0, -4), FX.WOOD, 5)
    _refresh_nav(level)
    if Construcoes.can_build(get_tree(), selected) != "":
        _update_hint("Acabou o material pra mais um.")
    else:
        _update_hint()
    return true


## O que dá pra recolher no quadrado: peça construída ou baú vazio feito aqui.
func _removable_at(pos: Vector2) -> Node2D:
    var level := _level()
    if level == null:
        return null
    var placed := _placed(level)
    for c in placed.get_children():
        if c.is_queued_for_deletion() or (c as Node2D).position.distance_to(placed.to_local(pos)) >= 8.0:
            continue
        if c is Construcao or c.has_meta("build_id"):
            return c
    return null


func remove_at(pos: Vector2) -> bool:
    var n := _removable_at(pos)
    if n == null:
        EventBus.show_message("Nada construído aqui pra recolher.", 1.5)
        return false
    if n is Chest and not _chest_empty(n as Chest):
        EventBus.show_message("Esvazie o baú antes.", 1.5)
        return false
    var id: StringName = (n as Construcao).id if n is Construcao else StringName(n.get_meta("build_id"))
    Construcoes.refund(id)
    n.get_parent().remove_child(n)
    n.queue_free()
    _refresh_nav(_level())
    Audio.play(&"pegar")
    return true


## A física só atualiza no próximo quadro: refaz o mapa de passagem agora e de novo depois.
func _refresh_nav(level: Level) -> void:
    level.invalidate_nav()
    get_tree().physics_frame.connect(func() -> void:
        if is_instance_valid(level):
            level.invalidate_nav(), CONNECT_ONE_SHOT)


func _chest_empty(c: Chest) -> bool:
    for i in c.inventory.size():
        if c.inventory.get_item_id(i) != &"":
            return false
    return true


func _placed(level: Level) -> Node2D:
    var p := get_tree().get_first_node_in_group("save_root").get_node("Placement")
    return p._container(level)


func _level() -> Level:
    var main := get_tree().get_first_node_in_group("save_root")
    return main.level if main and "level" in main else null


# --- tela -----------------------------------------------------------------------

func _update_hint(extra: String = "") -> void:
    var what := "Recolher (devolve metade)" if selected == REMOVE else String(Construcoes.ALL[selected].name)
    _hint.text = "%s   E/clique: %s   B: menu   %s" % [what, "recolher" if selected == REMOVE else "construir", extra]
    _hint.show()


func refresh() -> void:
    for c in _list.get_children():
        _list.remove_child(c)
        c.queue_free()
    var rm := Button.new()
    rm.text = "Recolher construção (devolve metade do material)"
    rm.focus_mode = Control.FOCUS_NONE
    rm.pressed.connect(choose.bind(REMOVE))
    _list.add_child(rm)
    for id: StringName in Construcoes.ORDER:
        var info: Dictionary = Construcoes.ALL[id]
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 6)
        var icon := TextureRect.new()
        var tex := load(_texture_of(id)) as Texture2D
        icon.texture = tex
        icon.custom_minimum_size = Vector2(16, 16)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        row.add_child(icon)
        var col := VBoxContainer.new()
        col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        col.add_theme_constant_override("separation", 0)
        var title := Label.new()
        var req := Construcoes.missing_req(id)
        var mx := int(info.get("max", 0))
        title.text = String(info.name) + (" (%d/%d)" % [Construcoes.count_built(get_tree(), id), mx] if mx > 0 else "")
        col.add_child(title)
        var sub := Label.new()
        sub.text = Construcoes.cost_text(id) + ("   — precisa: " + req if req != "" else "")
        sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        sub.add_theme_color_override("font_color", Color(1, 0.55, 0.5) if req != "" else (
            Color(1, 0.8, 0.5) if Construcoes.missing_cost(id) != "" else Color(0.75, 0.95, 0.7)))
        col.add_child(sub)
        var desc := Label.new()
        desc.text = String(info.desc)
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
        col.add_child(desc)
        row.add_child(col)
        var b := Button.new()
        b.text = "Construir"
        b.focus_mode = Control.FOCUS_NONE
        b.disabled = Construcoes.can_build(get_tree(), id) != ""
        b.pressed.connect(choose.bind(id))
        row.add_child(b)
        if req != "":
            row.modulate = Color(1, 1, 1, 0.6)
        _list.add_child(row)


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
    _panel.offset_left = 40
    _panel.offset_right = -40
    _panel.offset_top = 20
    _panel.offset_bottom = -20
    add_child(_panel)
    var v := VBoxContainer.new()
    _panel.add_child(v)
    var top := HBoxContainer.new()
    v.add_child(top)
    var t := Label.new()
    t.text = "Construir na fazenda"
    t.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
    t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(t)
    var x := Button.new()
    x.text = " X "
    x.focus_mode = Control.FOCUS_NONE
    x.pressed.connect(close)
    top.add_child(x)
    _info = Label.new()
    _info.add_theme_color_override("font_color", Color(1, 0.6, 0.5))
    v.add_child(_info)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(scroll)
    _list = VBoxContainer.new()
    _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _list.add_theme_constant_override("separation", 6)
    scroll.add_child(_list)
    var hb := StyleBoxFlat.new()
    hb.bg_color = Color(0.12, 0.09, 0.08, 0.85)
    hb.set_content_margin_all(4)
    _hint = Label.new()
    _hint.add_theme_stylebox_override("normal", hb)
    _hint.position = Vector2(232, 40)
    _hint.custom_minimum_size = Vector2(390, 0)
    _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(_hint)
