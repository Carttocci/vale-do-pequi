class_name VirtualJoystick
extends Control
## Analógico virtual flutuante para telas de toque.
##
## Encoste o dedo em qualquer ponto da área (lado esquerdo da tela) e o
## analógico aparece ali. Ele não move o jogador direto: aperta as mesmas
## ações do teclado/controle (move_left, move_right...) com intensidade
## proporcional. Assim o Player não sabe que o toque existe.

## Raio máximo da alavanca, em pixels da tela do jogo (640x360).
@export var radius: float = 24.0

var output := Vector2.ZERO

var _touch_index := -1
var _center := Vector2.ZERO
var _pressed_actions := {}

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Knob


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _reset_visual()


func _input(event: InputEvent) -> void:
    # Sem checar visibilidade de propósito: o primeiro toque é o que liga o
    # modo celular, e o analógico precisa pegar esse mesmo toque.
    # Também não marca o evento como tratado, para a TouchControls enxergá-lo.
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed and _touch_index == -1 and get_global_rect().has_point(touch.position):
            _touch_index = touch.index
            _center = touch.position
            _update(touch.position)
        elif not touch.pressed and touch.index == _touch_index:
            release()
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == _touch_index:
            _update(drag.position)


func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        release()


func is_active() -> bool:
    return _touch_index != -1


## Solta o analógico e todas as ações que ele estava segurando.
func release() -> void:
    _touch_index = -1
    output = Vector2.ZERO
    _apply_actions()
    if is_inside_tree():
        _reset_visual()


func _update(touch_pos: Vector2) -> void:
    var offset := (touch_pos - _center).limit_length(radius)
    output = offset / radius
    base.position = _center - global_position - base.size / 2.0
    knob.position = _center + offset - global_position - knob.size / 2.0
    base.modulate.a = 1.0
    knob.modulate.a = 1.0
    _apply_actions()


func _apply_actions() -> void:
    _set_action("move_right", maxf(output.x, 0.0))
    _set_action("move_left", maxf(-output.x, 0.0))
    _set_action("move_down", maxf(output.y, 0.0))
    _set_action("move_up", maxf(-output.y, 0.0))


func _set_action(action: StringName, strength: float) -> void:
    if strength > 0.0:
        Input.action_press(action, strength)
        _pressed_actions[action] = true
    elif _pressed_actions.has(action):
        # Só solta o que o próprio analógico apertou (não briga com o teclado).
        Input.action_release(action)
        _pressed_actions.erase(action)


func _reset_visual() -> void:
    if base == null:
        return
    # Em repouso, fica discreto no canto inferior esquerdo.
    var rest := Vector2(56, size.y - 56)
    base.position = rest - base.size / 2.0
    knob.position = rest - knob.size / 2.0
    base.modulate.a = 0.5
    knob.modulate.a = 0.5
