class_name OptionsPanel
extends PanelContainer
## Painel de opções (tela de título e menu de pausa): volume da música e dos
## efeitos, dica de missão na tela e tela cheia.

signal closed

var music_slider: HSlider
var sfx_slider: HSlider
var hint_check: CheckButton
var zoom_slider: HSlider


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.17, 0.13, 0.11, 0.97)
    box.border_color = Color(0.72, 0.47, 0.22)
    box.set_border_width_all(1)
    box.set_corner_radius_all(4)
    box.set_content_margin_all(10)
    add_theme_stylebox_override("panel", box)
    set_anchors_preset(Control.PRESET_CENTER)
    custom_minimum_size = Vector2(260, 0)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 6)
    add_child(v)
    var title := Label.new()
    title.text = "Opções"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 14)
    title.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
    v.add_child(title)
    music_slider = _slider(v, "Música", Settings.music_volume, Settings.set_music_volume)
    sfx_slider = _slider(v, "Efeitos", Settings.sfx_volume, func(x: float) -> void:
        Settings.set_sfx_volume(x)
        Audio.play(&"clique", 0.0))
    zoom_slider = _slider(v, "Zoom", 0.0, func(x: float) -> void:
        Settings.set_camera_zoom(lerpf(Settings.ZOOM_MIN, Settings.ZOOM_MAX, x)))
    hint_check = CheckButton.new()
    hint_check.text = "Missão atual na tela"
    hint_check.button_pressed = Settings.show_quest_hint
    hint_check.add_theme_font_size_override("font_size", 10)
    hint_check.toggled.connect(Settings.set_show_quest_hint)
    v.add_child(hint_check)
    var full := Button.new()
    full.text = "Tela cheia"
    full.add_theme_font_size_override("font_size", 10)
    full.visible = not OS.has_feature("web_ios")
    full.pressed.connect(func() -> void:
        Settings.toggle_fullscreen())
    v.add_child(full)
    var back := Button.new()
    back.text = "Voltar"
    back.add_theme_font_size_override("font_size", 11)
    back.pressed.connect(close)
    v.add_child(back)
    hide()


func open() -> void:
    music_slider.set_value_no_signal(Settings.music_volume)
    sfx_slider.set_value_no_signal(Settings.sfx_volume)
    zoom_slider.set_value_no_signal(inverse_lerp(Settings.ZOOM_MIN, Settings.ZOOM_MAX, Settings.camera_zoom))
    hint_check.set_pressed_no_signal(Settings.show_quest_hint)
    show()
    # centraliza (o tamanho só é conhecido depois de mostrar)
    reset_size()
    position = (get_viewport_rect().size - size) / 2.0


func close() -> void:
    hide()
    Audio.play(&"clique", 0.0)
    closed.emit()


func _slider(parent: Control, label: String, value: float, on_change: Callable) -> HSlider:
    var row := HBoxContainer.new()
    var l := Label.new()
    l.text = label
    l.custom_minimum_size = Vector2(60, 0)
    l.add_theme_font_size_override("font_size", 10)
    row.add_child(l)
    var s := HSlider.new()
    s.min_value = 0.0
    s.max_value = 1.0
    s.step = 0.05
    s.value = value
    s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    s.custom_minimum_size = Vector2(150, 20)
    s.value_changed.connect(on_change)
    row.add_child(s)
    parent.add_child(row)
    return s
