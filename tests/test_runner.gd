extends Node
## Testes de integração da Fase 1.
##
## Rodar pelo terminal (sem janela):
##   godot --headless --path . res://tests/test_runner.tscn
## Ou no editor: abra tests/test_runner.tscn e aperte F6.
## Código de saída 0 = tudo passou; 1 = alguma falha.

const MAIN_SCENE: PackedScene = preload("res://scenes/main/main.tscn")

var _passed := 0
var _failed := 0
var _main: Node
var _player: Player
var _messages: Array[String] = []
var _prompts: Array[String] = []


func _ready() -> void:
    EventBus.message_requested.connect(func(t: String, _d: float) -> void: _messages.append(t))
    EventBus.interaction_prompt_changed.connect(func(t: String) -> void: _prompts.append(t))
    await _run_all()
    print("\n==== %d passaram, %d falharam ====" % [_passed, _failed])
    get_tree().quit(0 if _failed == 0 else 1)


func _run_all() -> void:
    _test_input_map()
    _test_direction_mapping()
    await _setup_main()
    await _test_scene_structure()
    await _test_movement_and_stop()
    await _test_diagonal_speed()
    await _test_eight_direction_facing()
    await _test_house_collision()
    await _test_water_collision()
    await _test_world_bounds()
    await _test_inspect_well()
    await _test_collect_pequi()
    await _test_pause()
    await _test_touch_controls()


# --- utilidades ----------------------------------------------------------

func check(cond: bool, label: String) -> void:
    if cond:
        _passed += 1
        print("  ok   ", label)
    else:
        _failed += 1
        printerr("  FALHOU ", label)


func frames(n: int) -> void:
    for i in n:
        await get_tree().physics_frame


func hold(actions: Array, n: int) -> void:
    for a: String in actions:
        Input.action_press(a)
    await frames(n)
    for a: String in actions:
        Input.action_release(a)


func place_player(pos: Vector2) -> void:
    _player.global_position = pos
    _player.velocity = Vector2.ZERO
    await frames(2)


func node(path: String) -> Node2D:
    return _main.get_node(path) as Node2D


# --- testes --------------------------------------------------------------

func _test_input_map() -> void:
    print("[controles]")
    for action in ["move_left", "move_right", "move_up", "move_down", "interact", "attack",
            "dodge", "inventory", "map", "journal", "menu", "tool_1", "tool_9"]:
        check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(),
            "ação '%s' configurada" % action)
    var has_pad := false
    for ev in InputMap.action_get_events("move_left"):
        has_pad = has_pad or ev is InputEventJoypadMotion
    check(has_pad, "movimento aceita analógico do controle")


func _test_direction_mapping() -> void:
    print("[direções]")
    var expected := {Vector2.DOWN: 0, Vector2(1, 1): 1, Vector2.RIGHT: 2, Vector2(1, -1): 3,
        Vector2.UP: 4, Vector2(-1, -1): 5, Vector2.LEFT: 6, Vector2(-1, 1): 7}
    for v: Vector2 in expected:
        check(Player.direction_to_index(v) == expected[v], "vetor %s -> índice %d" % [v, expected[v]])


func _setup_main() -> void:
    _main = MAIN_SCENE.instantiate()
    add_child(_main)
    await frames(3)
    _player = _main.get("player") as Player


func _test_scene_structure() -> void:
    print("[cena]")
    check(_player != null, "jogador foi criado")
    check(_player.get_parent() == node("Farm/Entities"), "jogador está na camada com y-sort")
    check(node("Farm/Entities").y_sort_enabled, "y-sort ativo nas entidades")
    var ground := _main.get_node("Farm/Ground") as FarmGround
    check(ground.map_size == Vector2i(60, 34), "mapa ASCII carregado (60x34)")
    check(ground.get_used_cells().size() == 60 * 34, "todas as células do chão preenchidas")
    check(_player.camera.is_current(), "câmera do jogador está ativa")
    check(_player.camera.limit_right == 960 and _player.camera.limit_bottom == 544, "limites da câmera = tamanho do mapa")
    check(get_tree().get_nodes_in_group("player").size() == 1, "existe exatamente um jogador")


func _test_movement_and_stop() -> void:
    print("[movimento]")
    await place_player(Vector2(464, 160))
    var start := _player.global_position
    await hold(["move_right"], 30)
    check(_player.global_position.x > start.x + 20, "anda para a direita")
    check(_player.state == Player.State.WALK, "estado WALK ao andar")
    await frames(20)
    check(_player.velocity.length() < 1.0, "para ao soltar a tecla (atrito)")
    check(_player.state == Player.State.IDLE, "volta para IDLE")
    start = _player.global_position
    await hold(["move_up"], 20)
    check(_player.global_position.y < start.y - 10, "anda para cima")


func _test_diagonal_speed() -> void:
    await place_player(Vector2(600, 300))
    Input.action_press("move_right")
    Input.action_press("move_down")
    await frames(30)
    var speed := _player.velocity.length()
    Input.action_release("move_right")
    Input.action_release("move_down")
    check(absf(speed - _player.max_speed) < 1.0, "diagonal não é mais rápida (%.1f px/s)" % speed)
    await frames(20)


func _test_eight_direction_facing() -> void:
    print("[8 direções]")
    var combos := [["move_down"], ["move_down", "move_right"], ["move_right"], ["move_up", "move_right"],
        ["move_up"], ["move_up", "move_left"], ["move_left"], ["move_down", "move_left"]]
    for i in combos.size():
        await place_player(Vector2(600, 300))
        await hold(combos[i], 6)
        check(_player.facing_index == i, "olha para a direção %d" % i)
        check(_player.sprite.frame / Player.FRAMES_PER_DIRECTION == i, "linha do sprite = direção %d" % i)
    await frames(15)


func _test_house_collision() -> void:
    print("[colisões]")
    var house := node("Farm/Entities/CasaPrincipal")
    # Vem de baixo, à esquerda da porta, e empurra para cima contra a parede.
    await place_player(house.global_position + Vector2(-25, 20))
    await hold(["move_up"], 60)
    check(_player.global_position.y > house.global_position.y - 2, "não atravessa a parede da casa")
    await place_player(house.global_position + Vector2(-80, -14))
    await hold(["move_right"], 60)
    check(_player.global_position.x < house.global_position.x - 40, "não atravessa a lateral da casa")


func _test_water_collision() -> void:
    var ground := _main.get_node("Farm/Ground") as FarmGround
    # Lagoa começa na linha 24 (y=384). Jogador acima, empurrando para baixo.
    await place_player(Vector2(140, 360))
    await hold(["move_down"], 60)
    check(not ground.is_solid_at(_player.global_position - Vector2(0, 1)), "não entra na água")
    check(_player.global_position.y < 385.0, "para na margem da lagoa")
    var tree := node("Farm/Entities/Pequizeiro1")
    await place_player(tree.global_position + Vector2(0, 20))
    await hold(["move_up"], 40)
    check(_player.global_position.y > tree.global_position.y, "não atravessa o tronco do pequizeiro")
    await place_player(Vector2(200, 300))
    await hold(["move_up"], 50)
    check(_player.global_position.y > 284, "cerca da roça bloqueia passagem")


func _test_world_bounds() -> void:
    await place_player(Vector2(40, 200))
    await hold(["move_left"], 60)
    check(_player.global_position.x >= 0.0, "não sai pela borda oeste do mapa")
    await place_player(Vector2(900, 520))
    await hold(["move_down"], 60)
    check(_player.global_position.y <= 544.0, "não sai pela borda sul do mapa")


func _test_inspect_well() -> void:
    print("[interação]")
    var well := node("Farm/Entities/Poco")
    await place_player(well.global_position + Vector2(0, 16))
    await hold(["move_up"], 3)
    await frames(3)
    check(_player.get_interaction_target() != null, "detecta o poço à frente")
    check(_prompts.size() > 0 and _prompts[-1] == "Olhar o poço", "HUD recebe a dica 'Olhar o poço'")
    _messages.clear()
    check(_player.try_interact(), "interação acontece")
    check(_messages.size() == 1 and _messages[0].contains("Água"), "poço responde com mensagem")
    await place_player(Vector2(600, 300))
    await frames(3)
    check(_player.get_interaction_target() == null and _prompts[-1] == "", "dica some longe dos objetos")


func _test_collect_pequi() -> void:
    var tree := node("Farm/Entities/Pequizeiro2") as Pequizeiro
    GameState.reset()
    await place_player(tree.global_position + Vector2(0, 18))
    await hold(["move_up"], 3)
    await frames(3)
    check(_player.get_interaction_target() == tree.interactable, "mira o pequizeiro")
    check(_prompts[-1] == "Catar pequi", "dica 'Catar pequi'")
    _player.try_interact()
    check(GameState.get_item_count(&"pequi") == 3, "catou 3 pequis")
    check(tree.get_available() == 0, "pequis somem do chão")
    await frames(2)
    check(_prompts[-1] == "Pé de pequi", "dica atualiza depois de catar")
    _player.try_interact()
    check(GameState.get_item_count(&"pequi") == 3, "não duplica pequi antes de cair de novo")
    tree.regrow_timer.stop()
    tree.regrow_timer.timeout.emit()
    check(tree.get_available() == 3, "pequi volta a cair depois do tempo")


func _test_pause() -> void:
    print("[pausa]")
    var hud := _main.get_node("HUD")
    hud.set_paused(true)
    await place_player(Vector2(600, 300))
    var pos := _player.global_position
    Input.action_press("move_right")
    await get_tree().create_timer(0.3, true, false, true).timeout
    Input.action_release("move_right")
    check(_player.global_position == pos, "jogador congela com o jogo pausado")
    hud.set_paused(false)
    check(not get_tree().paused, "jogo retoma")


func touch(index: int, pos: Vector2, pressed: bool) -> void:
    var ev := InputEventScreenTouch.new()
    ev.index = index
    ev.position = pos
    ev.pressed = pressed
    Input.parse_input_event(ev)
    Input.flush_buffered_events()


func drag(index: int, pos: Vector2) -> void:
    var ev := InputEventScreenDrag.new()
    ev.index = index
    ev.position = pos
    Input.parse_input_event(ev)
    Input.flush_buffered_events()


func _test_touch_controls() -> void:
    print("[toque / celular]")
    var tc := _main.get_node("TouchControls") as TouchControls
    tc.set_touch_mode(false)
    check(not tc.visible, "controles de toque escondidos no desktop")
    await place_player(Vector2(600, 300))
    # Posições relativas à base da tela (a altura varia com aspect "expand").
    var by := get_viewport().get_visible_rect().size.y - 60.0
    touch(0, Vector2(80, by), true)
    await frames(1)
    check(tc.visible and tc.touch_mode, "aparecem ao tocar na tela")
    var start := _player.global_position
    drag(0, Vector2(130, by))
    await frames(30)
    check(_player.global_position.x > start.x + 20, "analógico virtual move o jogador")
    check(_player.facing_index == 2, "analógico vira o jogador para a direita")
    drag(0, Vector2(80, by + 40))
    await frames(10)
    check(_player.facing_index == 0, "analógico vira o jogador para baixo")
    touch(0, Vector2(80, by + 40), false)
    await frames(25)
    check(_player.velocity.length() < 1.0, "soltar o dedo para o jogador")
    check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_down"), "ações liberadas ao soltar")

    # Botão de interagir (toque com outro dedo, como no celular)
    var well := node("Farm/Entities/Poco")
    await place_player(well.global_position + Vector2(0, 16))
    await hold(["move_up"], 3)
    await frames(3)
    _messages.clear()
    var btn := tc.get_node("Interact") as TouchScreenButton
    var center := btn.position + btn.texture_normal.get_size() / 2.0
    touch(1, center, true)
    await frames(2)
    touch(1, center, false)
    await frames(2)
    check(_messages.size() == 1 and _messages[0].contains("balde"), "botão de toque interage com o poço")

    # Botão de pausa
    var pbtn := tc.get_node("Pause") as TouchScreenButton
    var pc := pbtn.position + pbtn.texture_normal.get_size() / 2.0
    touch(2, pc, true)
    await frames(2)
    touch(2, pc, false)
    await frames(2)
    check(get_tree().paused, "botão de toque pausa o jogo")
    touch(2, pc, true)
    await frames(2)
    touch(2, pc, false)
    await frames(2)
    check(not get_tree().paused, "botão de toque retoma o jogo")

    var key := InputEventKey.new()
    key.physical_keycode = KEY_W
    key.pressed = true
    Input.parse_input_event(key)
    Input.flush_buffered_events()
    key = key.duplicate()
    key.pressed = false
    Input.parse_input_event(key)
    Input.flush_buffered_events()
    await frames(1)
    check(not tc.visible, "somem quando o teclado é usado")
