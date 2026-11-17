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
var _current_prompt: String = ""
var _use_cooldown: float = 0.0
## Botões segurados. Controlados por eventos (não por Input.is_action_pressed)
## para que um clique na interface não acione nada no mundo.
var _use_held: bool = false
var _interact_held: bool = false

## Ação que o E faria agora: {"kind", "prompt", "priority", "provider"}.
var _action: Dictionary = {}

enum ActionKind { NONE, CELL, ITEM, INTERACTABLE }

## Prioridade quando várias coisas são possíveis ao mesmo tempo:
## colher (30) > ação especial do item, ex. encher regador (20) >
## objeto à frente, ex. porta/baú (10) > ação comum do item, ex. capinar (5).
const PRIORITY_CELL := 30
const PRIORITY_INTERACTABLE := 10

## Intervalo entre repetições ao segurar o botão (capinar/regar uma fileira).
const USE_COOLDOWN := 0.22

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
    _use_cooldown = maxf(0.0, _use_cooldown - delta)
    if not input_enabled or _use_cooldown > 0.0:
        return
    # Segurar repete a ação andando (capinar/regar/plantar/colher uma fileira).
    # Objetos (porta, baú) não repetem.
    if _interact_held and _action.get("kind") in [ActionKind.ITEM, ActionKind.CELL]:
        try_interact()
    elif _use_held:
        use_selected_item()


func _notification(what: int) -> void:
    if what == NOTIFICATION_PAUSED:
        _use_held = false
        _interact_held = false


func _input(event: InputEvent) -> void:
    # Soltar o botão sempre conta, mesmo que a interface tenha consumido o evento.
    if event.is_action_released("use_item"):
        _use_held = false
    if event.is_action_released("interact"):
        _interact_held = false


func _unhandled_input(event: InputEvent) -> void:
    if not input_enabled:
        return
    if event.is_action_pressed("use_item"):
        # No celular cada toque vira também um clique "emulado"; sem este filtro,
        # tocar em qualquer botão usaria a ferramenta. No toque, usar = botão próprio.
        if event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION:
            return
        _use_held = true
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("interact"):
        _interact_held = true
        if try_interact():
            get_viewport().set_input_as_handled()
    elif event.is_action_pressed("hotbar_next"):
        GameState.select_slot(GameState.selected_slot + 1)
    elif event.is_action_pressed("hotbar_prev"):
        GameState.select_slot(GameState.selected_slot - 1)
    else:
        for i in GameState.HOTBAR_SIZE:
            if event.is_action_pressed("tool_%d" % (i + 1)):
                GameState.select_slot(i)
                get_viewport().set_input_as_handled()
                return


func get_move_input() -> Vector2:
    if not input_enabled:
        return Vector2.ZERO
    # get_vector já normaliza: andar na diagonal não fica mais rápido.
    return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Converte um vetor no índice de direção (0..7) usado pelo spritesheet.
static func direction_to_index(dir: Vector2) -> int:
    var degrees := rad_to_deg(dir.angle())  # leste = 0°, sul = 90°
    return posmod(int(round((90.0 - degrees) / 45.0)), 8)


## Ponto (no mundo) logo à frente dos pés: a célula onde ferramentas agem.
func get_target_position() -> Vector2:
    return global_position + Vector2(0, -3) + DIRECTIONS[facing_index] * 13.0


## Botão de interação contextual (E / botão verde / A): faz a ação de maior
## prioridade possível à frente — colher, encher regador, abrir/usar objeto,
## capinar, regar, plantar. Retorna true se algo aconteceu.
func try_interact() -> bool:
    _refresh_interaction_target()
    _use_cooldown = USE_COOLDOWN
    match _action.get("kind", ActionKind.NONE):
        ActionKind.CELL:
            return _action.provider.interact_cell(get_target_position(), self)
        ActionKind.ITEM:
            return _action.provider.use_item(GameState.get_selected_item(), get_target_position(), self)
        ActionKind.INTERACTABLE:
            _action.provider.interact(self)
            _interact_held = false  # não repete abrir baú/dormir
            return true
    return false


## Usa só o item selecionado na célula à frente (clique / X), sem objetos.
func use_selected_item() -> bool:
    _use_cooldown = USE_COOLDOWN
    var item := GameState.get_selected_item()
    if item == null:
        return false
    for target in get_tree().get_nodes_in_group("item_target"):
        if target.use_item(item, get_target_position(), self):
            return true
    return false


## Texto da ação atual do botão de interação ("" = nada).
func get_action_prompt() -> String:
    return _action.get("prompt", "")


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
    _current_target = best
    _action = _resolve_action(best)
    var prompt: String = _action.get("prompt", "")
    if prompt != _current_prompt:
        _current_prompt = prompt
        EventBus.interaction_prompt_changed.emit(prompt)


func _resolve_action(interactable: Interactable) -> Dictionary:
    var best := {"kind": ActionKind.NONE, "prompt": "", "priority": -1, "provider": null}
    var pos := get_target_position()
    for provider in get_tree().get_nodes_in_group("cell_interaction"):
        var p: String = provider.get_cell_prompt(pos)
        if p != "" and PRIORITY_CELL > best.priority:
            best = {"kind": ActionKind.CELL, "prompt": p, "priority": PRIORITY_CELL, "provider": provider}
    var item := GameState.get_selected_item()
    if item:
        for target in get_tree().get_nodes_in_group("item_target"):
            var a: Dictionary = target.get_item_action(item, pos, self)
            if a.get("prompt", "") != "" and int(a.priority) > best.priority:
                best = {"kind": ActionKind.ITEM, "prompt": a.prompt, "priority": int(a.priority), "provider": target}
    if interactable and PRIORITY_INTERACTABLE > best.priority:
        best = {"kind": ActionKind.INTERACTABLE, "prompt": interactable.get_prompt(),
            "priority": PRIORITY_INTERACTABLE, "provider": interactable}
    return best
