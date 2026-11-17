class_name RecipeUI
extends CanvasLayer
## Tela do fogão a lenha (receitas) e da bancada (objetos + obras da fazenda).
## Pausa o mundo. Toque/clique em "Fazer" usa os ingredientes da mochila.

var station: String = ""
var _panel: PanelContainer
var _title: Label
var _list: VBoxContainer
var _info: Label


func _ready() -> void:
    layer = 3
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    _panel.hide()
    EventBus.craft_requested.connect(open)
    GameState.inventory.changed.connect(func() -> void: if is_open(): refresh())


func is_open() -> bool:
    return _panel.visible


func open(which: String) -> void:
    station = which
    _info.text = ""
    _panel.show()
    get_tree().paused = true
    refresh()


func close() -> void:
    _panel.hide()
    get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
    if is_open() and (event.is_action_pressed("menu") or event.is_action_pressed("inventory")):
        close()
        get_viewport().set_input_as_handled()


## Receitas mostradas agora (as de cozinha só as conhecidas).
func entries() -> Array:
    var out := []
    if station == "cozinha":
        for r in Recipes.station("cozinha"):
            if GameState.knows_recipe(StringName(r.id)):
                out.append(r)
    else:
        out.append_array(Recipes.station("bancada"))
        out.append_array(Recipes.station("obras"))
    return out


## Faz a receita `id` (usado pelos botões e pelos testes).
func make(id: String) -> bool:
    for r in entries():
        if r.id == id:
            var ok := Recipes.make(r)
            if ok and not Recipes.is_obra(r):
                var it := ItemDB.get_item(StringName(r.out))
                _info.text = "Pronto: %s ×%d" % [it.display_name if it else r.out, int(r.get("count", 1))]
            elif not ok:
                _info.text = "Falta ingrediente (ou espaço na mochila)."
            refresh()
            return ok
    return false


func refresh() -> void:
    _title.text = "Fogão a lenha" if station == "cozinha" else "Bancada e obras da fazenda"
    for c in _list.get_children():
        _list.remove_child(c)
        c.queue_free()
    if station == "cozinha":
        var missing := Recipes.station("cozinha").size() - entries().size()
        if missing > 0:
            _small("Receitas de família que faltam: %d (os moradores ensinam quando ficam amigos)." % missing)
    for r in entries():
        var row := HBoxContainer.new()
        var col := VBoxContainer.new()
        col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var name := Label.new()
        if Recipes.is_obra(r):
            name.text = "Obra: %s — %s" % [r.name, r.desc]
        else:
            var it := ItemDB.get_item(StringName(r.out))
            var extra := ""
            if it and it.category == ItemData.Category.FOOD:
                extra = "  (+%d energia, +%d vida)" % [it.energy, it.health]
            name.text = "%s%s%s" % [it.display_name if it else r.out, (" ×%d" % int(r.count)) if int(r.get("count", 1)) > 1 else "", extra]
        name.add_theme_font_size_override("font_size", 10)
        col.add_child(name)
        var ing := Label.new()
        ing.text = "   " + Recipes.ingredients_text(r)
        ing.add_theme_font_size_override("font_size", 8)
        ing.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
        col.add_child(ing)
        row.add_child(col)
        var b := Button.new()
        b.focus_mode = Control.FOCUS_NONE
        if Recipes.is_obra(r) and Recipes.obra_done(r):
            b.text = " Feita ✓ "
            b.disabled = true
        else:
            b.text = " Construir " if Recipes.is_obra(r) else " Fazer "
            b.disabled = not Recipes.can_make(r)
            b.pressed.connect(make.bind(String(r.id)))
        row.add_child(b)
        _list.add_child(row)


func _small(text: String) -> void:
    var l := Label.new()
    l.text = text
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", 8)
    l.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
    _list.add_child(l)


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
    _panel.offset_left = 60
    _panel.offset_right = -60
    _panel.offset_top = 24
    _panel.offset_bottom = -24
    add_child(_panel)
    var v := VBoxContainer.new()
    _panel.add_child(v)
    var top := HBoxContainer.new()
    v.add_child(top)
    _title = Label.new()
    _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _title.add_theme_font_size_override("font_size", 12)
    _title.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
    top.add_child(_title)
    var x := Button.new()
    x.text = " X "
    x.focus_mode = Control.FOCUS_NONE
    x.pressed.connect(close)
    top.add_child(x)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(scroll)
    _list = VBoxContainer.new()
    _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(_list)
    _info = Label.new()
    _info.add_theme_font_size_override("font_size", 9)
    _info.add_theme_color_override("font_color", Color(0.7, 0.95, 0.7))
    v.add_child(_info)
