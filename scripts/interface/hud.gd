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
    # Checagem barata a cada quadro: o sinal de redimensionamento não é
    # confiável em todos os navegadores quando o celular gira.
    _update_rotate_hint()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("menu"):
        set_paused(not get_tree().paused)
        get_viewport().set_input_as_handled()


func set_paused(paused: bool) -> void:
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


func _make_bar(color: Color, value: Callable) -> Control:
    var c := Control.new()
    c.custom_minimum_size = Vector2(100, 5)
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    c.draw.connect(func() -> void:
        c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.1, 0.08, 0.07, 0.85))
        c.draw_rect(Rect2(Vector2.ZERO, Vector2(c.size.x * clampf(value.call(), 0.0, 1.0), c.size.y)), color)
        c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.72, 0.47, 0.22), false, 1.0))
    return c
