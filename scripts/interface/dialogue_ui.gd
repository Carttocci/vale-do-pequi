class_name DialogueUI
extends CanvasLayer
## Caixa de conversa na parte de baixo da tela. Pausa o mundo.
##
## Avança com E / botão verde / clique ou toque na caixa. Na última fala, se
## houver opções (ex.: Comprar / Vender / Tchau), mostra botões. Esc fecha.

var speaker := ""
var lines := PackedStringArray()
var options := PackedStringArray()
var index := 0

var _on_option: Callable
var _panel: PanelContainer
var _name: Label
var _text: Label
var _hint: Label
var _buttons: HBoxContainer


func _ready() -> void:
    layer = 4
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    _panel.hide()
    EventBus.dialogue_requested.connect(open)


func is_open() -> bool:
    return _panel.visible


func open(who: String, what: PackedStringArray, opts: PackedStringArray = PackedStringArray(), on_option: Callable = Callable()) -> void:
    speaker = who
    lines = what if not what.is_empty() else PackedStringArray(["..."])
    options = opts
    _on_option = on_option
    index = 0
    get_tree().paused = true
    _panel.show()
    _show_current()


## Próxima fala (ou fecha, se não houver opções na última).
func advance() -> void:
    if not is_open():
        return
    if index < lines.size() - 1:
        index += 1
        _show_current()
    elif options.is_empty():
        close(-1)


func choose(option_index: int) -> void:
    close(option_index)


func close(option_index: int = -1) -> void:
    if not is_open():
        return
    _panel.hide()
    get_tree().paused = false
    var cb := _on_option
    _on_option = Callable()
    if cb.is_valid():
        cb.call(option_index)


func _unhandled_input(event: InputEvent) -> void:
    if not is_open():
        return
    if event.is_action_pressed("menu"):
        close(-1)
    elif event.is_action_pressed("interact") or event.is_action_pressed("use_item"):
        if index < lines.size() - 1 or options.is_empty():
            advance()
    else:
        return
    get_viewport().set_input_as_handled()


func _show_current() -> void:
    _name.text = speaker
    _text.text = lines[index]
    var last := index >= lines.size() - 1
    for b in _buttons.get_children():
        b.queue_free()
    _buttons.visible = last and not options.is_empty()
    _hint.visible = not _buttons.visible
    _hint.text = "[E] continuar" if not last else "[E] fechar"
    if _buttons.visible:
        for i in options.size():
            var b := Button.new()
            b.text = "  %s  " % options[i]
            b.focus_mode = Control.FOCUS_NONE
            b.add_theme_font_size_override("font_size", 10)
            b.pressed.connect(choose.bind(i))
            _buttons.add_child(b)


func _build() -> void:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.15, 0.12, 0.11, 0.95)
    box.border_color = Color(0.72, 0.47, 0.22, 1)
    box.set_border_width_all(1)
    box.set_corner_radius_all(3)
    box.set_content_margin_all(8)
    _panel = PanelContainer.new()
    _panel.add_theme_stylebox_override("panel", box)
    _panel.anchor_left = 0.5
    _panel.anchor_right = 0.5
    _panel.anchor_top = 1.0
    _panel.anchor_bottom = 1.0
    _panel.offset_left = -220
    _panel.offset_right = 220
    _panel.offset_top = -112
    _panel.offset_bottom = -40
    _panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
    _panel.gui_input.connect(func(e: InputEvent) -> void:
        if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not _buttons.visible:
            advance())
    add_child(_panel)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 4)
    col.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _panel.add_child(col)
    _name = Label.new()
    _name.add_theme_font_size_override("font_size", 11)
    _name.add_theme_color_override("font_color", Color(0.96, 0.77, 0.11))
    col.add_child(_name)
    _text = Label.new()
    _text.add_theme_font_size_override("font_size", 10)
    _text.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86))
    _text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _text.custom_minimum_size = Vector2(420, 28)
    col.add_child(_text)
    var bottom := HBoxContainer.new()
    col.add_child(bottom)
    _buttons = HBoxContainer.new()
    _buttons.add_theme_constant_override("separation", 6)
    _buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bottom.add_child(_buttons)
    _hint = Label.new()
    _hint.add_theme_font_size_override("font_size", 8)
    _hint.add_theme_color_override("font_color", Color(0.72, 0.66, 0.58))
    _hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    bottom.add_child(_hint)
