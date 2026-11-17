class_name Player
extends CharacterBody2D
## Jogador: movimento em 8 direções, animação por direção e interação.
##
## Estados ficam num enum simples por enquanto. Quando entrarem esquiva e
## ataque (Fase 5/6), a máquina de estados sai para scripts/player/states/.

signal facing_changed(direction_index: int)

enum State { IDLE, WALK }

## Ordem das linhas no spritesheet: S, SE, E, NE, N, NW, W, SW.
const DIRECTIONS: Array[Vector2] = [
    Vector2(0, 1), Vector2(0.7071, 0.7071), Vector2(1, 0), Vector2(0.7071, -0.7071),
    Vector2(0, -1), Vector2(-0.7071, -0.7071), Vector2(-1, 0), Vector2(-0.7071, 0.7071),
]
const FRAMES_PER_DIRECTION := 4

@export_group("Movimento")
@export var max_speed: float = 80.0
@export var acceleration: float = 900.0
@export var friction: float = 1200.0
@export_group("Animação")
@export var walk_fps: float = 8.0
@export_group("Interação")
## Distância, em pixels, do centro da área de interação até os pés do jogador.
@export var interact_reach: float = 12.0

var state: State = State.IDLE
var facing_index: int = 0
## Desliga o controle (diálogos, cutscenes, menus).
var input_enabled: bool = true

var _anim_time: float = 0.0
var _current_target: Interactable = null

@onready var sprite: Sprite2D = $Sprite
@onready var interaction_area: Area2D = $InteractionArea
@onready var camera: Camera2D = $Camera


func _ready() -> void:
    _update_interaction_area()
    _update_sprite_frame()


func _physics_process(delta: float) -> void:
    var input_dir := get_move_input()
    _apply_movement(input_dir, delta)
    move_and_slide()
    _update_state(input_dir, delta)
    _refresh_interaction_target()


func _unhandled_input(event: InputEvent) -> void:
    if input_enabled and event.is_action_pressed("interact"):
        if try_interact():
            get_viewport().set_input_as_handled()


func get_move_input() -> Vector2:
    if not input_enabled:
        return Vector2.ZERO
    # get_vector já normaliza: andar na diagonal não fica mais rápido.
    return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Converte um vetor no índice de direção (0..7) usado pelo spritesheet.
static func direction_to_index(dir: Vector2) -> int:
    var degrees := rad_to_deg(dir.angle())  # leste = 0°, sul = 90°
    return posmod(int(round((90.0 - degrees) / 45.0)), 8)


## Interage com o alvo mais próximo. Retorna true se houve interação.
func try_interact() -> bool:
    _refresh_interaction_target()
    if _current_target == null:
        return false
    _current_target.interact(self)
    return true


func get_interaction_target() -> Interactable:
    return _current_target


func set_camera_limits(world_rect: Rect2) -> void:
    camera.limit_left = int(world_rect.position.x)
    camera.limit_top = int(world_rect.position.y)
    camera.limit_right = int(world_rect.end.x)
    camera.limit_bottom = int(world_rect.end.y)
    camera.reset_smoothing()


func face(direction_index: int) -> void:
    direction_index = posmod(direction_index, 8)
    if direction_index == facing_index:
        return
    facing_index = direction_index
    _update_interaction_area()
    _update_sprite_frame()
    facing_changed.emit(facing_index)


# --- interno -------------------------------------------------------------

func _apply_movement(input_dir: Vector2, delta: float) -> void:
    if input_dir != Vector2.ZERO:
        velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
    else:
        velocity = velocity.move_toward(Vector2.ZERO, friction * delta)


func _update_state(input_dir: Vector2, delta: float) -> void:
    if input_dir != Vector2.ZERO:
        face(direction_to_index(input_dir))
    var moving := input_dir != Vector2.ZERO and velocity.length() > 5.0
    var new_state := State.WALK if moving else State.IDLE
    if new_state != state:
        state = new_state
        _anim_time = 0.0
    if state == State.WALK:
        _anim_time += delta
    _update_sprite_frame()


func _update_sprite_frame() -> void:
    var step := 0
    if state == State.WALK:
        step = int(_anim_time * walk_fps) % FRAMES_PER_DIRECTION
    sprite.frame = facing_index * FRAMES_PER_DIRECTION + step


func _update_interaction_area() -> void:
    # A área fica à frente do jogador, na altura do tronco.
    interaction_area.position = DIRECTIONS[facing_index] * interact_reach + Vector2(0, -4)


func _refresh_interaction_target() -> void:
    var best: Interactable = null
    var best_dist := INF
    for area in interaction_area.get_overlapping_areas():
        var candidate := area as Interactable
        if candidate == null or not candidate.enabled:
            continue
        var dist := candidate.global_position.distance_squared_to(interaction_area.global_position)
        if dist < best_dist:
            best_dist = dist
            best = candidate
    if best != _current_target:
        _current_target = best
        EventBus.interaction_prompt_changed.emit(best.get_prompt() if best else "")
    elif best != null and best.prompt_dirty:
        best.prompt_dirty = false
        EventBus.interaction_prompt_changed.emit(best.get_prompt())
