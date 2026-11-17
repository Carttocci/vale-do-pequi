class_name TouchControls
extends CanvasLayer
## Camada de controles de toque (celular/tablet).
##
## Aparece sozinha quando o aparelho tem tela de toque ou quando alguém
## encosta na tela; some quando o jogador usa teclado ou controle.
## Os botões usam TouchScreenButton com `action`, então disparam as mesmas
## ações do mapa de controles (interact, menu, toggle_fullscreen).

var touch_mode: bool = false

@onready var joystick: VirtualJoystick = $Joystick
@onready var interact_button: TouchScreenButton = $Interact
@onready var fullscreen_button: TouchScreenButton = $Fullscreen
@onready var pause_button: TouchScreenButton = $Pause
@onready var use_button: TouchScreenButton = $Use
@onready var bag_button: TouchScreenButton = $Bag

var _last_size := Vector2.ZERO


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    EventBus.interaction_prompt_changed.connect(_on_prompt_changed)
    _on_prompt_changed("")
    # iPhone não tem API de tela cheia no navegador; lá o botão não faria nada.
    fullscreen_button.visible = not OS.has_feature("web_ios")
    set_touch_mode(DisplayServer.is_touchscreen_available())
    _layout()


func _process(_delta: float) -> void:
    _layout()


func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and not touch_mode:
        set_touch_mode(true)
    elif touch_mode and event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton):
        set_touch_mode(false)


func set_touch_mode(enabled: bool) -> void:
    touch_mode = enabled
    visible = enabled
    if not enabled:
        joystick.release()
    EventBus.touch_mode_changed.emit(enabled)


func _on_prompt_changed(text: String) -> void:
    # Botão de interagir acende quando há algo à frente do jogador.
    interact_button.modulate = Color(1, 1, 1, 1.0 if text != "" else 0.45)


## Com aspect "expand" a largura da tela do jogo varia (celular 19,5:9 é mais
## largo que 16:9), então os botões se prendem à borda direita/inferior.
func _layout() -> void:
    var size := get_viewport().get_visible_rect().size
    if size == _last_size:
        return
    _last_size = size
    interact_button.position = Vector2(size.x - 70, size.y - 78)
    pause_button.position = Vector2(size.x - 32, 6)
    fullscreen_button.position = Vector2(size.x - 64, 6)
    bag_button.position = Vector2(size.x - 96, 6)
    use_button.position = Vector2(size.x - 116, size.y - 54)
