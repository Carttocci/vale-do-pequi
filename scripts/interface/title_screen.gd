class_name TitleScreen
extends Control
## Tela de título: Continuar (se houver save), Novo jogo, Opções, Créditos.

const MAIN_SCENE := "res://scenes/main/main.tscn"

var continue_button: Button
var new_button: Button
var options: OptionsPanel
var credits: PanelContainer
var _buttons: VBoxContainer
var sub: Label


## Aparece quando o site tem versão mais nova que a guardada no navegador.
var update_button: Button


func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg := TextureRect.new()
    bg.texture = load("res://assets/ui/titulo_fundo_placeholder.png")
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(bg)
    var title := Label.new()
    title.text = "Vale do Pequi"
    Settings.display_font(title, 60)
    title.add_theme_color_override("font_color", Color(0.98, 0.8, 0.2))
    title.add_theme_color_override("font_outline_color", Color(0.25, 0.14, 0.08))
    title.add_theme_constant_override("outline_size", 8)
    title.add_theme_color_override("font_shadow_color", Color(0.2, 0.1, 0.05, 0.6))
    title.add_theme_constant_override("shadow_offset_x", 0)
    title.add_theme_constant_override("shadow_offset_y", 4)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.set_anchors_preset(Control.PRESET_CENTER_TOP)
    title.position = Vector2(-300, 18)
    title.size = Vector2(600, 64)
    add_child(title)
    sub = Label.new()
    sub.text = "Uma fazenda no Cerrado goiano"
    sub.add_theme_font_size_override("font_size", 22)
    sub.add_theme_color_override("font_color", Color(1, 0.95, 0.82))
    sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    sub.add_theme_constant_override("outline_size", 4)
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
    sub.position = Vector2(-200, 84)
    sub.size = Vector2(400, 20)
    add_child(sub)
    _buttons = VBoxContainer.new()
    _buttons.add_theme_constant_override("separation", 6)
    _buttons.set_anchors_preset(Control.PRESET_CENTER)
    _buttons.position = Vector2(-90, -30)
    _buttons.custom_minimum_size = Vector2(180, 0)
    add_child(_buttons)
    continue_button = _button("Continuar", continue_game)
    new_button = _button("Novo jogo", _on_new_pressed)
    _button("Opções", func() -> void:
        _buttons.hide()
        sub.hide()
        options.open())
    _button("Créditos", func() -> void: credits.visible = not credits.visible)
    update_button = _button("Atualizar jogo", Settings.update_now)
    update_button.hide()
    Settings.update_available.connect(func(v: String) -> void:
        update_button.text = "Atualizar (v%s)" % v
        update_button.show()
        update_button.modulate = Color(1.3, 1.2, 0.7))
    if Settings.latest_version != "":
        Settings.update_available.emit(Settings.latest_version)
    else:
        Settings.check_for_update()
    if not OS.has_feature("web"):
        _button("Sair", func() -> void: get_tree().quit())
    var version := Label.new()
    version.text = "v" + str(ProjectSettings.get_setting("application/config/version", ""))
    version.add_theme_font_size_override("font_size", 13)
    version.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
    version.add_theme_constant_override("outline_size", 2)
    version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    version.position = Vector2(-60, -18)
    add_child(version)
    _build_credits()
    options = OptionsPanel.new()
    add_child(options)
    options.closed.connect(func() -> void:
        _buttons.show()
        sub.show())
    continue_button.visible = SaveManager.has_save()
    if continue_button.visible:
        var info := SaveManager.read_save_file()
        var day := int(info.get("game", {}).get("day", 1))
        continue_button.text = "Continuar (%s)" % Calendar.format_date(day)
    Audio.play_music(&"dia")


func _button(text: String, cb: Callable) -> Button:
    var b := Button.new()
    b.text = text
    Settings.big_font(b)
    b.custom_minimum_size = Vector2(200, 30)
    b.pressed.connect(func() -> void:
        Audio.play(&"clique", 0.0)
        cb.call())
    _buttons.add_child(b)
    return b


func continue_game() -> void:
    get_tree().change_scene_to_file(MAIN_SCENE)


func _on_new_pressed() -> void:
    if SaveManager.has_save() and new_button.text == "Novo jogo":
        new_button.text = "Apagar o save? De novo"
        return
    start_new_game()


func start_new_game() -> void:
    SaveManager.delete_save()
    GameState.new_game()
    get_tree().change_scene_to_file(MAIN_SCENE)


func _build_credits() -> void:
    credits = PanelContainer.new()
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.17, 0.13, 0.11, 0.95)
    box.set_content_margin_all(8)
    box.set_corner_radius_all(4)
    credits.add_theme_stylebox_override("panel", box)
    credits.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    credits.position = Vector2(10, -110)
    var l := Label.new()
    l.text = "Vale do Pequi — um jogo de Carttocci\nFeito com Godot 4. Arte baseada no Ninja Adventure de pixel-boy e AAA (CC0),\nrepintada para o Cerrado. Fontes Press Start 2P (CodeMan38, OFL) e Upheaval no título (Brian Kent, freeware).\nO resto da arte e os sons são gerados por código.\nInspirado no Cerrado goiano: o pequi, o ipê, as festas,\nas receitas e a memória do povo do interior."
    l.add_theme_font_size_override("font_size", 9)
    credits.add_child(l)
    credits.hide()
    add_child(credits)
