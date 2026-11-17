extends CanvasLayer
## HUD da Fase 1: dica de interação, mensagens curtas, contador de pequi e
## menu de pausa. Só escuta o EventBus; não conhece jogador nem objetos.

@onready var prompt_label: Label = $Root/Prompt
@onready var message_label: Label = $Root/Message
@onready var message_timer: Timer = $MessageTimer
@onready var item_box: Control = $Root/ItemBox
@onready var item_count: Label = $Root/ItemBox/Row/Count
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
    item_box.hide()
    pause_menu.hide()
    EventBus.interaction_prompt_changed.connect(_on_prompt_changed)
    EventBus.message_requested.connect(_on_message_requested)
    EventBus.item_collected.connect(_on_item_collected)
    message_timer.timeout.connect(_fade_message)
    resume_button.pressed.connect(set_paused.bind(false))
    quit_button.pressed.connect(func() -> void: get_tree().quit())
    # No navegador não existe "sair do jogo": é só fechar a aba.
    quit_button.visible = not OS.has_feature("web")
    EventBus.touch_mode_changed.connect(_on_touch_mode_changed)
    _update_rotate_hint()


func _process(_delta: float) -> void:
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
    if paused:
        resume_button.grab_focus()
    EventBus.pause_changed.emit(paused)


func _on_prompt_changed(text: String) -> void:
    _prompt_text = text
    prompt_label.visible = text != ""
    # No celular a dica aponta para o botão verde, não para a tecla E.
    prompt_label.text = (text + "  (toque no botão)") if _touch_mode else ("[E] " + text)


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


func _on_item_collected(item_id: StringName, _amount: int, total: int) -> void:
    if item_id == &"pequi":
        item_box.show()
        item_count.text = "x%d" % total
