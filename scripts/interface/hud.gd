extends CanvasLayer
## HUD da Fase 1: dica de interação, mensagens curtas, contador de pequi e
## menu de pausa. Só escuta o EventBus; não conhece jogador nem objetos.

@onready var prompt_label: Label = $Root/Prompt
@onready var message_label: Label = $Root/Message
@onready var message_timer: Timer = $MessageTimer
@onready var day_label: Label = $Root/DayBox/Day
@onready var hotbar: Hotbar = $Root/Hotbar
@onready var save_button: Button = $Root/PauseMenu/Panel/Buttons/Save
@onready var new_game_button: Button = $Root/PauseMenu/Panel/Buttons/NewGame
@onready var pause_menu: Control = $Root/PauseMenu
@onready var resume_button: Button = $Root/PauseMenu/Panel/Buttons/Resume
@onready var quit_button: Button = $Root/PauseMenu/Panel/Buttons/Quit
@onready var rotate_hint: Control = $Root/RotateHint

var _message_tween: Tween
var _touch_mode := false
var _prompt_text := ""


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    prompt_label.hide()
    message_label.hide()
    pause_menu.hide()
    EventBus.interaction_prompt_changed.connect(_on_prompt_changed)
    EventBus.message_requested.connect(_on_message_requested)
    GameState.day_changed.connect(func(_d: int) -> void: update_clock())
    Clock.time_changed.connect(func(_m: int) -> void: update_clock())
    Clock.day_started.connect(func(_d: int, _w: int) -> void: update_clock())
    GameState.money_changed.connect(func(_m: int) -> void: update_clock())
    update_clock()
    _build_bars()
    _build_boss_bar()
    _build_tracker()
    _build_menu_extras()
    save_button.pressed.connect(_on_save_pressed)
    new_game_button.pressed.connect(_on_new_game_pressed)
    message_timer.timeout.connect(_fade_message)
    resume_button.pressed.connect(set_paused.bind(false))
    quit_button.pressed.connect(func() -> void: get_tree().quit())
    # No navegador não existe "sair do jogo": é só fechar a aba.
    quit_button.visible = not OS.has_feature("web")
    EventBus.touch_mode_changed.connect(_on_touch_mode_changed)
    _update_rotate_hint()


func _process(_delta: float) -> void:
    # Dica de ação some enquanto há conversa/loja/menu na frente.
    prompt_label.visible = _prompt_text != "" and not get_tree().paused
    _update_boss_bar()
    # Checagem barata a cada quadro: o sinal de redimensionamento não é
    # confiável em todos os navegadores quando o celular gira.
    _update_rotate_hint()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("menu"):
        if options_panel and options_panel.visible:
            options_panel.close()
            get_viewport().set_input_as_handled()
            return
        set_paused(not get_tree().paused)
        get_viewport().set_input_as_handled()


func set_paused(paused: bool) -> void:
    if options_panel:
        options_panel.hide()
    get_tree().paused = paused
    pause_menu.visible = paused
    new_game_button.text = "Novo jogo"
    if paused:
        resume_button.grab_focus()
    EventBus.pause_changed.emit(paused)


func _on_prompt_changed(text: String) -> void:
    _prompt_text = text
    prompt_label.visible = text != ""
    # No celular a dica aponta para o botão verde, não para a tecla E.
    prompt_label.text = (text + "  (botão verde)") if _touch_mode else ("[E] " + text)


func _on_touch_mode_changed(enabled: bool) -> void:
    _touch_mode = enabled
    _on_prompt_changed(_prompt_text)


## Celular/tablet em pé: o jogo é horizontal, então pede para girar a tela.
func _update_rotate_hint() -> void:
    # Só em aparelho de toque: no PC uma janela estreita não deve bloquear o jogo.
    var touch_device := OS.has_feature("mobile") or OS.has_feature("web_android") \
            or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
    var win := DisplayServer.window_get_size()
    var portrait := touch_device and win.y > win.x
    if rotate_hint.visible != portrait:
        rotate_hint.visible = portrait


func _on_message_requested(text: String, duration: float) -> void:
    if _message_tween:
        _message_tween.kill()
    message_label.text = text
    message_label.modulate.a = 1.0
    message_label.show()
    message_timer.start(duration)


func _fade_message() -> void:
    _message_tween = create_tween()
    _message_tween.tween_property(message_label, "modulate:a", 0.0, 0.4)
    _message_tween.tween_callback(message_label.hide)


func _on_save_pressed() -> void:
    var ok := SaveManager.save_game()
    save_button.text = "Salvo!" if ok else "Erro ao salvar"
    get_tree().create_timer(1.5, true, false, true).timeout.connect(func() -> void: save_button.text = "Salvar jogo")


## Novo jogo apaga o save: pede um segundo toque para confirmar
## (sem janela de confirmação do navegador).
func _on_new_game_pressed() -> void:
    if new_game_button.text == "Novo jogo":
        new_game_button.text = "Apagar save? Toque de novo"
        return
    SaveManager.delete_save()
    GameState.new_game()
    get_tree().paused = false
    get_tree().reload_current_scene()


## "Seg, 1 Out  06:00" / "Chuva · Período chuvoso"
func update_clock() -> void:
    day_label.text = "%s  %s\n%s · %s\nR$ %d" % [Calendar.format_date(GameState.day), Calendar.format_time(Clock.minutes),
        Clock.weather_name(), Calendar.period_name(GameState.day).trim_prefix("Período "), GameState.money]


# --- vida e energia -------------------------------------------------------------

var health_bar: Control
var energy_bar: Control


func _build_bars() -> void:
    var box := VBoxContainer.new()
    box.position = Vector2(8, 54)
    box.add_theme_constant_override("separation", 2)
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Root.add_child(box)
    health_bar = _make_bar(Color(0.85, 0.25, 0.25), func() -> float: return float(GameState.health) / GameState.MAX_HEALTH)
    energy_bar = _make_bar(Color(0.95, 0.75, 0.2), func() -> float: return float(GameState.energy) / GameState.MAX_ENERGY)
    box.add_child(health_bar)
    box.add_child(energy_bar)
    GameState.health_changed.connect(func(_v: int, _m: int) -> void: health_bar.queue_redraw())
    GameState.energy_changed.connect(func(_v: int, _m: int) -> void: energy_bar.queue_redraw())


# --- chefe: barra grande no topo ---------------------------------------------

var boss_box: VBoxContainer
var boss_name: Label
var boss_bar: Control
var boss: Enemy


func _build_boss_bar() -> void:
    boss_box = VBoxContainer.new()
    boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
    boss_box.position = Vector2(-110, 40)
    boss_box.custom_minimum_size = Vector2(220, 0)
    boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    boss_box.add_theme_constant_override("separation", 1)
    $Root.add_child(boss_box)
    boss_name = Label.new()
    boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_name.add_theme_color_override("font_color", Color(0.85, 0.75, 1))
    boss_name.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.1))
    boss_name.add_theme_constant_override("outline_size", 3)
    boss_box.add_child(boss_name)
    boss_bar = _make_bar(Color(0.62, 0.38, 0.95), func() -> float:
        return float(boss.hp) / boss.max_hp if is_instance_valid(boss) else 0.0)
    boss_bar.custom_minimum_size = Vector2(220, 7)
    boss_box.add_child(boss_bar)
    boss_box.hide()


## Chefe vivo por perto (na região ativa) → mostra a barra.
func _update_boss_bar() -> void:
    if boss_box == null:
        return
    var player := get_tree().get_first_node_in_group("player") as Node2D
    var found: Enemy = null
    if player:
        for n in get_tree().get_nodes_in_group("enemy"):
            var e := n as Enemy
            if e and e.info.get("ai", "") == "boss" and not e.is_dead() and e.is_visible_in_tree() \
                    and e.global_position.distance_to(player.global_position) < 300.0:
                found = e
                break
    boss = found
    boss_box.visible = found != null
    if found:
        boss_name.text = String(found.info.name)
        boss_bar.queue_redraw()


func _make_bar(color: Color, value: Callable) -> Control:
    var c := Control.new()
    c.custom_minimum_size = Vector2(100, 5)
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    c.draw.connect(func() -> void:
        c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.1, 0.08, 0.07, 0.85))
        c.draw_rect(Rect2(Vector2.ZERO, Vector2(c.size.x * clampf(value.call(), 0.0, 1.0), c.size.y)), color)
        c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.72, 0.47, 0.22), false, 1.0))
    return c


# --- missão atual (canto esquerdo) -----------------------------------------

var quest_label: Label
var buff_label: Label


func _build_tracker() -> void:
    quest_label = Label.new()
    quest_label.position = Vector2(8, 78)
    quest_label.size = Vector2(190, 40)
    quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    quest_label.add_theme_font_size_override("font_size", 8)
    quest_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
    quest_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    quest_label.add_theme_constant_override("outline_size", 3)
    quest_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Root.add_child(quest_label)
    for sig in [Quests.quest_started, Quests.quest_updated, Quests.quest_completed]:
        sig.connect(func(_id: String) -> void: update_tracker())
    buff_label = Label.new()
    buff_label.position = Vector2(8, 120)
    buff_label.add_theme_font_size_override("font_size", 8)
    buff_label.add_theme_color_override("font_color", Color(0.7, 0.95, 0.7))
    buff_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
    buff_label.add_theme_constant_override("outline_size", 3)
    buff_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Root.add_child(buff_label)
    GameState.buff_changed.connect(func(_b: StringName) -> void: update_tracker())
    update_tracker()


## Mostra a etapa atual da história principal (ou da primeira secundária).
func update_tracker() -> void:
    var text := ""
    for id in Quests.order:
        if Quests.is_active(id):
            text = "★ " + String(Quests.step(id).get("text", ""))
            if Quests.defs[id].get("main", false):
                break
    quest_label.text = text
    buff_label.text = ("◆ " + GameState.BUFF_NAMES[GameState.buff]) if GameState.buff != &"" else ""


# --- opções e volta ao menu ----------------------------------------------------

const TITLE_SCENE := "res://scenes/title/title.tscn"

var options_panel: OptionsPanel
var options_button: Button
var menu_button: Button


func _build_menu_extras() -> void:
    var buttons: Control = $Root/PauseMenu/Panel/Buttons
    options_button = Button.new()
    options_button.name = "Options"
    options_button.text = "Opções"
    options_button.pressed.connect(func() -> void:
        pause_menu.hide()
        options_panel.open())
    buttons.add_child(options_button)
    buttons.move_child(options_button, quit_button.get_index())
    menu_button = Button.new()
    menu_button.name = "TitleMenu"
    menu_button.text = "Salvar e ir ao menu"
    menu_button.pressed.connect(go_to_title)
    buttons.add_child(menu_button)
    buttons.move_child(menu_button, quit_button.get_index())
    for b in [options_button, menu_button]:
        b.add_theme_font_size_override("font_size", save_button.get_theme_font_size("font_size"))
    options_panel = OptionsPanel.new()
    $Root.add_child(options_panel)
    options_panel.closed.connect(func() -> void: pause_menu.show())
    Settings.changed.connect(_apply_settings)
    _apply_settings()


func _apply_settings() -> void:
    if quest_label:
        quest_label.visible = Settings.show_quest_hint


func go_to_title() -> void:
    SaveManager.save_game()
    get_tree().paused = false
    get_tree().change_scene_to_file(TITLE_SCENE)
