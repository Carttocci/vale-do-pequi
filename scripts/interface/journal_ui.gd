class_name JournalUI
extends CanvasLayer
## Diário (J / botão do caderno): Missões, Caderno de campo e Habilidades.
## Pausa o mundo enquanto está aberto. No toque: abas e botões grandes.

const TABS := ["Missões", "Caderno", "Habilidades"]
const PATH_NAMES := {&"guerreiro": "Guerreiro (dano e defesa)", &"cacador": "Caçador (arco)", &"explorador": "Explorador (energia)"}

var tab: int = 0
var _panel: PanelContainer
var _tab_buttons: Array[Button] = []
var _body: VBoxContainer
var _scroll: ScrollContainer


func _ready() -> void:
    layer = 3
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    _panel.hide()
    GameState.journal_changed.connect(func() -> void: if is_open(): refresh())
    Quests.quest_updated.connect(func(_id: String) -> void: if is_open(): refresh())


func is_open() -> bool:
    return _panel.visible


func open(which: int = -1) -> void:
    if which >= 0:
        tab = which
    _panel.show()
    get_tree().paused = true
    refresh()


func close() -> void:
    _panel.hide()
    get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
    if not is_open():
        if event.is_action_pressed("journal") and not get_tree().paused:
            open()
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("journal") or event.is_action_pressed("menu"):
        close()
    elif event.is_action_pressed("hotbar_next") or event.is_action_pressed("move_right"):
        set_tab((tab + 1) % TABS.size())
    elif event.is_action_pressed("hotbar_prev") or event.is_action_pressed("move_left"):
        set_tab((tab + TABS.size() - 1) % TABS.size())
    else:
        return
    get_viewport().set_input_as_handled()


func set_tab(i: int) -> void:
    tab = i
    refresh()


## Texto visível do diário (usado pelos testes).
func body_text() -> String:
    var parts := PackedStringArray()
    for c in _body.get_children():
        if c is Label:
            parts.append((c as Label).text)
        elif c is HBoxContainer:
            for cc in c.get_children():
                if cc is Label:
                    parts.append((cc as Label).text)
    return "\n".join(parts)


func refresh() -> void:
    for i in _tab_buttons.size():
        _tab_buttons[i].modulate = Color.WHITE if i == tab else Color(1, 1, 1, 0.55)
    for c in _body.get_children():
        _body.remove_child(c)
        c.queue_free()
    match tab:
        0: _fill_quests()
        1: _fill_notebook()
        2: _fill_skills()


func _fill_quests() -> void:
    var any := false
    for id in Quests.order:
        if not Quests.is_active(id):
            continue
        any = true
        var q: Dictionary = Quests.defs[id]
        _label(("★ " if q.get("main", false) else "• ") + q.title, 11, Color(1, 0.85, 0.45) if q.get("main", false) else Color.WHITE)
        _label("   " + q.desc, 9, Color(0.85, 0.8, 0.72))
        var s := Quests.step(id)
        var text: String = s.get("text", "")
        if s.get("type", "") == "kill":
            text += "  (%d/%d)" % [int(Quests.counters.get(id, 0)), int(s.count)]
        elif s.get("type", "") == "deliver":
            text += "  (%d/%d)" % [mini(GameState.get_item_count(StringName(s.item)), int(s.count)), int(s.count)]
        _label("   → " + text, 9, Color(0.7, 0.95, 0.7))
    if not any:
        _label("Nenhuma missão ativa. Veja o mural da praça!", 10)
    _label("Concluídas: %d" % Quests.done.size(), 9, Color(0.75, 0.75, 0.75))


func _fill_notebook() -> void:
    _label("Peixes (%d/%d)" % [GameState.fish_log.size(), ItemDB.all_fish().size()], 11, Color(0.6, 0.85, 1))
    for f in ItemDB.all_fish():
        var item := ItemDB.get_item(f.item)
        var n := int(GameState.fish_log.get(f.item, 0))
        _label("   %s  %s" % [item.display_name if item else String(f.item), ("×%d" % n) if n > 0 else "—"], 9,
            Color.WHITE if n > 0 else Color(0.6, 0.6, 0.6))
    _label("Bichos do Cerrado (%d/%d)" % [GameState.species_seen.size(), WildAnimal.SPECIES.size()], 11, Color(0.75, 0.95, 0.6))
    for sp: StringName in WildAnimal.SPECIES:
        var info: Dictionary = WildAnimal.SPECIES[sp]
        var seen := GameState.species_seen.has(sp)
        _label("   %s  %s" % [info.name, ("(%s)" % info.sci) if seen else "— ainda não visto"], 9,
            Color.WHITE if seen else Color(0.6, 0.6, 0.6))


func _fill_skills() -> void:
    for sk: StringName in GameState.SKILLS:
        var lvl := GameState.skill_level(sk)
        _label("%s   nível %d" % [GameState.SKILL_NAMES[sk], lvl], 10)
    _label("Caminhos de combate — pontos livres: %d" % GameState.path_points_free(), 11, Color(1, 0.75, 0.5))
    for p: StringName in PATH_NAMES:
        var row := HBoxContainer.new()
        var l := Label.new()
        l.text = "%s: %d" % [PATH_NAMES[p], int(GameState.paths[p])]
        l.add_theme_font_size_override("font_size", 9)
        l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(l)
        var b := Button.new()
        b.text = " + "
        b.focus_mode = Control.FOCUS_NONE
        b.disabled = GameState.path_points_free() <= 0
        b.pressed.connect(func() -> void: GameState.add_path_point(p))
        row.add_child(b)
        _body.add_child(row)
    var reset := Button.new()
    reset.text = "Redistribuir pontos"
    reset.focus_mode = Control.FOCUS_NONE
    reset.add_theme_font_size_override("font_size", 9)
    reset.pressed.connect(GameState.reset_paths)
    _body.add_child(reset)


func _label(text: String, size: int = 10, color := Color.WHITE) -> Label:
    var l := Label.new()
    l.text = text
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    _body.add_child(l)
    return l


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
    _panel.offset_top = 24
    _panel.offset_bottom = -24
    add_child(_panel)
    var v := VBoxContainer.new()
    _panel.add_child(v)
    var top := HBoxContainer.new()
    v.add_child(top)
    for i in TABS.size():
        var b := Button.new()
        b.text = "  %s  " % TABS[i]
        b.focus_mode = Control.FOCUS_NONE
        b.add_theme_font_size_override("font_size", 10)
        b.pressed.connect(set_tab.bind(i))
        top.add_child(b)
        _tab_buttons.append(b)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(spacer)
    var x := Button.new()
    x.text = " X "
    x.focus_mode = Control.FOCUS_NONE
    x.pressed.connect(close)
    top.add_child(x)
    _scroll = ScrollContainer.new()
    _scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(_scroll)
    _body = VBoxContainer.new()
    _body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _scroll.add_child(_body)
