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
@onready var bag_button: TouchScreenButton = $Bag
@onready var dodge_button: TouchScreenButton = $Dodge
@onready var journal_button: TouchScreenButton = $Journal
@onready var attack_button: TouchScreenButton = $Attack
@onready var eat_button: TouchScreenButton = $Eat
@onready var zoom_in_button: TouchScreenButton = $ZoomIn
@onready var zoom_out_button: TouchScreenButton = $ZoomOut
@onready var map_button: TouchScreenButton = $Map
@onready var build_button: TouchScreenButton = $Build

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


## Pinça com dois dedos no meio da tela = zoom. Toques que começam no
## analógico (canto esquerdo de baixo) ou nos botões (direito de baixo) ficam de fora.
var _pinch_touches := {}   # índice -> posição
var _pinch_start := 0.0
var _pinch_zoom := 1.0


func _pinch_zone(pos: Vector2) -> bool:
    var size := get_viewport().get_visible_rect().size
    var bottom := pos.y > size.y * 0.55
    return not (bottom and (pos.x < size.x * 0.4 or pos.x > size.x - 150.0)) and pos.y > 40.0


func _handle_pinch(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and _pinch_zone(event.position):
            _pinch_touches[event.index] = event.position
        else:
            _pinch_touches.erase(event.index)
        _pinch_start = 0.0
        if _pinch_touches.size() == 2:
            var p: Array = _pinch_touches.values()
            _pinch_start = (p[0] as Vector2).distance_to(p[1])
            _pinch_zoom = Settings.camera_zoom
    elif event is InputEventScreenDrag and _pinch_touches.has(event.index):
        _pinch_touches[event.index] = event.position
        if _pinch_touches.size() == 2 and _pinch_start > 20.0:
            var p: Array = _pinch_touches.values()
            var ratio := (p[0] as Vector2).distance_to(p[1]) / _pinch_start
            Settings.set_camera_zoom(_pinch_zoom * ratio, false)


func _input(event: InputEvent) -> void:
    _handle_pinch(event)
    if event is InputEventScreenTouch and not touch_mode:
        set_touch_mode(true)
    elif touch_mode and event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton):
        set_touch_mode(false)


func set_touch_mode(enabled: bool) -> void:
    touch_mode = enabled
    visible = enabled
    # primeira vez no celular e nunca mexeu no zoom: chega mais perto do personagem
    if enabled and not Settings.zoom_touched and Settings.camera_zoom < 1.75:
        Settings.camera_zoom = 1.75
        Settings.apply()
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
    journal_button.position = Vector2(size.x - 128, 6)
    attack_button.position = Vector2(size.x - 122, size.y - 96)
    eat_button.position = Vector2(size.x - 38, size.y - 116)
    zoom_in_button.position = Vector2(size.x - 160, 6)
    zoom_out_button.position = Vector2(size.x - 192, 6)
    map_button.position = Vector2(size.x - 224, 6)
    build_button.position = Vector2(size.x - 256, 6)
    dodge_button.position = Vector2(size.x - 110, size.y - 46)
