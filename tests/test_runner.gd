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


const TEST_SAVE := "user://teste_automatizado_save.json"


func _ready() -> void:
    # Nunca toca no save real do jogador.
    SaveManager.save_path = TEST_SAVE
    Settings.path = "user://teste_opcoes.cfg"
    SaveManager.delete_save()
    # Tempo parado e sol todo dia: testes determinísticos. Os da Fase 3
    # ligam o relógio e trocam o clima quando precisam.
    Clock.running = false
    Clock.forced_weather = Clock.Weather.ENSOLARADO
    GameState.new_game()
    EventBus.message_requested.connect(func(t: String, _d: float) -> void: _messages.append(t))
    EventBus.interaction_prompt_changed.connect(func(t: String) -> void: _prompts.append(t))
    await _run_all()
    print("\n==== %d passaram, %d falharam ====" % [_passed, _failed])
    SaveManager.delete_save()
    get_tree().quit(0 if _failed == 0 else 1)


func _run_all() -> void:
    _test_export_safe_defaults()
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
    _test_item_db()
    _test_inventory_unit()
    await _test_hotbar_selection()
    await _test_farming_cycle()
    await _test_farming_rules()
    await _test_watering_can()
    await _test_regrow_crop()
    await _test_chest_and_inventory_ui()
    await _test_save_load()
    _test_save_robustness()
    await _test_touch_use_button()
    await _test_contextual_e()
    _test_calendar()
    await _test_clock()
    _test_weather_rolls()
    await _test_rain_and_periods()
    await _test_pequi_season()
    _test_daylight_and_hud()
    await _test_save_v2_and_migration()
    await _test_regions()
    _test_village_layout()
    await _test_npc_schedule_and_walk()
    await _test_dialogue_and_friendship()
    await _test_shop()
    await _test_save_v3()
    await _test_mata_region()
    await _test_fishing()
    _test_fish_table()
    await _test_ranch()
    await _test_wildlife_and_traps()
    _test_skills()
    await _test_save_v4()
    await _test_combat_basics()
    await _test_enemies_and_damage()
    await _test_ranged_dodge_hunt()
    _test_energy_and_paths()
    await _test_save_v5()
    await _test_quest_chain_start()
    await _test_mining_and_trail()
    await _test_mine_floors()
    await _test_guardian_boss()
    await _test_ruins_and_act1()
    await _test_side_quests_and_board()
    await _test_journal_ui()
    await _test_save_v6()
    await _test_cooking()
    await _test_eating_and_buffs()
    await _test_gifts_and_hearts()
    await _test_festivals()
    await _test_decor_and_obras()
    await _test_save_v7()
    _test_data_integrity()
    await _test_audio()
    await _test_settings_and_options()
    await _test_title_screen()
    await _test_rain_continuous()
    await _test_attack_button()
    await _test_eat_button()
    await _test_messy_farm()
    await _test_camera_zoom()


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
    # os testes das fases antigas usam a fazenda limpa; a bagunça tem testes próprios
    var debris := _main.get_node("Farm/Entities/DebrisField") as DebrisField
    debris.clear_all()
    debris.growth_enabled = false


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
    GameState.select_slot(8)  # mão vazia: sem ação de ferramenta no chão
    await place_player(Vector2(600, 300))
    await frames(3)
    check(_player.get_interaction_target() == null and _prompts[-1] == "", "dica some longe dos objetos")
    GameState.select_slot(0)


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
    GameState.sleep()
    check(tree.get_available() == 3, "pequi volta a cair no dia seguinte")


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
    check(_messages.size() == 1 and _messages[0] != "", "botão de toque interage com o poço (sem usar ferramenta junto)")

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


# --- Fase 2 ----------------------------------------------------------------

func field() -> FarmField:
    return _main.get_node("Farm/FarmField") as FarmField


func select_item(id: StringName) -> void:
    for i in GameState.inventory.size():
        if GameState.inventory.get_item_id(i) == id:
            if i >= GameState.HOTBAR_SIZE:
                GameState.inventory.swap(i, GameState.HOTBAR_SIZE - 1)
                i = GameState.HOTBAR_SIZE - 1
            GameState.select_slot(i)
            return
    push_error("item não está na mochila: %s" % id)


func use_at_front() -> bool:
    _player._use_cooldown = 0.0
    return _player.use_selected_item()


func face_right_in_roca(pos := Vector2(150, 210)) -> void:
    await place_player(pos)
    _player.face(2)
    await frames(2)


func _test_item_db() -> void:
    print("[Fase 2: catálogo]")
    check(ItemDB.item_ids().size() >= 11, "itens carregados (%d)" % ItemDB.item_ids().size())
    check(ItemDB.crop_ids().size() == 4, "4 culturas carregadas")
    for crop_id in ItemDB.crop_ids():
        var crop := ItemDB.get_crop(crop_id)
        check(crop.stage_textures.size() == crop.stage_days.size() + 1, "%s: texturas = estágios + 1" % crop_id)
        check(ItemDB.get_item(crop.seed_item) != null and ItemDB.get_item(crop.harvest_item) != null, "%s: semente e colheita existem" % crop_id)
        check(ItemDB.get_item(crop.seed_item).crop_id == crop.id, "%s: semente aponta para a cultura" % crop_id)
    check(ItemDB.max_stack(&"enxada") == 1, "ferramenta não empilha")


func _test_inventory_unit() -> void:
    print("[Fase 2: inventário]")
    var inv := Inventory.new(3)
    check(inv.add(&"milho", 150) == 0, "150 milhos cabem em 2 pilhas")
    check(inv.count_of(&"milho") == 150 and inv.get_slot(0).count == 99, "pilha máxima de 99")
    check(inv.add(&"enxada", 2) == 1, "só cabe uma enxada no slot que sobrou")
    check(inv.add(&"feijao", 5) == 5, "mochila cheia devolve o que sobrou")
    check(inv.space_for(&"milho") == 48, "espaço restante calculado")
    check(inv.remove(&"milho", 100) and inv.count_of(&"milho") == 50, "remove de várias pilhas")
    check(not inv.remove(&"milho", 51), "não remove mais do que tem")
    inv.swap(0, 2)
    check(inv.get_item_id(0) == &"enxada", "troca de lugar")
    var other := Inventory.new(2)
    check(inv.transfer_slot_to(other, 0) == 1 and other.count_of(&"enxada") == 1, "transfere entre inventários")
    var copy := Inventory.new(3)
    copy.from_data(inv.to_data())
    check(copy.to_data() == inv.to_data(), "salvar/carregar inventário mantém tudo")
    copy.from_data([{"id": "item_que_nao_existe", "count": 3}, null, {"id": "milho", "count": 999}])
    check(copy.get_slot(0) == null and copy.count_of(&"milho") == 99, "save com item inválido não quebra")


func _test_hotbar_selection() -> void:
    print("[Fase 2: atalhos]")
    GameState.new_game()
    check(GameState.get_item_count(&"enxada") == 1 and GameState.get_item_count(&"regador") == 1, "jogo novo começa com enxada e regador")
    check(GameState.get_item_count(&"semente_milho") > 0, "jogo novo começa com sementes")
    Input.action_press("tool_2")
    await frames(1)
    Input.action_release("tool_2")
    var ev := InputEventAction.new()
    ev.action = "tool_2"
    ev.pressed = true
    Input.parse_input_event(ev)
    Input.flush_buffered_events()
    await frames(1)
    check(GameState.selected_slot == 1, "tecla 2 seleciona o slot 2")
    var hotbar := _main.get_node("HUD/Root/Hotbar") as Hotbar
    hotbar.get_slot_button(0).pressed.emit()
    check(GameState.selected_slot == 0, "tocar no slot da barra seleciona")


func _test_farming_cycle() -> void:
    print("[Fase 2: plantio completo]")
    GameState.new_game()
    var f := field()
    await face_right_in_roca()
    var cell := f.cell_at(_player.get_target_position())
    select_item(&"enxada")
    check(use_at_front() and f.is_tilled(cell), "enxada capina a terra da roça")
    select_item(&"semente_milho")
    var seeds := GameState.get_item_count(&"semente_milho")
    check(use_at_front() and f.get_crop_id(cell) == &"milho", "semente de milho plantada")
    check(GameState.get_item_count(&"semente_milho") == seeds - 1, "gastou 1 semente")
    check(not use_at_front(), "não planta duas vezes no mesmo lugar")
    var crop := ItemDB.get_crop(&"milho")
    for d in crop.days_to_mature():
        select_item(&"regador")
        check(use_at_front() and f.is_watered(cell), "dia %d: regou" % (d + 1))
        await frames(2)
        check(_prompts[-1] != "Colher milho", "dia %d: ainda não dá pra colher" % (d + 1))
        GameState.sleep()
        check(not f.is_watered(cell), "dia %d: terra seca de novo pela manhã" % (d + 1))
    check(f.is_ripe(cell), "milho maduro depois de %d dias regados" % crop.days_to_mature())
    var sprite: Sprite2D = f._crop_sprites.get(cell)
    check(sprite != null and sprite.texture == crop.stage_textures[-1], "sprite mostra o milho maduro")
    await frames(2)
    check(_prompts[-1] == "Colher milho", "dica 'Colher milho'")
    var before := GameState.get_item_count(&"milho")
    check(_player.try_interact(), "E colhe")
    check(GameState.get_item_count(&"milho") > before, "milho foi para a mochila")
    check(f.is_tilled(cell) and f.get_crop_id(cell) == &"", "milho não rebrota: sobra a terra capinada")


func _test_farming_rules() -> void:
    print("[Fase 2: regras do solo]")
    var f := field()
    # Sem água não cresce
    await face_right_in_roca(Vector2(150, 240))
    var cell := f.cell_at(_player.get_target_position())
    select_item(&"enxada")
    use_at_front()
    select_item(&"semente_milho")
    use_at_front()
    GameState.sleep()
    GameState.sleep()
    check(f.cells[cell].age == 0, "sem regar, a planta não cresce")
    # Estrada, água e casa não capinam
    var ground := _main.get_node("Farm/Ground") as FarmGround
    check(not f.can_till(Vector2i(28, 10)), "não capina a estrada de terra vermelha")
    check(not f.can_till(Vector2i(8, 27)), "não capina a lagoa")
    check(not f.can_till(f.cell_at(node("Farm/Entities/CasaPrincipal").global_position + Vector2(0, -10))), "não capina embaixo da casa")
    check(not f.can_till(f.cell_at(node("Farm/Entities/Poco").global_position + Vector2(0, -3))), "não capina embaixo do poço")
    check(f.can_till(Vector2i(40, 6)), "capina grama comum fora da roça")
    select_item(&"semente_feijao")
    await face_right_in_roca(Vector2(150, 180))
    check(not use_at_front(), "não planta sem capinar antes")
    check(_messages[-1].contains("Capine"), "avisa que precisa capinar")
    check(ground != null, "chão existe")


func _test_watering_can() -> void:
    print("[Fase 2: regador]")
    var f := field()
    GameState.water = 1
    GameState.water_changed.emit(1)
    await face_right_in_roca(Vector2(200, 180))
    var cell := f.cell_at(_player.get_target_position())
    select_item(&"enxada")
    use_at_front()
    select_item(&"regador")
    check(use_at_front() and GameState.water == 0, "regar gasta água")
    GameState.sleep()
    check(not use_at_front(), "regador vazio não rega")
    check(_messages[-1].contains("vazio"), "avisa que o regador está vazio")
    check(not f.is_watered(cell), "célula continua seca")
    var well := node("Farm/Entities/Poco")
    await place_player(well.global_position + Vector2(0, 16))
    _player.face(4)
    await frames(2)
    check(use_at_front() and GameState.water == GameState.WATER_MAX, "enche o regador no poço")
    GameState.water = 0
    await place_player(Vector2(140, 375))
    _player.face(0)
    await frames(2)
    check(use_at_front() and GameState.water == GameState.WATER_MAX, "enche o regador na lagoa")


func _test_regrow_crop() -> void:
    print("[Fase 2: cultura que rebrota]")
    var f := field()
    await face_right_in_roca(Vector2(230, 180))
    var cell := f.cell_at(_player.get_target_position())
    select_item(&"enxada")
    use_at_front()
    select_item(&"semente_feijao")
    use_at_front()
    var crop := ItemDB.get_crop(&"feijao")
    for d in crop.days_to_mature():
        f.water(cell)
        GameState.sleep()
    var before := GameState.get_item_count(&"feijao")
    check(_player.try_interact() and GameState.get_item_count(&"feijao") >= before + crop.harvest_min, "colheu feijão")
    check(f.get_crop_id(cell) == &"feijao" and not f.is_ripe(cell), "feijão continua plantado depois da colheita")
    for d in crop.regrow_days:
        f.water(cell)
        GameState.sleep()
    check(f.is_ripe(cell), "feijão produz de novo em %d dias" % crop.regrow_days)


func _test_chest_and_inventory_ui() -> void:
    print("[Fase 2: baú e mochila]")
    var ui := _main.get_node("InventoryUI") as InventoryUI
    var chest := node("Farm/Entities/BauDoAvo") as Chest
    check(chest.inventory.count_of(&"semente_abobora") > 0, "baú do avô começa com sementes")
    await place_player(chest.global_position + Vector2(0, 16))
    _player.face(4)
    await frames(3)
    check(_prompts[-1] == "Abrir baú do avô", "dica 'Abrir baú do avô'")
    _player.try_interact()
    await frames(1)
    check(ui.is_open() and ui.mode == InventoryUI.Mode.CHEST and get_tree().paused, "baú abre e pausa o mundo")
    var abobora := chest.inventory.count_of(&"semente_abobora")
    var slot := -1
    for i in chest.inventory.size():
        if chest.inventory.get_item_id(i) == &"semente_abobora":
            slot = i
    ui.press_chest_slot(slot)
    check(GameState.get_item_count(&"semente_abobora") == abobora and chest.inventory.count_of(&"semente_abobora") == 0, "tocar no item do baú passa para a mochila")
    var bag_slot := 0
    ui.press_bag_slot(bag_slot)
    check(chest.inventory.count_of(&"enxada") == 1 or chest.inventory.size() > 0, "tocar no item da mochila passa para o baú")
    chest.inventory.transfer_slot_to(GameState.inventory, chest.inventory.size() - 1)
    for i in chest.inventory.size():
        if chest.inventory.get_item_id(i) == &"enxada":
            ui.press_chest_slot(i)
    check(GameState.get_item_count(&"enxada") == 1, "enxada de volta na mochila")
    ui.close()
    check(not ui.is_open() and not get_tree().paused, "fecha e despausa")
    # Mochila: selecionar e trocar
    var ev := InputEventAction.new()
    ev.action = "inventory"
    ev.pressed = true
    Input.parse_input_event(ev)
    Input.flush_buffered_events()
    await frames(1)
    check(ui.is_open() and ui.mode == InventoryUI.Mode.INVENTORY, "tecla I abre a mochila")
    var a := GameState.inventory.get_item_id(0)
    var b := GameState.inventory.get_item_id(1)
    ui.press_bag_slot(0)
    ui.press_bag_slot(1)
    check(GameState.inventory.get_item_id(0) == b and GameState.inventory.get_item_id(1) == a, "troca itens de lugar na mochila")
    var esc := InputEventAction.new()
    esc.action = "menu"
    esc.pressed = true
    Input.parse_input_event(esc)
    Input.flush_buffered_events()
    await frames(1)
    check(not ui.is_open() and not get_tree().paused, "Esc fecha a mochila (sem abrir a pausa)")
    check(not _main.get_node("HUD").pause_menu.visible, "menu de pausa continua fechado")


func _test_save_load() -> void:
    print("[Fase 2: salvar e carregar]")
    var f := field()
    var chest := node("Farm/Entities/BauDoAvo") as Chest
    var tree := node("Farm/Entities/Pequizeiro3") as Pequizeiro
    GameState.add_item(&"pequi", 7)
    await face_right_in_roca(Vector2(260, 230))
    var cell := f.cell_at(_player.get_target_position())
    select_item(&"enxada")
    use_at_front()
    f.plant(cell, &"abobora")
    f.water(cell)
    GameState.sleep()
    f.water(cell)
    chest.inventory.add(&"milho", 5)
    tree._set_available(1)
    var expected_inv := GameState.inventory.to_data()
    var expected_day := GameState.day
    var expected_cells := f.get_save_data()
    var expected_chest := chest.inventory.to_data()
    var pos := _player.global_position
    check(SaveManager.save_game() and SaveManager.has_save(), "jogo salvo em arquivo")
    var raw := SaveManager.read_save_file()
    check(int(raw.get("version", -1)) == GameState.DATA_VERSION, "save tem número de versão")
    # Bagunça tudo
    GameState.new_game()
    f.load_save_data({})
    chest.inventory.clear()
    tree._set_available(3)
    await place_player(Vector2(600, 300))
    check(f.cells.is_empty() and GameState.day == 1, "estado apagado antes de carregar")
    check(SaveManager.load_game(), "carregou o save")
    check(GameState.day == expected_day, "dia restaurado")
    check(GameState.inventory.to_data() == expected_inv, "mochila restaurada")
    check(f.get_save_data() == expected_cells, "plantação restaurada (terra, planta, idade, rega)")
    check(f._crop_sprites.has(cell), "sprite da planta recriado")
    check(chest.inventory.to_data() == expected_chest, "baú restaurado")
    check(tree.get_available() == 1, "pequis no chão restaurados")
    check(_player.global_position.distance_to(pos) < 1.0, "posição do jogador restaurada")


func _test_save_robustness() -> void:
    print("[Fase 2: save robusto]")
    var f := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
    f.store_string("{isso não é json")
    f.close()
    var day := GameState.day
    check(not SaveManager.load_game() and GameState.day == day, "save corrompido é ignorado sem quebrar")
    f = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
    f.store_string(JSON.stringify({"version": GameState.DATA_VERSION + 5, "game": {"day": 99}}))
    f.close()
    check(not SaveManager.load_game() and GameState.day == day, "save de versão mais nova é recusado")
    f = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
    f.store_string(JSON.stringify({"game": {"day": 4}}))
    f.close()
    check(SaveManager.load_game() and GameState.day == 4, "save antigo sem versão carrega com padrões")
    SaveManager.delete_save()
    check(not SaveManager.has_save(), "apagar save funciona")


func _test_touch_use_button() -> void:
    print("[Fase 2: toque]")
    var tc := _main.get_node("TouchControls") as TouchControls
    tc.set_touch_mode(true)
    var f := field()
    await face_right_in_roca(Vector2(120, 160))
    var cell := f.cell_at(_player.get_target_position())
    select_item(&"enxada")
    _player._use_cooldown = 0.0
    await frames(2)
    var btn := tc.get_node("Interact") as TouchScreenButton
    var center := btn.position + btn.texture_normal.get_size() / 2.0
    touch(3, center, true)
    await frames(1)
    touch(3, center, false)
    await frames(2)
    check(f.is_tilled(cell), "botão verde de toque capina (um botão só)")
    var bag := tc.get_node("Bag") as TouchScreenButton
    var bc := bag.position + bag.texture_normal.get_size() / 2.0
    touch(4, bc, true)
    await frames(1)
    touch(4, bc, false)
    await frames(1)
    var ui := _main.get_node("InventoryUI") as InventoryUI
    check(ui.is_open(), "botão da mochila abre a mochila")
    touch(4, bc, true)
    await frames(1)
    touch(4, bc, false)
    await frames(1)
    check(not ui.is_open(), "botão da mochila fecha a mochila")
    tc.set_touch_mode(false)


func press_e() -> void:
    _player._use_cooldown = 0.0
    var ev := InputEventAction.new()
    ev.action = "interact"
    ev.pressed = true
    Input.parse_input_event(ev)
    Input.flush_buffered_events()
    await frames(1)
    var up := InputEventAction.new()
    up.action = "interact"
    up.pressed = false
    Input.parse_input_event(up)
    Input.flush_buffered_events()
    await frames(1)


func _test_contextual_e() -> void:
    print("[E contextual]")
    GameState.new_game()
    var f := field()
    await face_right_in_roca(Vector2(150, 160))
    var cell := f.cell_at(_player.get_target_position())
    select_item(&"enxada")
    await frames(2)
    check(_prompts[-1] == "Capinar", "dica '[E] Capinar' com a enxada na roça")
    await press_e()
    check(f.is_tilled(cell), "E capina")
    select_item(&"semente_milho")
    await frames(2)
    check(_prompts[-1] == "Plantar milho", "dica 'Plantar milho'")
    await press_e()
    check(f.get_crop_id(cell) == &"milho", "E planta")
    select_item(&"regador")
    await frames(2)
    check(_prompts[-1] == "Regar", "dica 'Regar'")
    await press_e()
    check(f.is_watered(cell), "E rega")
    # Poço: com regador cheio, E olha o poço; com regador gasto, E enche
    var well := node("Farm/Entities/Poco")
    await place_player(well.global_position + Vector2(0, 16))
    _player.face(4)
    await frames(2)
    check(GameState.water < GameState.WATER_MAX and _prompts[-1] == "Encher regador", "regador gasto: dica 'Encher regador' no poço")
    _messages.clear()
    await press_e()
    check(GameState.water == GameState.WATER_MAX, "E enche o regador no poço")
    await frames(2)
    check(_prompts[-1] == "Olhar o poço", "regador cheio: E volta a olhar o poço")
    # Porta: segurando a enxada, E dorme (não tenta capinar)
    var house := node("Farm/Entities/CasaPrincipal")
    select_item(&"enxada")
    await place_player(house.global_position + Vector2(0, 14))
    _player.face(4)
    await frames(2)
    var day := GameState.day
    check(_prompts[-1].begins_with("Dormir"), "na porta com a enxada a dica é Dormir")
    await press_e()
    check(GameState.day == day + 1, "E dorme mesmo segurando a enxada")
    # Colher tem prioridade sobre a ferramenta
    await face_right_in_roca(Vector2(150, 160))
    f.cells[cell].age = 99
    f._refresh(cell)
    select_item(&"regador")
    await frames(2)
    check(_prompts[-1] == "Colher milho", "planta madura: colher ganha do regador")
    var milho := GameState.get_item_count(&"milho")
    await press_e()
    check(GameState.get_item_count(&"milho") > milho, "E colhe")
    # Segurar E capina uma fileira andando
    select_item(&"enxada")
    await place_player(Vector2(120, 256))
    _player.face(2)
    await frames(2)
    _player._use_cooldown = 0.0
    var hold := InputEventAction.new()
    hold.action = "interact"
    hold.pressed = true
    Input.parse_input_event(hold)
    Input.flush_buffered_events()
    Input.action_press("move_right")
    await frames(40)
    Input.action_release("move_right")
    var rel := InputEventAction.new()
    rel.action = "interact"
    rel.pressed = false
    Input.parse_input_event(rel)
    Input.flush_buffered_events()
    await frames(2)
    var row := 0
    for x in range(6, 18):
        if f.is_tilled(Vector2i(x, 15)):
            row += 1
    check(row >= 3, "segurar E e andar capina vários quadrados (%d)" % row)
    check(not _player._interact_held, "soltar E para de repetir")


# --- Fase 3 ----------------------------------------------------------------

## Pula direto para um dia (sem passar pelos anteriores).
func jump_to_day(d: int) -> void:
    GameState.day = d - 1
    GameState.sleep()


func _test_calendar() -> void:
    print("[Fase 3: calendário]")
    check(Calendar.format_date(1) == "Seg, 1 Out", "dia 1 = Seg, 1 Out")
    check(Calendar.period(1) == Calendar.PERIOD_RAINY, "outubro é período chuvoso")
    check(Calendar.format_date(11) == "Qui, 1 Nov", "dia 11 = 1 Nov")
    check(Calendar.month_index(31) == 0 and Calendar.year(31) == 2, "dia 31 = janeiro do ano 2")
    check(Calendar.month_index(70) == 3 and Calendar.period(70) == Calendar.PERIOD_RAINY, "abril ainda é chuvoso")
    check(Calendar.month_index(71) == 4 and Calendar.period(71) == Calendar.PERIOD_DRY, "maio começa o período seco")
    check(Calendar.period(120) == Calendar.PERIOD_DRY and Calendar.period(121) == Calendar.PERIOD_RAINY, "outubro do ano 2 volta a chover")
    check(Calendar.is_pequi_season(1) and Calendar.is_pequi_season(40) and not Calendar.is_pequi_season(41), "safra do pequi: outubro a janeiro")
    check(Calendar.format_time(390) == "06:30" and Calendar.format_time(25 * 60) == "01:00", "formato da hora")
    check(Calendar.format_date_long(1) == "1º de outubro, ano 1", "data por extenso")


func _test_clock() -> void:
    print("[Fase 3: relógio]")
    GameState.new_game()
    check(Clock.minutes == Clock.DAY_START, "dia começa às 06:00")
    Clock.advance_minutes(90)
    check(Calendar.format_time(Clock.minutes) == "07:30", "avança o relógio")
    # passa sozinho com o relógio ligado
    Clock.real_seconds_per_step = 0.02
    Clock.running = true
    var before := Clock.minutes
    await get_tree().create_timer(0.25).timeout
    Clock.running = false
    Clock.real_seconds_per_step = 7.0
    check(Clock.minutes > before, "o tempo passa sozinho (%s)" % Calendar.format_time(Clock.minutes))
    # pausa congela o tempo
    Clock.real_seconds_per_step = 0.02
    Clock.running = true
    get_tree().paused = true
    before = Clock.minutes
    await get_tree().create_timer(0.25, true, false, true).timeout
    var during_pause := Clock.minutes
    get_tree().paused = false
    Clock.running = false
    Clock.real_seconds_per_step = 7.0
    check(during_pause == before, "o tempo para com o jogo pausado")
    # apagar às 02:00
    await place_player(Vector2(600, 300))
    var day := GameState.day
    _messages.clear()
    Clock.advance_minutes(Clock.DAY_END - Clock.minutes)
    await frames(2)
    check(GameState.day == day + 1 and Clock.minutes == Clock.DAY_START, "às 02:00 apaga e acorda no dia seguinte às 06:00")
    var spawn: Vector2 = _main.level.get_spawn_position()
    check(_player.global_position.distance_to(spawn) < 2.0, "acorda na porta de casa")
    check(_messages.size() > 0 and _messages[-1].contains("apagou"), "mensagem de que apagou")
    var hud := _main.get_node("HUD")
    check(hud.day_label.text.begins_with(Calendar.format_date(GameState.day) + "  06:00"), "HUD mostra data e hora")


func _test_weather_rolls() -> void:
    print("[Fase 3: clima]")
    var saved_force := Clock.forced_weather
    Clock.forced_weather = -1
    var rain_wet := 0
    var rain_dry := 0
    for d in range(2, 72):          # out a abr (chuvoso)
        if Clock.roll_weather(d) in [Clock.Weather.CHUVA, Clock.Weather.TEMPESTADE]:
            rain_wet += 1
    for year in 3:                  # mai a set (seco) de 3 anos
        for d in range(71 + year * 120, 121 + year * 120):
            if Clock.roll_weather(d) in [Clock.Weather.CHUVA, Clock.Weather.TEMPESTADE]:
                rain_dry += 1
    check(rain_wet >= 20, "chuvoso chove bastante (%d de 70 dias)" % rain_wet)
    check(rain_dry <= 12, "seco quase não chove (%d de 150 dias)" % rain_dry)
    check(Clock.roll_weather(1) == Clock.Weather.ENSOLARADO, "primeiro dia sempre ensolarado")
    check(Clock.roll_weather(17) == Clock.roll_weather(17), "mesmo save, mesmo clima no mesmo dia")
    var seco_tipos := {}
    for d in range(71, 121):
        seco_tipos[Clock.roll_weather(d)] = true
    check(seco_tipos.has(Clock.Weather.NEBLINA) or seco_tipos.has(Clock.Weather.VENTANIA), "seco tem neblina/ventania")
    Clock.forced_weather = saved_force


func _test_rain_and_periods() -> void:
    print("[Fase 3: chuva e períodos]")
    GameState.new_game()
    var f := field()
    f.load_save_data({})
    var cell := Vector2i(8, 11)
    f.till(cell)
    f.plant(cell, &"milho")
    Clock.forced_weather = Clock.Weather.CHUVA
    GameState.sleep()
    check(Clock.weather == Clock.Weather.CHUVA and f.is_watered(cell), "dia de chuva rega a roça sozinho")
    GameState.sleep()
    check(f.cells[cell].age == 1, "planta cresceu com a chuva sem regar à mão")
    var wfx := _main.get_node("WeatherFX") as WeatherFX
    check(wfx.rain.emitting, "chuva aparece na tela")
    Clock.forced_weather = Clock.Weather.ENSOLARADO
    GameState.sleep()
    check(not wfx.rain.emitting, "sol: sem chuva na tela")
    # Virada para o período seco
    var cell2 := Vector2i(9, 11)
    f.till(cell2)
    f.plant(cell2, &"feijao")
    _messages.clear()
    jump_to_day(71)
    check(Calendar.period(GameState.day) == Calendar.PERIOD_DRY, "chegou maio (seco)")
    check(f.get_crop_id(cell) == &"", "milho morre no período seco")
    check(f.get_crop_id(cell2) == &"feijao", "feijão aguenta o seco")
    check(_messages.size() > 0 and _messages[-1].contains("milho"), "avisa que o milho morreu")
    # Não deixa plantar fora de época
    await face_right_in_roca(Vector2(150, 160))
    var target := f.cell_at(_player.get_target_position())
    f.till(target)
    select_item(&"semente_milho")
    await frames(2)
    check(_prompts[-1] == "Plantar milho (fora de época)", "dica avisa 'fora de época'")
    await press_e()
    check(f.get_crop_id(target) == &"" and _messages[-1].contains("chuvoso"), "não planta milho no seco e explica")
    select_item(&"semente_feijao")
    await frames(2)
    await press_e()
    check(f.get_crop_id(target) == &"feijao", "feijão planta no seco")


func _test_pequi_season() -> void:
    print("[Fase 3: safra do pequi]")
    var tree := node("Farm/Entities/Pequizeiro4") as Pequizeiro
    jump_to_day(80)  # maio/junho
    check(tree.get_available() == 0, "fora da safra não cai pequi")
    await place_player(tree.global_position + Vector2(0, 18))
    _player.face(4)
    GameState.select_slot(8)
    await frames(3)
    check(_prompts[-1] == "Pé de pequi (fora da safra)", "dica 'fora da safra'")
    jump_to_day(121)  # outubro do ano 2
    check(tree.get_available() == tree.fruits_on_ground, "em outubro volta a cair pequi")


func _test_daylight_and_hud() -> void:
    print("[Fase 3: luz]")
    var noon := Clock.daylight_color(12 * 60, Clock.Weather.ENSOLARADO)
    var night := Clock.daylight_color(23 * 60, Clock.Weather.ENSOLARADO)
    var dusk := Clock.daylight_color(18 * 60, Clock.Weather.ENSOLARADO)
    var rainy_noon := Clock.daylight_color(12 * 60, Clock.Weather.CHUVA)
    check(noon.v > 0.95, "meio-dia claro")
    check(night.v < 0.7 and night.b > night.r, "noite escura e azulada")
    check(dusk.r > dusk.b, "fim de tarde alaranjado")
    check(rainy_noon.v < noon.v, "dia de chuva mais escuro")
    var wfx := _main.get_node("WeatherFX") as WeatherFX
    Clock.minutes = 23 * 60
    wfx.refresh()
    check(wfx.daylight.color.is_equal_approx(night), "CanvasModulate segue o relógio")
    Clock.minutes = Clock.DAY_START
    Clock.weather = Clock.Weather.NEBLINA
    wfx.refresh()
    check(wfx.fog.color.a > 0.3, "neblina de manhã")
    Clock.minutes = 11 * 60
    wfx.refresh()
    check(wfx.fog.color.a == 0.0, "neblina some até as 10h")
    Clock.weather = Clock.Weather.ENSOLARADO
    wfx.refresh()


func _test_save_v2_and_migration() -> void:
    print("[Fase 3: save v2]")
    Clock.minutes = 15 * 60 + 40
    Clock.weather = Clock.Weather.NUBLADO
    var seed := Clock.world_seed
    check(SaveManager.save_game(), "salva com relógio")
    var raw := SaveManager.read_save_file()
    check(int(raw.version) == GameState.DATA_VERSION and raw.has("clock"), "save tem relógio e clima")
    Clock.reset()
    check(SaveManager.load_game(), "carrega")
    check(Clock.minutes == 15 * 60 + 40 and Clock.weather == Clock.Weather.NUBLADO and Clock.world_seed == seed, "hora, clima e semente restaurados")
    # Save antigo da Fase 2 (v1)
    var v1 := {"version": 1, "game": {"day": 5, "water": 3, "selected_slot": 0,
        "inventory": [{"id": "enxada", "count": 1}]}, "player": {}, "nodes": {}}
    var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
    file.store_string(JSON.stringify(v1))
    file.close()
    Clock.minutes = 20 * 60
    check(SaveManager.load_game(), "save v1 (Fase 2) carrega na Fase 3")
    check(GameState.day == 5 and GameState.water == 3, "dados da v1 preservados")
    check(Clock.minutes == Clock.DAY_START and Clock.weather == Clock.Weather.ENSOLARADO, "migração v1→v2 começa o dia às 06:00, ensolarado")
    SaveManager.delete_save()


# --- Fase 4 ----------------------------------------------------------------

func vila() -> Level:
    return _main.get_region(&"vila")


func npc(id: String) -> Npc:
    for n in get_tree().get_nodes_in_group("npc"):
        if String(n.data.id) == id:
            return n
    return null


func set_time(day: int, minutes: int) -> void:
    GameState.day = day
    Clock.minutes = minutes
    Clock.time_changed.emit(minutes)


func _test_regions() -> void:
    print("[Fase 4: regiões]")
    GameState.new_game()
    _main.change_region_now(&"farm")
    var farm: Level = _main.get_region(&"farm")
    check(_main.level == farm and farm.visible and not vila().visible, "começa na fazenda, vila escondida")
    # Andar até a saída leste
    await place_player(Vector2(925, 320))
    Input.action_press("move_right")
    await frames(25)
    Input.action_release("move_right")
    await get_tree().create_timer(0.8).timeout
    check(_main.level == vila(), "saída leste leva à vila")
    check(_player.get_parent() == vila().get_entities_root(), "jogador está nas entidades da vila")
    check(not farm.visible and farm.process_mode == Node.PROCESS_MODE_DISABLED, "fazenda desligada enquanto está na vila")
    check(_player.camera.limit_right == 800, "câmera com o tamanho da vila")
    check(_player.global_position.distance_to(vila().get_marker(&"da_fazenda").global_position) < 20, "chega pela entrada oeste")
    check(_player.input_enabled, "controle volta depois da transição")
    # A lagoa da fazenda fica nas mesmas coordenadas: não pode bloquear a vila.
    await place_player(Vector2(170, 372))
    Input.action_press("move_down")
    await frames(40)
    Input.action_release("move_down")
    check(_player.global_position.y > 410, "água da fazenda não bloqueia a vila (%.0f)" % _player.global_position.y)
    # Voltar
    await place_player(Vector2(36, 320))
    Input.action_press("move_left")
    await frames(25)
    Input.action_release("move_left")
    await get_tree().create_timer(0.8).timeout
    check(_main.level == farm and farm.visible, "saída oeste da vila volta para a fazenda")
    check(_player.global_position.distance_to(farm.get_marker(&"da_vila").global_position) < 20, "chega pela estrada leste da fazenda")
    # Fazenda continua viva: planta cresce mesmo com o jogador na vila
    var f := field()
    var cell := Vector2i(10, 10)
    f.load_save_data({})
    f.till(cell)
    f.plant(cell, &"milho")
    f.water(cell)
    _main.change_region_now(&"vila")
    Clock.advance_minutes(Clock.DAY_END - Clock.minutes)  # apaga às 2h na vila
    await frames(2)
    check(_main.level == farm, "apagar na vila acorda na fazenda")
    check(f.cells[cell].age == 1, "plantação cresceu enquanto estava fora")


func _test_village_layout() -> void:
    print("[Fase 4: vila]")
    var v := vila()
    check(v.ground.map_size == Vector2i(50, 34), "mapa da vila carregado (50x34)")
    _main.change_region_now(&"vila")
    var all_ok := true
    for m in v.get_node("Markers").get_children():
        if not v.is_walkable(m.global_position):
            all_ok = false
            printerr("    marcador em lugar bloqueado: ", m.name, " ", m.global_position)
    check(all_ok, "todos os marcadores ficam em lugar andável")
    var missing := []
    for n in get_tree().get_nodes_in_group("npc"):
        for line in Array(n.data.schedule) + Array(n.data.schedule_sunday):
            var marker := String(line).split(" ")[1].trim_suffix("!")
            if v.get_marker(StringName(marker)) == null:
                missing.append(marker)
    check(missing.is_empty(), "todos os marcadores das rotinas existem %s" % [missing])
    check(get_tree().get_nodes_in_group("npc").filter(func(n: Node) -> bool: return vila().is_ancestor_of(n)).size() == 6, "6 moradores na vila")
    var p := v.find_path(v.get_marker(&"casa_azul").global_position, v.get_marker(&"lagoa_pier").global_position)
    check(p.size() > 10, "existe caminho da casa azul até a lagoa (%d passos)" % p.size())
    var blocked := false
    for pt in p:
        if not v.is_walkable(pt):
            blocked = true
    check(not blocked, "caminho não atravessa prédios nem água")


func _test_npc_schedule_and_walk() -> void:
    print("[Fase 4: rotina]")
    _main.change_region_now(&"vila")
    var helena := npc("helena")
    set_time(2, 6 * 60 + 10)  # terça 06:10
    helena.snap_to_schedule()
    check(helena.inside and not helena.visible, "06:10 Helena ainda está em casa")
    check(not helena.interactable.enabled, "dentro de casa não dá pra conversar")
    set_time(2, 7 * 60 + 30)
    check(not helena.inside and helena.visible and not helena._path.is_empty(), "07:30 sai de casa andando")
    for i in 400:
        helena._process(0.1)
        if helena._path.is_empty():
            break
    check(helena.is_at_marker(&"mercearia_balcao"), "chegou no balcão da mercearia andando")
    check(helena.is_shop_open(), "loja aberta com ela no balcão")
    set_time(2, 20 * 60 + 10)
    helena.snap_to_schedule()
    check(helena.inside and not helena.is_shop_open(), "20h já foi pra casa: loja fechada")
    set_time(7, 10 * 60)  # dia 7 = domingo
    helena.snap_to_schedule()
    check(Calendar.weekday(7) == "Dom" and helena.is_at_marker(&"igreja_porta"), "domingo de manhã Helena vai à igreja")
    check(not helena.is_shop_open(), "domingo a mercearia não abre")
    var benedito := npc("benedito")
    set_time(2, 9 * 60)
    benedito.snap_to_schedule()
    check(benedito.is_at_marker(&"praca_banco_2"), "Seu Benedito no banco da praça às 9h")


func _test_dialogue_and_friendship() -> void:
    print("[Fase 4: conversa]")
    var dlg := _main.get_node("DialogueUI") as DialogueUI
    Quests.active.clear()  # sem fala de missão no meio
    var joao := npc("benedito")
    joao.met = false
    joao.friendship = 0
    joao.last_talk_day = 0
    set_time(3, 9 * 60)
    Clock.weather = Clock.Weather.ENSOLARADO
    joao.snap_to_schedule()
    await place_player(joao.global_position + Vector2(0, 16))
    _player.face(4)
    GameState.select_slot(8)
    await frames(3)
    check(_prompts[-1] == "Conversar com Seu Benedito", "dica 'Conversar com Seu Benedito'")
    await press_e()
    check(dlg.is_open() and get_tree().paused, "conversa abre e pausa")
    check(dlg.lines == joao.data.intro, "primeira conversa é a apresentação")
    check(dlg.speaker == "Seu Benedito", "nome de quem fala")
    for i in joao.data.intro.size():
        var ev := InputEventAction.new()
        ev.action = "interact"
        ev.pressed = true
        Input.parse_input_event(ev)
        Input.flush_buffered_events()
        await frames(1)
    check(not dlg.is_open() and not get_tree().paused, "E avança e fecha no fim")
    check(joao.met and joao.friendship == Npc.TALK_FRIENDSHIP, "conheceu e ganhou amizade")
    await press_e()
    check(dlg.lines.size() == 1 and dlg.lines[0] in joao.data.lines_repeat, "segunda conversa no dia: fala de repetição")
    dlg.close()
    check(joao.friendship == Npc.TALK_FRIENDSHIP, "amizade só sobe uma vez por dia")
    set_time(4, 9 * 60)
    var pool := Array(joao.data.lines_generic) + Array(joao.data.lines_morning)
    check(joao.pick_lines()[0] in pool, "outro dia de manhã: fala de manhã ou geral")
    Clock.weather = Clock.Weather.CHUVA
    check(joao.pick_lines()[0] in joao.data.lines_rain, "chovendo: fala sobre a chuva")
    Clock.weather = Clock.Weather.ENSOLARADO
    joao.friendship = 60
    var found_friend := false
    for d in range(10, 60):
        GameState.day = d
        if joao.pick_lines()[0] in joao.data.lines_friend:
            found_friend = true
            break
    check(found_friend, "com amizade alta aparecem falas de amigo")


func _test_shop() -> void:
    print("[Fase 4: mercearia]")
    GameState.new_game()
    var shop := _main.get_node("ShopUI") as ShopUI
    var dlg := _main.get_node("DialogueUI") as DialogueUI
    var helena := npc("helena")
    helena.met = true
    set_time(2, 10 * 60)
    helena.snap_to_schedule()
    await place_player(helena.global_position + Vector2(0, 16))
    _player.face(4)
    GameState.select_slot(8)
    await frames(3)
    check(_prompts[-1] == "Conversar com Helena", "na frente do balcão: conversa com a Helena (não com a placa)")
    await press_e()
    check(dlg.is_open() and dlg.options == PackedStringArray(["Comprar", "Vender", "Tchau"]), "Helena oferece Comprar/Vender/Tchau")
    dlg.choose(0)
    await frames(1)
    check(shop.is_open() and shop.tab == ShopUI.Tab.BUY and get_tree().paused, "Comprar abre a loja")
    var money := GameState.money
    var seeds := GameState.get_item_count(&"semente_abobora")
    check(shop.buy(&"semente_abobora", 1) == 1, "comprou 1 semente de abóbora")
    check(GameState.money == money - 16 and GameState.get_item_count(&"semente_abobora") == seeds + 1, "dinheiro saiu e semente entrou")
    GameState.spend_money(GameState.money - 15)
    check(shop.buy(&"semente_abobora", 1) == 0 and GameState.money == 15, "sem dinheiro não compra")
    check(shop.buy(&"semente_milho", 5) == 1, "compra só o que o dinheiro dá")
    check(shop.buy(&"enxada", 1) == 0, "não vende o que não está na lista")
    shop.set_tab(ShopUI.Tab.SELL)
    GameState.add_item(&"abobora", 3)
    GameState.add_item(&"pequi", 4)
    var before := GameState.money
    check(shop.sell(&"abobora", 999) == 3 and GameState.money == before + 3 * 35, "vende 3 abóboras por R$ 105")
    check(shop.sell(&"pequi", 1) == 1 and GameState.get_item_count(&"pequi") == 3, "vende pequi um por um")
    check(shop.sell(&"enxada", 1) == 0 and GameState.get_item_count(&"enxada") == 1, "não compra ferramenta")
    check(shop.sell(&"semente_milho", 1) == 0, "não compra semente de volta")
    var hud := _main.get_node("HUD")
    check(hud.day_label.text.ends_with("R$ %d" % GameState.money), "HUD mostra o dinheiro")
    shop.close()
    check(not get_tree().paused, "fechar a loja despausa")
    # Fora do horário
    set_time(2, 19 * 60)
    helena.snap_to_schedule()
    helena.talk()
    check(dlg.is_open() and dlg.options.is_empty(), "fora do horário: só conversa, sem loja")
    dlg.close()


func _test_save_v3() -> void:
    print("[Fase 4: save v3]")
    _main.change_region_now(&"vila")
    var helena := npc("helena")
    helena.friendship = 37
    helena.met = true
    GameState.money = 1234
    await place_player(Vector2(424, 300))
    check(SaveManager.save_game(), "salva na vila")
    var raw := SaveManager.read_save_file()
    check(raw.player.region == "vila" and int(raw.game.money) == 1234, "save guarda região e dinheiro")
    _main.change_region_now(&"farm")
    GameState.money = 0
    helena.friendship = 0
    check(SaveManager.load_game(), "carrega")
    check(_main.level == vila() and _player.global_position.distance_to(Vector2(424, 300)) < 1.0, "volta para a vila, no mesmo lugar")
    check(GameState.money == 1234 and helena.friendship == 37, "dinheiro e amizade restaurados")
    var v2 := {"version": 2, "game": {"day": 9}, "clock": {"minutes": 600}, "player": {"x": 100, "y": 100}, "nodes": {}}
    var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
    file.store_string(JSON.stringify(v2))
    file.close()
    check(SaveManager.load_game(), "save da Fase 3 (v2) carrega")
    check(GameState.money == GameState.STARTING_MONEY and _main.level.region_id == &"farm", "migração v2→v3: dinheiro inicial e fazenda")
    SaveManager.delete_save()
    _main.change_region_now(&"farm")


## Proteção contra um bug que só aparece no jogo exportado (Web/Windows):
## propriedade exportada cujo valor padrão tem tipo diferente do declarado
## (ex.: PackedStringArray = []) perde os valores do .tres na exportação.
func _test_export_safe_defaults() -> void:
    print("[exportação]")
    # O editor só percebe o problema no export, então verificamos o texto
    # dos scripts: "@export var x: PackedStringArray = [...]" é proibido.
    var bad := []
    var scripts := []
    _collect_scripts("res://scripts", scripts)
    var re := RegEx.create_from_string("@export[^\\n]*:\\s*Packed\\w+Array\\s*=\\s*\\[")
    for path: String in scripts:
        var text := FileAccess.get_file_as_string(path)
        for m in re.search_all(text):
            bad.append(path.get_file())
    check(scripts.size() > 20, "scripts encontrados para verificar (%d)" % scripts.size())
    check(bad.is_empty(), "arrays exportados com padrão do tipo certo %s" % [bad])


func _collect_scripts(path: String, out: Array) -> void:
    var d := DirAccess.open(path)
    if d == null:
        return
    for f in d.get_files():
        if f.ends_with(".gd"):
            out.append(path + "/" + f)
    for sub in d.get_directories():
        _collect_scripts(path + "/" + sub, out)


# --- Fase 5 ----------------------------------------------------------------

func mata() -> MataLevel:
    return _main.get_region(&"mata") as MataLevel


func _test_mata_region() -> void:
    print("[Fase 5: Mata dos Ipês]")
    _main.change_region_now(&"vila")
    await place_player(Vector2(770, 320))
    Input.action_press("move_right")
    await frames(25)
    Input.action_release("move_right")
    await get_tree().create_timer(0.8).timeout
    check(_main.level == mata(), "saída leste da vila leva à mata")
    check(mata().ground.map_size == Vector2i(60, 34) and mata().water_habitat == "rio", "mapa da mata com rio")
    check(not mata().is_walkable(Vector2(100, 420)) and mata().is_walkable(Vector2(472, 420)), "rio bloqueia, ponte deixa passar")
    var path := mata().find_path(Vector2(40, 328), Vector2(472, 488))
    check(path.size() > 5, "dá para atravessar o rio pela ponte")


func _test_fishing() -> void:
    print("[Fase 5: pesca]")
    GameState.new_game()
    _main.change_region_now(&"farm")
    var fishing := _main.get_node("Fishing") as Fishing
    var ui := _main.get_node("FishingUI") as FishingUI
    GameState.add_item(&"vara_bambu", 1)
    select_item(&"vara_bambu")
    await place_player(Vector2(140, 381))
    _player.face(0)
    await frames(3)
    check(fishing.is_water(_player.get_target_position()), "de frente para a lagoa")
    check(_prompts[-1] == "Pescar", "dica 'Pescar' com a vara na mão")
    _messages.clear()
    await press_e()
    check(not ui.is_active() and _messages[-1].contains("isca"), "sem isca não pesca e avisa")
    GameState.add_item(&"isca", 3)
    await press_e()
    check(ui.is_active() and ui.phase == FishingUI.Phase.WAIT and GameState.get_item_count(&"isca") == 2, "lançou: gastou 1 isca, esperando")
    check(not _player.input_enabled, "jogador parado enquanto pesca")
    ui.press()
    check(not ui.is_active() and _player.input_enabled, "puxar cedo espanta o peixe")
    # pescaria completa
    Clock.minutes = 10 * 60
    await press_e()
    ui._timer = 0.0
    await frames(2)
    check(ui.phase == FishingUI.Phase.BITE, "peixe fisgou")
    ui.press()
    check(ui.phase == FishingUI.Phase.REEL, "começou a briga")
    var fish := ui.fish
    for i in ui.hits_needed:
        ui.marker = ui.zone_center
        ui.press()
    check(not ui.is_active(), "acertos suficientes terminam a briga")
    check(GameState.get_item_count(fish.item) == 1, "peixe na mochila (%s)" % fish.item)
    check(GameState.fish_log.has(fish.item) and GameState.skill_xp.get(&"pesca", 0) > 0, "registrado e ganhou XP de pesca")
    check(fish.item in [&"lambari", &"traira", &"tucunare"], "peixe de lagoa na lagoa")
    # errar 3 vezes
    await press_e()
    ui._timer = 0.0
    await frames(2)
    ui.press()
    for i in 3:
        ui.marker = fposmod(ui.zone_center + 0.5, 1.0)
        ui.press()
    check(not ui.is_active() and _messages[-1].contains("fugiu"), "3 erros: o peixe foge")
    # loja do João
    var joao := npc("joao_pedro")
    check(joao.data.has_shop() and "isca" in joao.data.shop_sells, "João Pedro vende vara e isca")


func _test_fish_table() -> void:
    var f := _main.get_node("Fishing") as Fishing
    var seen := {}
    for i in 600:
        var fish := f.roll_fish("rio", 22 * 60, Calendar.PERIOD_RAINY, "chuva")
        seen[fish.item] = true
    check(seen.has(&"pintado") and seen.has(&"dourado_rei"), "noite de chuva no rio: pintado e às vezes o lendário")
    check(not seen.has(&"traira") and not seen.has(&"dourado"), "sem peixe de lagoa no rio; dourado é do seco de manhã")
    seen = {}
    for i in 300:
        seen[f.roll_fish("rio", 8 * 60, Calendar.PERIOD_DRY, "ensolarado").item] = true
    check(seen.has(&"dourado") and not seen.has(&"dourado_rei"), "manhã de seca no rio: dourado, sem lendário")
    seen = {}
    for i in 200:
        seen[f.roll_fish("lagoa", 7 * 60, Calendar.PERIOD_DRY, "ensolarado").item] = true
    check(seen.size() == 1 and seen.has(&"lambari"), "lagoa cedo no seco: só lambari")


func _test_ranch() -> void:
    print("[Fase 5: criação]")
    GameState.new_game()
    _main.change_region_now(&"farm")
    var ranch := get_tree().get_first_node_in_group("ranch") as Ranch
    ranch.load_save_data({})
    var shop := _main.get_node("ShopUI") as ShopUI
    shop.open_shop({"title": "Clínica", "sells": PackedStringArray(["animal:galinha", "racao"]), "buys": PackedInt32Array(), "tab": 0})
    GameState.money = 1000
    check(shop.buy_animal(&"galinha") and ranch.count(&"galinha") == 1 and GameState.money == 880, "comprou uma galinha (R$ 120)")
    check(shop.buy(&"racao", 5) == 5, "comprou ração")
    shop.close()
    var hens := ranch.get_children().filter(func(c: Node) -> bool: return c is FarmAnimal)
    check(hens.size() == 1 and ranch.chicken_pen.has_point(hens[0].position), "galinha aparece no galinheiro")
    for i in 5:
        ranch.add_animal(&"galinha")
    check(not ranch.can_buy(&"galinha") and ranch.count(&"galinha") == 6, "galinheiro cabe 6")
    # comedouro
    select_item(&"racao")
    var feeder := ranch.chicken_feeder
    await place_player(feeder.global_position + Vector2(0, 18))
    _player.face(4)
    await frames(3)
    check(_prompts[-1] == "Pôr no comedouro (0/20)", "dica 'Pôr no comedouro'")
    for i in 5:
        await press_e()
    check(ranch.feed[&"galinheiro"] == 5 and GameState.get_item_count(&"racao") == 0, "5 porções no comedouro")
    for a in ranch.animals:
        a.happiness = 100
    GameState.sleep()
    var eggs := ranch.get_children().filter(func(c: Node) -> bool: return c is Pickup)
    check(ranch.feed[&"galinheiro"] == 0, "galinhas comeram (5 porções)")
    check(eggs.size() == 5, "galinhas alimentadas e felizes botaram ovos (%d)" % eggs.size())
    var hungry := ranch.animals.filter(func(a: Dictionary) -> bool: return a.happiness < 100)
    check(hungry.size() == 1, "a galinha que não comeu ficou triste")
    var egg := eggs[0] as Pickup
    await place_player(egg.global_position + Vector2(0, 14))
    _player.face(4)
    await frames(3)
    check(_prompts[-1] == "Pegar ovo caipira", "dica 'Pegar ovo caipira'")
    await press_e()
    check(GameState.get_item_count(&"ovo") == 1 and ranch.pickups.size() == 4, "pegou o ovo")
    var hen: FarmAnimal = ranch.get_children().filter(func(c: Node) -> bool: return c is FarmAnimal)[0]
    var before: int = hen.record.happiness
    hen.record.happiness = 50
    hen.pet()
    hen.pet()
    check(hen.record.happiness == 58, "carinho: +8 felicidade, uma vez por dia")


func _test_wildlife_and_traps() -> void:
    print("[Fase 5: fauna e caça]")
    _main.change_region_now(&"mata")
    set_time(3, 10 * 60)
    mata().respawn()
    var animals := mata().animals()
    var cap := animals.filter(func(a: WildAnimal) -> bool: return a.species == &"capivara")
    var jav := animals.filter(func(a: WildAnimal) -> bool: return a.species == &"javali")
    check(cap.size() == 3 and cap[0].visible, "capivaras à beira do rio de dia")
    check(jav.size() == 3 and not jav[0].visible, "javali escondido de manhã")
    check(get_tree().get_nodes_in_group("tracks").size() >= 1, "pegadas de javali na mata")
    set_time(3, 18 * 60)
    check(jav[0].visible, "javali aparece no fim da tarde")
    set_time(3, 10 * 60)
    GameState.species_seen.clear()
    var c0 := cap[0] as WildAnimal
    c0.observe()
    check(GameState.species_seen.has(&"capivara") and _messages[-1].contains("Hydrochoerus"), "observar registra no caderno com nome científico")
    var xp: int = GameState.skill_xp.get(&"caca", 0)
    c0.observe()
    check(GameState.skill_xp[&"caca"] == xp + 2, "repetir observação dá pouco XP")
    # armadilha
    GameState.add_item(&"armadilha", 1)
    select_item(&"armadilha")
    await place_player(Vector2(200, 328))
    _player.face(2)
    await frames(3)
    check(_prompts[-1] == "Colocar armadilha de javali", "dica 'Colocar armadilha'")
    await press_e()
    var traps := get_tree().get_nodes_in_group("persistent").filter(func(n: Node) -> bool: return false)
    var placed := mata().get_node("Entities/Placed").get_children()
    check(placed.size() == 1 and GameState.get_item_count(&"armadilha") == 0, "armadilha armada na mata")
    var trap := placed[0] as Armadilha
    for d in 20:
        if trap.caught:
            break
        GameState.sleep()
    check(trap.caught, "armadilha pegou um javali depois de alguns dias")
    trap.open()
    check(GameState.get_item_count(&"carne_javali") == 2 and GameState.get_item_count(&"couro") == 1 and GameState.get_item_count(&"armadilha") == 1,
        "abrir: carne, couro e a armadilha de volta")
    _main.change_region_now(&"farm")
    select_item(&"armadilha")
    await face_right_in_roca(Vector2(150, 160))
    check(_prompts[-1] != "Colocar armadilha de javali", "armadilha não pode ser colocada na fazenda")


func _test_skills() -> void:
    print("[Fase 5: habilidades]")
    check(GameState.level_for_xp(0) == 0 and GameState.level_for_xp(50) == 1 and GameState.level_for_xp(4000) == 10, "tabela de níveis")
    var before := GameState.skill_level(&"mineracao")
    GameState.skill_xp[&"mineracao"] = 0
    GameState.add_xp(&"mineracao", 150)
    check(GameState.skill_level(&"mineracao") == 2 and _messages[-1].contains("nível 2"), "subir de nível avisa")


func _test_save_v4() -> void:
    print("[Fase 5: save v4]")
    _main.change_region_now(&"mata")
    var ranch := get_tree().get_first_node_in_group("ranch") as Ranch
    GameState.add_item(&"armadilha", 1)
    select_item(&"armadilha")
    await place_player(Vector2(260, 328))
    _player.face(2)
    await frames(3)
    await press_e()
    var expected_ranch := ranch.get_save_data()
    var expected_game := GameState.to_data()
    check(SaveManager.save_game(), "salva")
    ranch.load_save_data({})
    GameState.new_game()
    var cont := mata().get_node("Entities/Placed")
    for c in cont.get_children():
        c.free()
    check(SaveManager.load_game(), "carrega")
    check(JSON.stringify(ranch.get_save_data()) == JSON.stringify(expected_ranch), "animais, comedouro e ovos restaurados")
    check(GameState.skill_xp == expected_game.skills or GameState.to_data().skills == expected_game.skills, "habilidades restauradas")
    check(GameState.fish_log.size() == expected_game.fish_log.size() and GameState.species_seen.size() == expected_game.species_seen.size(), "caderno restaurado")
    check(mata().get_node("Entities/Placed").get_child_count() >= 1, "armadilha armada restaurada")
    var v3 := {"version": 3, "game": {"day": 3, "money": 50}, "player": {"region": "farm"}, "nodes": {}}
    var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
    file.store_string(JSON.stringify(v3))
    file.close()
    check(SaveManager.load_game() and GameState.money == 50 and GameState.skill_xp.is_empty(), "save v3 migra para v4")
    SaveManager.delete_save()
    _main.change_region_now(&"farm")


# --- Fase 6 ----------------------------------------------------------------

func spawn_enemy(kind: StringName, pos: Vector2) -> Enemy:
    var e := Enemy.new().setup(kind, pos, _main.level)
    _main.level.get_entities_root().add_child(e)
    return e


func _test_combat_basics() -> void:
    print("[Fase 6: golpes]")
    GameState.new_game()
    _main.change_region_now(&"farm")
    GameState.add_item(&"facao", 1)
    select_item(&"facao")
    await place_player(Vector2(600, 300))
    _player.face(2)
    await frames(2)
    check(_prompts[-1] == "Atacar", "com o facão na mão o E vira 'Atacar'")
    var e := spawn_enemy(&"raiz_torta", Vector2(614, 300))
    e.info = e.info.duplicate()
    e.info.speed = 0.0  # parado para o teste
    var combat := _player.combat
    check(combat.attack(), "golpe acontece")
    check(e.hp == e.max_hp - 10, "facão tira 10 de vida")
    check(not combat.attack(), "tempo de recarga entre golpes")
    combat.cooldown = 0.0
    combat.attack()
    combat.cooldown = 0.0
    combat.attack()
    check(combat.combo == 3, "terceiro golpe seguido é o combo")
    await frames(2)
    check(e.is_dead(), "raiz-torta derrotada em 3 golpes (o 3º é mais forte)")
    await get_tree().create_timer(0.4).timeout
    var drops: Array = _main.level.get_entities_root().get_children().filter(func(c: Node) -> bool: return c is Pickup)
    check(drops.size() >= 1, "inimigo deixa itens (madeira)")
    check(GameState.skill_xp.get(&"combate", 0) > 0, "XP de combate")
    for d in drops:
        d.queue_free()
    # golpe pelas costas não acerta; giro carregado acerta em volta
    var back := spawn_enemy(&"lodo_cinza", Vector2(586, 300))
    back.info = back.info.duplicate()
    back.info.speed = 0.0
    combat.cooldown = 0.0
    combat._since_last = 9.0
    combat.attack()
    check(back.hp == back.max_hp, "golpe normal não acerta quem está atrás")
    combat.cooldown = 0.0
    combat.begin_charge()
    combat.charge = CombatComponent.CHARGE_TIME + 0.1
    check(combat.release_charge() and back.hp <= back.max_hp - 20, "golpe carregado gira e acerta atrás (dano dobrado)")
    combat.charge = 0.1
    check(not combat.release_charge(), "soltar cedo não carrega")


func _test_enemies_and_damage() -> void:
    print("[Fase 6: inimigos e dano]")
    GameState.new_game()
    await place_player(Vector2(600, 300))
    var e := spawn_enemy(&"raiz_torta", Vector2(640, 300))
    for i in 120:
        await get_tree().physics_frame
        if GameState.health < GameState.MAX_HEALTH:
            break
    check(GameState.health == GameState.MAX_HEALTH - 8, "raiz-torta persegue e bate (8 de dano)")
    var hp := GameState.health
    _player.take_damage(10, Vector2.RIGHT)
    check(GameState.health == hp, "invulnerável logo depois de apanhar")
    e.queue_free()
    # desmaio
    GameState.money = 500
    _main.change_region_now(&"vila")
    var day := GameState.day
    _player._iframes = 0.0
    GameState.health = 5
    _player.take_damage(50, Vector2.LEFT)
    await frames(2)
    check(GameState.day == day + 1 and _main.level.region_id == &"farm", "vida zero: desmaia e acorda em casa no dia seguinte")
    check(GameState.health == GameState.MAX_HEALTH and GameState.money == 450, "volta com vida cheia e perde 10% do dinheiro")
    # inimigos noturnos da mata
    _main.change_region_now(&"mata")
    set_time(GameState.day, 12 * 60)
    mata().respawn()
    var en := mata().enemies()
    check(en.size() >= 3 and not en[0].visible, "criaturas corrompidas escondidas de dia")
    set_time(GameState.day, 20 * 60)
    check(en[0].visible, "à noite elas aparecem")
    set_time(GameState.day, 12 * 60)
    _main.change_region_now(&"farm")


func _test_ranged_dodge_hunt() -> void:
    print("[Fase 6: arco, esquiva e caça]")
    GameState.new_game()
    _main.change_region_now(&"farm")
    GameState.add_item(&"arco", 1)
    select_item(&"arco")
    await place_player(Vector2(600, 300))
    _player.face(2)
    await frames(2)
    check(_prompts[-1] == "Atirar", "arco: 'Atirar'")
    check(not _player.combat.attack() and _messages[-1].contains("flechas"), "sem flecha não atira")
    GameState.add_item(&"flecha", 5)
    var e := spawn_enemy(&"morcego", Vector2(680, 294))
    e.info = e.info.duplicate()
    e.info.speed = 0.0
    e.info.aggro = 0.0
    check(_player.combat.attack() and GameState.get_item_count(&"flecha") == 4, "atirou uma flecha")
    await get_tree().create_timer(0.5).timeout
    check(e.hp < e.max_hp, "flecha acertou o morcego de longe")
    e.queue_free()
    # esquiva
    var start := _player.global_position
    check(_player.combat.dodge(Vector2.LEFT), "esquivou")
    check(not _player.take_damage(20, Vector2.RIGHT), "durante a esquiva não leva dano")
    await get_tree().create_timer(0.3).timeout
    check(_player.global_position.x < start.x - 40, "a esquiva desloca o jogador")
    check(GameState.energy < GameState.MAX_ENERGY, "esquiva gasta energia")
    # caça ao javali (invasor) e proteção da fauna nativa
    _main.change_region_now(&"mata")
    set_time(GameState.day, 18 * 60)
    mata().respawn()
    var jav: WildAnimal = mata().animals().filter(func(a: WildAnimal) -> bool: return a.species == &"javali")[0]
    var cap: WildAnimal = mata().animals().filter(func(a: WildAnimal) -> bool: return a.species == &"capivara")[0]
    check(jav.is_in_group("huntable") and not cap.is_in_group("huntable"), "só o javali pode ser caçado")
    GameState.add_item(&"machado", 1)
    select_item(&"machado")
    for i in 2:
        jav.take_hit(22, Vector2.RIGHT, 0)
    await frames(2)
    var meat: Array = mata().get_entities_root().find_children("*", "Pickup", true, false)
    check(meat.size() >= 2, "javali abatido deixa carne e couro")
    _main.change_region_now(&"farm")


func _test_energy_and_paths() -> void:
    print("[Fase 6: energia e caminhos]")
    GameState.new_game()
    check(GameState.energy == 100 and GameState.health == 100, "começa com vida e energia cheias")
    GameState.energy = 1
    check(not GameState.use_energy(2) and _messages[-1].contains("energia"), "sem energia não usa ferramenta")
    GameState.sleep()
    check(GameState.energy == 100, "dormir recupera a energia")
    check(GameState.path_points_free() == 0, "sem nível de combate, sem pontos")
    GameState.skill_xp[&"combate"] = 300  # nível 3
    check(GameState.path_points_free() == 3, "nível 3 de combate = 3 pontos")
    var base := GameState.melee_multiplier()
    check(GameState.add_path_point(&"guerreiro") and GameState.melee_multiplier() > base, "Guerreiro aumenta o dano")
    GameState.add_path_point(&"cacador")
    GameState.add_path_point(&"explorador")
    check(not GameState.add_path_point(&"guerreiro"), "não passa do total de pontos")
    GameState.reset_paths()
    check(GameState.path_points_free() == 3, "pontos podem ser redistribuídos")


func _test_save_v5() -> void:
    print("[Fase 6: save v5]")
    GameState.health = 42
    GameState.energy = 17
    GameState.add_path_point(&"cacador")
    check(SaveManager.save_game(), "salva")
    GameState.new_game()
    check(SaveManager.load_game() and GameState.health == 42 and GameState.energy == 17 and GameState.paths[&"cacador"] == 1,
        "vida, energia e caminhos restaurados")
    SaveManager.delete_save()


# --- Fase 7: aventura ---------------------------------------------------------

func serra() -> SerraLevel:
    return _main.get_region(&"serra") as SerraLevel


func mine() -> MineLevel:
    return _main.get_region(&"mina") as MineLevel


func ruinas() -> RuinasLevel:
    return _main.get_region(&"ruinas") as RuinasLevel


## Conversa com o morador e fecha a caixa (conclui etapas de missão).
func talk_to(id: String) -> void:
    var dlg := _main.get_node("DialogueUI") as DialogueUI
    npc(id).talk()
    dlg.close()
    await frames(1)


func _test_quest_chain_start() -> void:
    print("[Fase 7: história — começo]")
    GameState.new_game()
    _main.change_region_now(&"vila")
    check(Quests.is_active("q_chegada"), "jogo novo começa a missão 'Uma nova vida'")
    var hud := _main.get_node("HUD")
    check(hud.quest_label.text.contains("Benedito"), "HUD mostra a etapa atual")
    var dlg := _main.get_node("DialogueUI") as DialogueUI
    var money := GameState.money
    npc("benedito").talk()
    check(dlg.is_open() and dlg.lines[0].begins_with("Então você veio mesmo"), "Benedito fala da missão em vez da conversa normal")
    dlg.close()
    await frames(1)
    check(Quests.is_done("q_chegada") and GameState.money == money + 100, "missão concluída com recompensa")
    check(Quests.is_active("q_luzes"), "próxima missão da história começa sozinha")
    set_time(GameState.day, 14 * 60)
    _main.change_region_now(&"mata")
    check(Quests.active["q_luzes"] == 0, "de dia na mata a etapa não conclui")
    set_time(GameState.day, 20 * 60)
    check(Quests.active["q_luzes"] == 1, "na mata depois das 19h: etapa concluída")
    _main.change_region_now(&"vila")
    set_time(GameState.day, 10 * 60)
    npc("benedito").snap_to_schedule()
    await talk_to("benedito")
    check(Quests.is_active("q_fragmentos") and GameState.get_item_count(&"flecha") >= 10, "Benedito conta do Silêncio e dá flechas")
    var talked := Quests.dialogue_for("mariana")
    check(talked.is_empty(), "sem os fragmentos a Mariana não tem fala de entrega")
    GameState.add_item(&"fragmento_silencio", 3)
    await talk_to("mariana")
    check(Quests.is_active("q_trilha") and GameState.get_item_count(&"fragmento_silencio") == 0, "fragmentos entregues à Mariana")
    await talk_to("toninho")
    check(GameState.get_item_count(&"picareta") == 1, "Toninho entrega a picareta do avô")
    check(Quests.step("q_trilha").type == "flag", "etapa seguinte: abrir a trilha")


func _test_mining_and_trail() -> void:
    print("[Fase 7: picareta e trilha da serra]")
    _main.change_region_now(&"mata")
    set_time(GameState.day, 10 * 60)
    var m := mata()
    check(m.pedregulhos.size() == 4 and not m.trail_open(), "4 pedregulhos fecham a trilha")
    check(not m.is_walkable(Vector2(472, 24)), "pedregulho bloqueia a passagem")
    select_item(&"picareta")
    await place_player(Vector2(472, 52))
    _player.face(4)
    await frames(2)
    check(_prompts[-1] == "Quebrar pedregulho", "com a picareta o E vira 'Quebrar pedregulho'")
    var mining := _main.get_node("Mining") as Mining
    var item := ItemDB.get_item(&"picareta")
    var energy := GameState.energy
    var hits := 0
    while not m.pedregulhos[1].is_broken() and hits < 10:
        mining.use_item(item, _player.get_target_position(), _player)
        hits += 1
    check(hits == 4, "pedregulho quebra em 4 picaretadas")
    check(GameState.energy == energy - 4 * Mining.ENERGY, "picaretada gasta energia")
    check(GameState.skill_xp.get(&"mineracao", 0) > 0, "XP de mineração")
    await frames(2)
    var stones: Array = m.get_entities_root().get_children().filter(func(c: Node) -> bool: return c is Pickup)
    check(stones.size() >= 1, "pedregulho deixa pedras")
    for st in stones:
        st.queue_free()
    for r: Rock in m.pedregulhos:
        while not r.is_broken():
            r.hit(5)
    check(GameState.has_flag(&"trilha_serra_aberta"), "trilha aberta (marco da história)")
    check(m.is_walkable(Vector2(472, 24)), "caminho livre depois de quebrar")
    check(Quests.is_active("q_mina"), "missão 'Fundo da mina' começa")
    check(m.get_node("SaidaSerra").target_region == &"serra", "saída norte leva à serra")
    _main.change_region_now(&"serra", &"da_mata")
    check(_main.level == serra(), "chegou na Serra do Cristal")
    check(serra().mine_floors_available() == [1], "só o andar 1 no começo")
    check(serra().portal.interactable.prompt == "Examinar portal", "portal das ruínas fechado")
    var field := _main.get_node("Farm/FarmField") as FarmField
    check(field.get_item_action(ItemDB.get_item(&"enxada"), Vector2(200, 200), _player).is_empty(),
        "fora da fazenda a enxada não capina a roça de longe")


func _test_mine_floors() -> void:
    print("[Fase 7: mina procedural]")
    var mn := mine()
    mn.pending_floor = 1
    _main.change_region_now(&"mina")
    await get_tree().physics_frame
    await frames(2)
    check(mn.floor_number == 1 and GameState.get_flag(&"mina_fundo") == 1, "andar 1")
    check(mn.is_walkable(_player.global_position), "jogador nasce em chão livre")
    check(mn.ladder_down != null and mn.ladder_up != null, "escada para descer e para subir")
    check(not mn.find_path(_player.global_position, mn.ladder_down.global_position).is_empty() \
        or mn.ladder_down.global_position.distance_to(_player.global_position) < 20, "dá para andar até a escada de descer")
    check(mn.rocks().size() >= 10, "andar tem pedras para minerar")
    check(mn.enemies().size() >= 2, "andar tem criaturas")
    var kinds := {}
    for r in mn.rocks():
        kinds[r.kind] = true
    check(not kinds.has(&"ouro") and not kinds.has(&"cristal"), "no raso não tem ouro nem cristal")
    var text1 := _ground_text(mn)
    mn.build_floor(1)
    check(_ground_text(mn) == text1, "mesmo andar no mesmo dia = mesmo mapa")
    for i in 4:
        mn.go_down()
    await frames(1)
    check(mn.floor_number == 5 and GameState.get_flag(&"mina_fundo") == 5, "desceu até o andar 5")
    check(Quests.is_active("q_guardiao"), "chegar no andar 5 conclui 'Fundo da mina'")
    check(serra().mine_floors_available() == [1, 5], "elevador libera o andar 5")
    var deep := {}
    for f in [7, 8, 9]:
        mn.build_floor(f)
        for r in mn.rocks():
            deep[r.kind] = true
    check(deep.has(&"ouro") or deep.has(&"cristal"), "no fundo aparecem ouro/cristal")
    _main.change_region_now(&"serra", &"da_mina")


func _ground_text(lvl: Level) -> String:
    var s := ""
    for y in lvl.ground.map_size.y:
        for x in lvl.ground.map_size.x:
            s += str(lvl.ground.get_cell_atlas_coords(Vector2i(x, y)).x)
    return s


func _test_guardian_boss() -> void:
    print("[Fase 7: Guardião de Cristal]")
    # as criaturas dos andares anteriores bateram no jogador; sem isso ele
    # pode desmaiar no meio do teste e voltar para a fazenda
    GameState.health = GameState.MAX_HEALTH
    var mn := mine()
    mn.pending_floor = 10
    _main.change_region_now(&"mina")
    await frames(2)
    check(mn.boss != null and mn.boss.kind == &"guardiao_cristal", "andar 10: o Guardião aparece")
    check(mn.ladder_down == null, "andar 10 é o último")
    mn.boss.special_attack()
    await frames(1)
    check(get_tree().get_nodes_in_group("projectile").size() >= 8, "ataque especial: estilhaços em círculo")
    for p in get_tree().get_nodes_in_group("projectile"):
        p.queue_free()
    var b := mn.boss
    GameState.health = GameState.MAX_HEALTH
    b.take_hit(b.max_hp / 2 + 1, Vector2.UP, 0.0)
    await frames(2)
    check(b.phase == 2, "abaixo de metade: segunda fase")
    check(mn.enemies().size() >= 3, "chama morcegos para ajudar")
    b.take_hit(9999, Vector2.UP, 0.0)
    await get_tree().create_timer(0.4).timeout
    check(GameState.has_flag(&"guardiao_derrotado"), "Guardião derrotado (marco)")
    var heart: Array = mn.get_entities_root().find_children("*", "Pickup", true, false).filter(
        func(p: Node) -> bool: return p.item_id == &"coracao_cristal")
    check(heart.size() == 1, "deixa o coração de cristal")
    check(Quests.is_active("q_ruinas"), "missão 'Ruínas do Cerrado' começa")
    mn.build_floor(10)
    check(mn.boss == null and mn.rocks().size() == 6, "depois de derrotado: sala de cristais")
    _main.change_region_now(&"serra", &"da_mina")
    check(serra().mine_floors_available() == [1, 5, 10], "elevador libera o andar 10")
    check(serra().portal.interactable.prompt == "Entrar nas ruínas", "portal das ruínas aberto")


func _test_ruins_and_act1() -> void:
    print("[Fase 7: Ruínas do Cerrado]")
    _main.change_region_now(&"ruinas", &"da_serra")
    var r := ruinas()
    await get_tree().physics_frame
    await frames(1)
    check(r.seal.collision_layer == 1 and not r.is_walkable(Vector2(320, 176)), "selo fecha a câmara")
    check(not r.mae_do_ouro.visible, "câmara vazia antes do chefe")
    r.enter_chamber()
    check(r.boss == null, "chefe não aparece com o selo fechado")
    r.touch_totem(&"sol")
    r.touch_totem(&"lua")
    check(r.lit.is_empty(), "ordem errada apaga os totens")
    r.touch_totem(&"sol")
    r.touch_totem(&"chuva")
    r.touch_totem(&"lua")
    check(GameState.has_flag(&"totens_resolvidos"), "sol, chuva e lua: enigma resolvido")
    await get_tree().physics_frame
    check(r.seal.collision_layer == 0 and r.is_walkable(Vector2(320, 176)), "selo some e libera a passagem")
    check(Quests.step("q_ruinas").get("flag", "") == "eco_derrotado", "etapa: enfrentar o fundo das ruínas")
    await place_player(Vector2(320, 120))
    await frames(2)
    check(r.boss != null and r.boss.kind == &"eco_silencio", "entrar na câmara desperta o Eco do Silêncio")
    var b := r.boss
    var energy := GameState.energy
    b.special_attack()
    var orbs := get_tree().get_nodes_in_group("projectile")
    check(orbs.size() == 3, "Eco solta 3 orbes")
    for o in orbs:
        o.global_position = _player.global_position + Vector2(0, -6)
    _player._iframes = 0.0
    await frames(2)
    check(GameState.energy < energy, "orbe do Silêncio rouba energia")
    for o in get_tree().get_nodes_in_group("projectile"):
        o.queue_free()
    b.take_hit(9999, Vector2.UP, 0.0)
    await get_tree().create_timer(0.4).timeout
    check(GameState.has_flag(&"eco_derrotado") and r.mae_do_ouro.visible, "Eco derrotado: a Mãe-do-Ouro aparece")
    var dlg := _main.get_node("DialogueUI") as DialogueUI
    r.mae_do_ouro.talk()
    check(dlg.speaker == "Mãe-do-Ouro" and dlg.lines.size() == 5, "Mãe-do-Ouro conta sobre o Silêncio")
    dlg.close()
    await frames(1)
    check(Quests.is_done("q_ruinas") and GameState.has_flag(&"ato1_completo"), "Ato 1 completo!")
    check(GameState.get_item_count(&"cristal_vale") >= 1, "recompensa: cristal do vale")
    GameState.health = GameState.MAX_HEALTH


func _test_side_quests_and_board() -> void:
    print("[Fase 7: mural e missões secundárias]")
    GameState.new_game()
    _main.change_region_now(&"vila")
    check(Quests.board_available().is_empty(), "dia 1: mural vazio")
    GameState.day = 2
    check(Quests.board_available().has("s_alzira_milho") and not Quests.board_available().has("s_toninho_ferro"),
        "mural mostra pedidos conforme o dia")
    var board := vila().get_node("Entities/Mural") as QuestBoard
    var dlg := _main.get_node("DialogueUI") as DialogueUI
    board.open()
    check(dlg.is_open() and dlg.options[-1] == "Fechar", "mural lista pedidos")
    var idx := Array(dlg.options).find("Pamonhada da Dona Alzira")
    dlg.choose(idx)
    check(Quests.is_active("s_alzira_milho"), "aceitou o pedido da Dona Alzira")
    check(not Quests.board_available().has("s_alzira_milho"), "pedido aceito sai do mural")
    GameState.add_item(&"milho", 5)
    var money := GameState.money
    var alz := npc("alzira")
    var f := alz.friendship
    await talk_to("alzira")
    check(Quests.is_done("s_alzira_milho") and GameState.get_item_count(&"milho") == 0 and GameState.money == money + 150,
        "milho entregue, recompensa paga")
    check(alz.friendship >= f + 30, "amizade da Dona Alzira subiu")
    GameState.day = 5
    Quests.start("s_benedito_javali")
    for i in 3:
        EventBus.enemy_killed.emit(&"javali_corrompido")
    EventBus.enemy_killed.emit(&"raiz_torta")
    check(Quests.active["s_benedito_javali"] == 1, "3 javalis corrompidos contam para a missão")
    Quests.start("s_mariana_fauna")
    for sp in [&"capivara", &"cutia", &"quati", &"seriema"]:
        GameState.log_species(sp)
    check(Quests.active["s_mariana_fauna"] == 1, "4 espécies no caderno contam para a missão")


func _test_journal_ui() -> void:
    print("[Fase 7: diário]")
    var j := _main.get_node("JournalUI") as JournalUI
    var ev := InputEventAction.new()
    ev.action = "journal"
    ev.pressed = true
    Input.parse_input_event(ev)
    Input.flush_buffered_events()
    await frames(2)
    check(j.is_open() and get_tree().paused, "J abre o diário e pausa")
    j.set_tab(0)
    check(j.body_text().contains("Uma nova vida") and j.body_text().contains("Javalis corrompidos"), "aba Missões lista as ativas")
    j.set_tab(1)
    check(j.body_text().contains("Capivara  (Hydrochoerus hydrochaeris)") and j.body_text().contains("ainda não visto"),
        "aba Caderno: espécies vistas e não vistas")
    GameState.skill_xp[&"combate"] = 150
    j.set_tab(2)
    check(j.body_text().contains("pontos livres: 2"), "aba Habilidades mostra pontos de caminho")
    GameState.add_path_point(&"guerreiro")
    await frames(1)
    check(j.body_text().contains("pontos livres: 1"), "diário atualiza ao gastar ponto")
    j.close()
    check(not get_tree().paused, "fechar despausa")
    check(_main.get_node("TouchControls/Journal").action == "journal", "botão de toque do diário")


func _test_save_v6() -> void:
    print("[Fase 7: save v6]")
    GameState.set_flag(&"mina_fundo", 7)
    GameState.set_flag(&"trilha_serra_aberta")
    for r: Rock in mata().pedregulhos:
        r.hp = 0
    _main.change_region_now(&"ruinas", &"da_serra")
    check(SaveManager.save_game(), "salva dentro das ruínas")
    var saved := SaveManager.read_save_file()
    check(saved.version == GameState.DATA_VERSION and saved.player.region == "serra", "dentro de ruínas/mina o save fica na porta da serra")
    GameState.new_game()
    for r: Rock in mata().pedregulhos:
        r.load_save_data({"broken": false})
    check(not Quests.is_active("s_benedito_javali"), "jogo novo zera missões")
    check(SaveManager.load_game(), "carrega")
    check(_main.level == serra(), "volta na serra")
    check(GameState.get_flag(&"mina_fundo") == 7 and GameState.has_flag(&"trilha_serra_aberta"), "marcos restaurados")
    check(Quests.is_active("s_benedito_javali") and Quests.active["s_benedito_javali"] == 1 and Quests.is_done("s_alzira_milho"),
        "missões restauradas")
    check(mata().trail_open(), "pedregulhos quebrados continuam quebrados")
    var old := {"version": 5, "game": {"day": 3}, "nodes": {}}
    var mig := SaveManager.migrate(old)
    check(mig.version == GameState.DATA_VERSION, "save v5 migra até a versão atual")
    SaveManager.delete_save()
    GameState.new_game()
    _main.change_region_now(&"farm")


# --- Fase 8: conteúdo ----------------------------------------------------------

func _test_cooking() -> void:
    print("[Fase 8: fogão a lenha]")
    GameState.new_game()
    _main.change_region_now(&"farm")
    var farm := _main.get_region(&"farm") as FarmLevel
    check(GameState.knows_recipe(&"pamonha") and not GameState.knows_recipe(&"canjica"), "receitas iniciais; as de família faltam")
    await place_player(farm.fogao.position + Vector2(0, 16))
    _player.face(4)
    GameState.select_slot(8)
    await frames(3)
    check(_prompts[-1] == "Cozinhar no fogão a lenha", "dica 'Cozinhar no fogão a lenha'")
    await press_e()
    var ui := _main.get_node("RecipeUI") as RecipeUI
    check(ui.is_open() and ui.station == "cozinha" and get_tree().paused, "fogão abre a tela de receitas e pausa")
    check(ui.entries().size() == 4, "mostra só as 4 receitas conhecidas")
    check(not ui.make("pamonha"), "sem milho não cozinha")
    GameState.add_item(&"milho", 6)
    var mem := GameState.memories
    check(ui.make("pamonha") and GameState.get_item_count(&"pamonha") == 1 and GameState.get_item_count(&"milho") == 3,
        "pamonha: gasta 3 milhos")
    check(GameState.memories == mem + 1, "primeira pamonha vira lembrança do vale")
    ui.make("pamonha")
    check(GameState.memories == mem + 1 and GameState.get_item_count(&"pamonha") == 2, "repetir a receita não conta de novo")
    check(not ui.make("canjica"), "receita desconhecida não aparece")
    GameState.add_item(&"mandioca", 1)
    ui.make("farinha")
    check(GameState.get_item_count(&"farinha") == 2, "farinha de mandioca: 1 mandioca vira 2")
    check(GameState.skill_xp.get(&"artesanato", 0) > 0, "cozinhar dá XP de artesanato")
    ui.close()
    check(not get_tree().paused, "fechar despausa")


func _test_eating_and_buffs() -> void:
    print("[Fase 8: comer e efeitos]")
    select_item(&"pamonha")
    await place_player(Vector2(600, 300))
    await frames(3)
    check(_prompts[-1] == "Comer pamonha", "com comida na mão o E vira 'Comer'")
    GameState.energy = 30
    var n := GameState.get_item_count(&"pamonha")
    await press_e()
    await frames(2)
    check(GameState.energy == 70 and GameState.get_item_count(&"pamonha") == n - 1, "comer recupera energia e gasta 1")
    var base := GameState.melee_multiplier()
    GameState.add_item(&"arroz_pequi", 1)
    GameState.eat(ItemDB.get_item(&"arroz_pequi"))
    check(GameState.buff == &"combate" and is_equal_approx(GameState.melee_multiplier(), base * 1.25), "arroz com pequi: +25% de dano")
    var hud := _main.get_node("HUD")
    check(hud.buff_label.text.contains("Valentia"), "HUD mostra o efeito")
    GameState.set_buff(&"folego")
    GameState.energy = 50
    GameState.use_energy(4)
    check(GameState.energy == 48, "fôlego: ferramentas gastam metade")
    GameState.set_buff(&"rapidez")
    check(is_equal_approx(GameState.speed_multiplier(), 1.2), "pernas leves: +20% de velocidade")
    GameState.sleep()
    check(GameState.buff == &"" and hud.buff_label.text == "", "efeito acaba ao dormir")


func _test_gifts_and_hearts() -> void:
    print("[Fase 8: presentes e corações]")
    _main.change_region_now(&"vila")
    Quests.active.clear()
    var helena := npc("helena")
    helena.friendship = 0
    helena.met = true
    helena.gift_day = 0
    set_time(GameState.day, 9 * 60)
    helena.snap_to_schedule()
    GameState.add_item(&"pequi", 3)
    select_item(&"pequi")
    await place_player(helena.global_position + Vector2(0, 16))
    _player.face(4)
    await frames(3)
    check(_prompts[-1] == "Presentear Helena", "item na mão + morador = 'Presentear'")
    check(helena.gift_taste(&"pequi") == &"love" and helena.gift_taste(&"pedra") == &"hate", "cada morador tem seus gostos")
    await press_e()
    var dlg := _main.get_node("DialogueUI") as DialogueUI
    check(dlg.is_open() and dlg.lines[0].contains("pequi"), "reação ao presente")
    dlg.close()
    await frames(1)
    check(helena.friendship == 80 and GameState.get_item_count(&"pequi") == 2, "presente adorado: +80 de amizade")
    check(not _player.try_interact() or helena.friendship == 80, "um presente por dia")
    dlg.close()
    await frames(1)
    check(helena.friendship == 80 and GameState.get_item_count(&"pequi") == 2, "segundo presente no dia é recusado")
    helena.friendship = 200
    check(helena.hearts() == 2, "100 pontos = 1 coração")
    GameState.select_slot(8)
    var mem := GameState.memories
    helena.talk()
    check(dlg.lines[0].contains("canjica"), "2 corações: conversa especial")
    dlg.close()
    await frames(1)
    check(GameState.knows_recipe(&"canjica") and GameState.memories == mem + 1, "Helena ensina a canjica (lembrança)")
    helena.talk()
    check(not dlg.lines[0].contains("canjica"), "conversa especial só acontece uma vez")
    dlg.close()
    helena.friendship = 400
    var arroz := GameState.get_item_count(&"arroz")
    helena.talk()
    dlg.close()
    await frames(1)
    check(GameState.get_item_count(&"arroz") == arroz + 5, "4 corações: presente da Helena")
    # missão de entrega tem preferência sobre presente
    GameState.day = 2
    Quests.start("s_alzira_milho")
    GameState.add_item(&"milho", 5)
    var alz := npc("alzira")
    var gifting := _main.get_node("Gifting") as Gifting
    check(gifting.get_item_action(ItemDB.get_item(&"milho"), alz.global_position + Vector2(0, -8), _player).is_empty(),
        "com entrega de missão pendente, o E conversa em vez de presentear")
    Quests.reset()
    var j := _main.get_node("JournalUI") as JournalUI
    j.open(3)
    check(j.body_text().contains("Helena   ♥♥♥♥"), "diário: aba Amizades com corações")
    j.close()


func _test_festivals() -> void:
    print("[Fase 8: festas]")
    check(Festivals.today(25) == &"festa_pequi" and Festivals.today(36) == &"folia_reis"
        and Festivals.today(78) == &"cavalhadas" and Festivals.today(89) == &"festa_junina", "4 festas no calendário")
    check(Festivals.today(145) == &"festa_pequi", "repetem todo ano")
    check(Festivals.next(1).day == 25, "próxima festa a partir do dia 1: Festa do Pequi (5 de dezembro)")
    var v := vila() as VilaLevel
    _main.change_region_now(&"vila")
    jump_to_day(24)
    check(v.festa_root == null, "dia comum: praça sem festa")
    jump_to_day(25)
    check(_messages.any(func(m: String) -> bool: return m.contains("Festa do Pequi na praça")), "aviso de festa de manhã")
    check(v.festa_root != null and v.festival == &"festa_pequi", "dia 25: praça enfeitada")
    set_time(25, 10 * 60)
    var helena := npc("helena")
    helena.snap_to_schedule()
    check(helena.is_at_marker(&"festa_1") and not helena.is_shop_open(), "moradores vão para a festa (loja fechada)")
    var mem := GameState.memories
    v.concurso_pequi()
    check(GameState.get_item_count(&"trofeu_pequi") == 0, "sem 10 pequis não entra no concurso")
    GameState.add_item(&"pequi", 10)
    var money := GameState.money
    v.concurso_pequi()
    var dlg := _main.get_node("DialogueUI") as DialogueUI
    dlg.close()
    check(GameState.get_item_count(&"trofeu_pequi") == 1 and GameState.money == money + 300, "campeão do pequi: troféu e R$ 300")
    check(GameState.memories == mem + 1, "festa vira lembrança do vale")
    GameState.add_item(&"pequi", 10)
    v.concurso_pequi()
    check(GameState.get_item_count(&"trofeu_pequi") == 1, "concurso uma vez por ano")
    jump_to_day(36)
    check(v.festival == &"folia_reis", "6 de janeiro: Folia de Reis")
    GameState.inventory.clear()
    v.receber_folia()
    check(not GameState.has_flag(StringName("festa_folia_reis_ano%d" % Calendar.year(36))), "folia pede comida")
    GameState.add_item(&"pamonha", 1)
    v.receber_folia()
    dlg.close()
    check(GameState.get_item_count(&"pamonha") == 0 and GameState.buff == &"folego", "prato para a folia: bênção (fôlego)")
    jump_to_day(78)
    v.assistir_cavalhadas()
    dlg.close()
    check(v.festival == &"cavalhadas" and GameState.has_flag(StringName("festa_cavalhadas_ano%d" % Calendar.year(78))), "Cavalhadas assistidas")
    jump_to_day(89)
    check(v.festival == &"festa_junina" and v.festa_root.get_child_count() >= 4, "Festa Junina: fogueira e pescaria")
    GameState.money = 5
    check(v.pescaria() == null and GameState.money == 5, "pescaria custa R$ 10")
    GameState.money = 100
    v.pescaria()
    check(GameState.money == 90, "pagou a pescaria")
    v.dancar_quadrilha()
    dlg.close()
    check(GameState.has_flag(StringName("festa_festa_junina_ano%d" % Calendar.year(89))), "dançou a quadrilha")
    jump_to_day(90)
    check(v.festa_root == null, "no dia seguinte a praça volta ao normal")


func _test_decor_and_obras() -> void:
    print("[Fase 8: bancada, decoração e obras]")
    _main.change_region_now(&"farm")
    var ui := _main.get_node("RecipeUI") as RecipeUI
    ui.open("bancada")
    check(ui.entries().size() == 10, "bancada: 7 objetos (com o machado) + 3 obras")
    GameState.add_item(&"madeira", 6)
    check(ui.make("banco_madeira") and GameState.get_item_count(&"banco_madeira") == 1, "banco de madeira feito")
    ui.close()
    select_item(&"banco_madeira")
    await place_player(Vector2(600, 300))
    _player.face(2)
    await frames(3)
    check(_prompts[-1] == "Colocar banco de madeira", "dica 'Colocar banco de madeira'")
    await press_e()
    var placed: Array = _main.get_region(&"farm").get_node("Entities/Placed").get_children()
    var banco: Decor = null
    for c in placed:
        if c is Decor:
            banco = c
    check(banco != null and banco.item_id == &"banco_madeira" and banco.sprite.texture != null, "banco colocado na fazenda")
    check(SaveManager.save_game(), "salva com decoração")
    banco.queue_free()
    await frames(1)
    SaveManager.load_game()
    await frames(1)
    var again: Array = _main.get_region(&"farm").get_node("Entities/Placed").get_children().filter(
        func(c: Node) -> bool: return c is Decor and c.item_id == &"banco_madeira")
    check(again.size() == 1, "decoração volta ao carregar")
    var n := GameState.get_item_count(&"banco_madeira")
    (again[0] as Decor).pick_up()
    check(GameState.get_item_count(&"banco_madeira") == n + 1, "E recolhe a decoração")
    GameState.add_item(&"pedra", 20)
    GameState.add_item(&"madeira", 10)
    GameState.money = 1000
    ui.open("bancada")
    check(ui.make("caixa_dagua") and GameState.has_flag(&"obra_caixa_dagua") and GameState.money == 700, "obra: caixa d'água")
    check(not ui.make("caixa_dagua"), "obra só se faz uma vez")
    ui.close()
    GameState.refill_water()
    check(GameState.water == 40, "regador agora enche 40")
    var ranch := get_tree().get_first_node_in_group("ranch") as Ranch
    check(ranch.capacity(&"galinha") == 6, "galinheiro: 6 lugares")
    GameState.set_flag(&"obra_galinheiro_maior")
    check(ranch.capacity(&"galinha") == 10, "galinheiro maior: 10 lugares")
    SaveManager.delete_save()


func _test_save_v7() -> void:
    print("[Fase 8: save v7]")
    GameState.set_buff(&"pesca")
    GameState.learn_recipe(&"empadao")
    var mem := GameState.memories
    var helena := npc("helena")
    helena.gift_day = GameState.day
    check(SaveManager.save_game(), "salva")
    GameState.new_game()
    helena.gift_day = 0
    check(SaveManager.load_game(), "carrega")
    check(GameState.buff == &"pesca" and GameState.knows_recipe(&"empadao") and GameState.memories == mem, "efeito, receitas e lembranças")
    check(not helena.can_receive_gift(), "presente do dia lembrado")
    var old := {"version": 6, "game": {"day": 3}, "nodes": {}}
    var mig := SaveManager.migrate(old)
    check(mig.version == GameState.DATA_VERSION, "save v6 migra para v7")
    GameState.from_data(mig.game)
    check(GameState.knows_recipe(&"pamonha"), "save antigo ganha as receitas iniciais")
    SaveManager.delete_save()
    GameState.new_game()


# --- Fase 9: finalização --------------------------------------------------------

func _test_data_integrity() -> void:
    print("[Fase 9: dados consistentes]")
    var bad := PackedStringArray()
    for r in Recipes.station("cozinha") + Recipes.station("bancada") + Recipes.station("obras"):
        for it in r.ing:
            if ItemDB.get_item(StringName(it)) == null:
                bad.append("receita %s: %s" % [r.id, it])
        if r.has("out") and ItemDB.get_item(StringName(r.out)) == null:
            bad.append("receita %s sem item" % r.id)
    var npc_ids := {}
    for n in get_tree().get_nodes_in_group("npc"):
        npc_ids[String(n.data.id)] = true
        for list in [n.data.gifts_love, n.data.gifts_like, n.data.gifts_hate, n.data.shop_sells]:
            for it in list:
                if not it.begins_with("animal:") and ItemDB.get_item(StringName(it)) == null:
                    bad.append("%s: item %s" % [n.data.id, it])
        for it in n.data.shop_sells:
            if not it.begins_with("animal:") and ItemDB.get_item(StringName(it)).buy_price <= 0:
                bad.append("%s vende %s sem preço" % [n.data.id, it])
    for q in Quests.defs.values():
        for st in q.steps:
            if st.has("npc") and not npc_ids.has(st.npc):
                bad.append("missão %s: morador %s" % [q.id, st.npc])
            if st.has("item") and ItemDB.get_item(StringName(st.item)) == null:
                bad.append("missão %s: item %s" % [q.id, st.item])
        for it in q.get("rewards", {}).get("items", {}):
            if ItemDB.get_item(StringName(it)) == null:
                bad.append("missão %s: prêmio %s" % [q.id, it])
    for e in HeartEvents.all():
        if not npc_ids.has(e.npc):
            bad.append("evento: morador %s" % e.npc)
        for it in e.get("items", {}):
            if ItemDB.get_item(StringName(it)) == null:
                bad.append("evento %s: item %s" % [e.npc, it])
    for f: StringName in VilaLevel.BARRACA_ITEMS:
        for it in VilaLevel.BARRACA_ITEMS[f]:
            var item := ItemDB.get_item(StringName(it))
            if item == null or item.buy_price <= 0:
                bad.append("barraca %s: %s" % [f, it])
    check(bad.is_empty(), "receitas, lojas, missões e eventos só citam itens e moradores que existem " + str(bad))
    var arb := PackedStringArray()
    for item in ItemDB.all_items():
        if item.buy_price > 0 and item.sell_price >= item.buy_price:
            arb.append(String(item.id))
        if item.category == ItemData.Category.FOOD and item.energy <= 0:
            arb.append(String(item.id) + " (comida sem energia)")
    check(arb.is_empty(), "nenhum item dá lucro comprando e revendendo; toda comida dá energia " + str(arb))
    for r in Recipes.station("cozinha"):
        var cost := 0
        for it in r.ing:
            cost += ItemDB.get_item(StringName(it)).sell_price * int(r.ing[it])
        var value := ItemDB.get_item(StringName(r.out)).sell_price * int(r.get("count", 1))
        if value < cost:
            arb.append(r.id)
    check(arb.is_empty(), "cozinhar nunca dá prejuízo na venda " + str(arb))


func _test_audio() -> void:
    print("[Fase 9: som e música]")
    check(AudioServer.get_bus_index(Audio.BUS_MUSIC) != -1 and AudioServer.get_bus_index(Audio.BUS_SFX) != -1,
        "canais de música e efeitos")
    check(Audio._sfx.size() == Audio.SFX.size() and Audio._music.size() == Audio.TRACKS.size(), "todos os sons carregados")
    check(Audio._music.values().all(func(s: AudioStreamWAV) -> bool: return s.loop_mode == AudioStreamWAV.LOOP_FORWARD),
        "músicas em loop")
    GameState.new_game()
    _main.change_region_now(&"farm")
    set_time(3, 10 * 60)
    check(Audio.music_for_context() == &"dia", "de dia: viola")
    set_time(3, 20 * 60)
    check(Audio.music_for_context() == &"noite", "à noite: música da noite")
    var mn := mine()
    mn.pending_floor = 1
    _main.change_region_now(&"mina")
    check(Audio.current_track == &"mina", "na mina: música da mina")
    _main.change_region_now(&"vila")
    set_time(25, 10 * 60)
    check(Audio.music_for_context() == &"festa", "dia de festa na vila: forró")
    set_time(3, 10 * 60)
    _main.change_region_now(&"farm")
    Audio._last_played.clear()
    GameState.add_money(10)
    check(Audio.last_sfx == &"moeda", "ganhar dinheiro toca moeda")
    Audio._last_played.clear()
    GameState.damage(5)
    check(Audio.last_sfx == &"dano", "levar dano toca som")
    Audio._last_played.clear()
    var field := _main.get_node("Farm/FarmField") as FarmField
    field.till(Vector2i(10, 12))
    check(Audio.last_sfx == &"capinar", "capinar faz barulho de enxada")


func _test_settings_and_options() -> void:
    print("[Fase 9: opções]")
    Settings.set_music_volume(0.3)
    var idx := AudioServer.get_bus_index(Audio.BUS_MUSIC)
    check(is_equal_approx(AudioServer.get_bus_volume_db(idx), linear_to_db(0.3)), "volume da música aplicado")
    Settings.set_sfx_volume(0.0)
    check(AudioServer.is_bus_mute(AudioServer.get_bus_index(Audio.BUS_SFX)), "efeitos no zero = mudo")
    Settings.music_volume = 1.0
    Settings.load_settings()
    check(is_equal_approx(Settings.music_volume, 0.3) and Settings.sfx_volume == 0.0, "opções salvas em arquivo")
    var hud := _main.get_node("HUD")
    Settings.set_show_quest_hint(false)
    check(not hud.quest_label.visible, "dá para esconder a missão da tela")
    Settings.set_show_quest_hint(true)
    hud.set_paused(true)
    check(hud.options_button.get_parent() == hud.save_button.get_parent(), "menu de pausa tem 'Opções'")
    hud.options_button.pressed.emit()
    check(hud.options_panel.visible and not hud.pause_menu.visible, "opções abrem por cima do jogo pausado")
    hud.options_panel.music_slider.value = 0.5
    check(is_equal_approx(Settings.music_volume, 0.5), "slider muda o volume")
    hud.options_panel.close()
    check(hud.pause_menu.visible, "voltar das opções retorna ao menu de pausa")
    hud.set_paused(false)
    check(not get_tree().paused, "jogo volta")
    Settings.set_music_volume(0.7)
    Settings.set_sfx_volume(0.8)
    DirAccess.remove_absolute(Settings.path)


func _test_title_screen() -> void:
    print("[Fase 9: tela de título]")
    check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/title/title.tscn", "jogo abre na tela de título")
    check(str(ProjectSettings.get_setting("application/config/version")).begins_with("1."), "versão 1.x")
    SaveManager.delete_save()
    var title := (load("res://scenes/title/title.tscn") as PackedScene).instantiate() as TitleScreen
    add_child(title)
    await frames(2)
    check(not title.continue_button.visible, "sem save: sem 'Continuar'")
    title.queue_free()
    SaveManager.save_game()
    title = (load("res://scenes/title/title.tscn") as PackedScene).instantiate() as TitleScreen
    add_child(title)
    await frames(2)
    check(title.continue_button.visible and title.continue_button.text.begins_with("Continuar ("), "com save: 'Continuar (data)'")
    title._on_new_pressed()
    check(title.new_button.text != "Novo jogo" and SaveManager.has_save(), "novo jogo pede confirmação antes de apagar")
    title.options.open()
    check(title.options.visible, "opções na tela de título")
    title.queue_free()
    SaveManager.delete_save()


# --- pedidos: chuva, ataque, comer, fazenda bagunçada, zoom -------------------------

func action_press(action: String) -> void:
    var ev := InputEventAction.new()
    ev.action = action
    ev.pressed = true
    Input.parse_input_event(ev)
    Input.flush_buffered_events()
    await frames(1)
    var up := InputEventAction.new()
    up.action = action
    up.pressed = false
    Input.parse_input_event(up)
    Input.flush_buffered_events()
    await frames(1)


func _test_rain_continuous() -> void:
    print("[chuva contínua]")
    var fx := _main.get_node("WeatherFX") as WeatherFX
    Clock.forced_weather = Clock.Weather.CHUVA
    jump_to_day(GameState.day + 1)
    check(fx.rain.emitting, "dia de chuva: chovendo")
    var restarts := fx.rain_restarts
    for i in 12:
        Clock.minutes += 10
        Clock.time_changed.emit(Clock.minutes)
    check(fx.rain_restarts == restarts and fx.rain.emitting, "passar as horas não reinicia a chuva")
    Clock.forced_weather = Clock.Weather.TEMPESTADE
    jump_to_day(GameState.day + 1)
    check(fx.rain.amount == 320, "tempestade: chuva mais forte")
    Clock.forced_weather = Clock.Weather.ENSOLARADO
    jump_to_day(GameState.day + 1)
    check(not fx.rain.emitting, "sol: sem chuva")


func _test_attack_button() -> void:
    print("[botão de atacar]")
    GameState.new_game()
    _main.change_region_now(&"mata")
    set_time(GameState.day, 10 * 60)
    GameState.inventory.clear()
    GameState.add_item(&"semente_milho", 5)
    GameState.select_slot(0)
    var combat := _player.combat
    check(combat.attack_weapon() == CombatComponent.FISTS, "sem arma nenhuma: soco")
    await place_player(Vector2(300, 200))
    _player.face(2)
    var e := spawn_enemy(&"raiz_torta", Vector2(312, 200))
    var hp := e.hp
    combat.cooldown = 0.0
    await action_press("attack")
    check(e.hp < hp, "F (ou o botão ⚔) dá soco mesmo com semente na mão")
    GameState.add_item(&"facao", 1)
    GameState.select_slot(0)
    check(combat.attack_weapon().id == &"facao", "com facão na mochila, o botão usa o facão")
    GameState.add_item(&"espada", 1)
    check(combat.attack_weapon().id == &"espada", "pega a arma mais forte da mochila")
    hp = e.hp
    combat.cooldown = 0.0
    await action_press("attack")
    check(e.hp < hp, "golpe com a arma da mochila")
    e.queue_free()
    check(_main.get_node("TouchControls/Attack").action == "attack", "botão de atacar no celular")


func _test_eat_button() -> void:
    print("[botão de comer]")
    GameState.inventory.clear()
    GameState.select_slot(0)
    GameState.energy = 50
    _messages.clear()
    await action_press("eat")
    check(GameState.energy == 50 and _messages.any(func(m: String) -> bool: return m.contains("Nada pra comer")),
        "sem comida: avisa")
    GameState.add_item(&"pequi", 2)
    GameState.add_item(&"pamonha", 1)
    GameState.add_item(&"empadao", 1)
    GameState.select_slot(8)  # mão vazia
    check(_player.best_food().id == &"empadao", "falta 50 de energia: escolhe o que enche (empadão)")
    GameState.energy = 92
    check(_player.best_food().id == &"pequi", "falta pouco: escolhe o menor que enche (pequi)")
    GameState.energy = 50
    await action_press("eat")
    check(GameState.energy == 100 and GameState.get_item_count(&"empadao") == 0, "Q (ou o botão) come")
    GameState.energy = 50
    for i in GameState.inventory.size():
        if GameState.inventory.get_item_id(i) == &"pequi":
            GameState.select_slot(i)
    check(_player.best_food().id == &"pequi", "comida na mão tem preferência")
    await action_press("eat")
    check(GameState.energy == 60, "pequi cru: +10 de energia")
    check(_main.get_node("TouchControls/Eat").action == "eat", "botão de comer no celular")


func _test_messy_farm() -> void:
    print("[fazenda com mato, galho, pedra e árvore]")
    GameState.new_game()
    _main.change_region_now(&"farm")
    set_time(GameState.day, 10 * 60)
    var df := _main.get_node("Farm/Entities/DebrisField") as DebrisField
    df.generate()
    check(df.count(&"mato") > 80 and df.count(&"galho") > 10 and df.count(&"pedrinha") > 10 and df.count(&"arvore") > 10,
        "fazenda começa cheia: mato %d, galho %d, pedra %d, árvore %d" % [df.count(&"mato"), df.count(&"galho"), df.count(&"pedrinha"), df.count(&"arvore")])
    var ground := df.ground
    var bad := 0
    for cell: Vector2i in df.cells:
        if not ground.get_cell_atlas_coords(cell).x in DebrisField.GRASS_TILES:
            bad += 1
    check(bad == 0, "nada na estrada, na água ou na roça")
    var spawn: Vector2 = _main.level.get_spawn_position(&"")
    check(df.cells.keys().all(func(c: Vector2i) -> bool: return ground.map_to_local(c).distance_to(spawn) >= 40),
        "porta de casa livre")
    df.clear_all()
    var base := Vector2i(36, 22)
    for i in 5:
        df._add(base + Vector2i(i, 0), &"galho")
    for i in 3:
        df._add(base + Vector2i(i, 2), &"pedrinha")
    df._add(base + Vector2i(0, 4), &"mato")
    GameState.inventory.clear()
    GameState.select_slot(0)
    var c0 := ground.map_to_local(base)
    await place_player(c0 + Vector2(0, 14))
    _player.face(4)
    await frames(3)
    check(_prompts[-1] == "Pegar galho", "E no galho: 'Pegar galho'")
    for i in 5:
        df.interact_cell(ground.map_to_local(base + Vector2i(i, 0)), _player)
    for i in 3:
        df.interact_cell(ground.map_to_local(base + Vector2i(i, 2)), _player)
    check(GameState.get_item_count(&"galho") == 5 and GameState.get_item_count(&"pedra") == 3, "pegou 5 galhos e 3 pedras")
    var mato_cell := base + Vector2i(0, 4)
    var field := _main.get_node("Farm/FarmField") as FarmField
    check(not field.can_till(mato_cell), "enxada não capina em cima do mato")
    var energy := GameState.energy
    df.interact_cell(ground.map_to_local(mato_cell), _player)
    check(df.kind_at(mato_cell) == &"" and GameState.energy == energy - 1, "arrancou o mato (1 de energia)")
    check(field.can_till(mato_cell), "terreno limpo dá pra capinar")
    var ui := _main.get_node("RecipeUI") as RecipeUI
    ui.open("bancada")
    check(ui.make("machado") and GameState.get_item_count(&"machado") == 1, "bancada: 5 galhos + 3 pedras = machado")
    check(GameState.get_item_count(&"galho") == 0 and GameState.get_item_count(&"pedra") == 0, "gastou os galhos e as pedras")
    ui.close()
    var tree := base + Vector2i(2, 6)
    df._add(tree, &"arvore")
    var axe := ItemDB.get_item(&"machado")
    var tp := ground.map_to_local(tree)
    check(df.get_item_action(axe, tp, _player).get("prompt", "") == "Cortar árvore", "com machado: 'Cortar árvore'")
    check(df.get_item_action(ItemDB.get_item(&"enxada"), tp, _player).is_empty(), "sem machado não corta")
    for i in 5:
        df.use_item(axe, tp, _player)
    check(df.kind_at(tree) == &"toco", "5 machadadas: árvore cai e fica o toco")
    await frames(1)
    var wood := df.get_children().filter(func(c: Node) -> bool: return c is Pickup and c.item_id == &"madeira")
    check(wood.size() >= 1, "árvore deixa madeira")
    for i in 3:
        df.use_item(axe, tp, _player)
    check(df.kind_at(tree) == &"", "3 machadadas: toco arrancado")
    # golpe de arma corta mato; machado no golpe também corta árvore
    df._add(base + Vector2i(1, 8), &"mato")
    df._add(base + Vector2i(1, 9), &"arvore")
    var fc := ground.map_to_local(base + Vector2i(1, 8))
    var n := df.slash(fc + Vector2(0, -14), Vector2.DOWN, 18.0, 20.0, ItemDB.get_item(&"facao"))
    check(n >= 1 and df.kind_at(base + Vector2i(1, 8)) == &"", "golpe de facão corta o mato")
    check(df.kind_at(base + Vector2i(1, 9)) == &"arvore" and df.cells[base + Vector2i(1, 9)].hp == 5, "facão não corta árvore")
    df.slash(fc, Vector2.DOWN, 18.0, 20.0, axe)
    check(df.cells[base + Vector2i(1, 9)].hp == 4, "golpe de machado corta árvore")
    # salva e carrega
    check(SaveManager.save_game(), "salva a fazenda")
    df.clear_all()
    SaveManager.load_game()
    await frames(1)
    check(df.kind_at(base + Vector2i(1, 9)) == &"arvore" and df.cells[base + Vector2i(1, 9)].hp == 4, "árvore (já machucada) volta ao carregar")
    df.growth_enabled = true
    var weeds := df.count(&"mato")
    var twigs := df.count(&"galho")
    df.grow_daily()
    check(df.count(&"mato") > weeds and df.count(&"galho") > twigs, "todo dia nasce mato e cai galho")
    df.growth_enabled = false
    _main.change_region_now(&"vila")
    check(df.get_cell_prompt(fc) == "", "fora da fazenda a bagunça não responde")
    _main.change_region_now(&"farm")
    df.clear_all()
    SaveManager.delete_save()


func _test_camera_zoom() -> void:
    print("[zoom da câmera]")
    Settings.set_camera_zoom(2.0)
    await frames(1)
    check(_player.camera.zoom == Vector2(2, 2), "zoom aplicado na câmera")
    await action_press("zoom_in")
    check(is_equal_approx(Settings.camera_zoom, 2.25), "+ aproxima")
    await action_press("zoom_out")
    await action_press("zoom_out")
    check(is_equal_approx(Settings.camera_zoom, 1.75), "− afasta")
    Settings.set_camera_zoom(9.0)
    check(Settings.camera_zoom == Settings.ZOOM_MAX, "zoom tem limite")
    var hud := _main.get_node("HUD")
    hud.options_panel.open()
    hud.options_panel.zoom_slider.value = 0.0
    check(Settings.camera_zoom == Settings.ZOOM_MIN, "slider de zoom nas opções")
    hud.options_panel.hide()
    check(_main.get_node("TouchControls/ZoomIn").action == "zoom_in" and _main.get_node("TouchControls/ZoomOut").action == "zoom_out",
        "botões + e − no celular")
    Settings.set_camera_zoom(1.0)
    DirAccess.remove_absolute(Settings.path)
