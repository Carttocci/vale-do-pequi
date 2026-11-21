extends Node
## Prints da criação, estações, mapa, luzes e '!'. Uso:
## godot --path . res://tools/captura/captura_criacao.tscn

func _ready() -> void:
    SaveManager.save_path = "user://captura_save.json"
    SaveManager.delete_save()
    Quests.skip_tutorial = true
    GameState.new_game()
    Quests.reset()
    var main: Node = load("res://scenes/main/main.tscn").instantiate()
    add_child(main)
    DirAccess.make_dir_recursive_absolute("user://capturas")
    Clock.running = false
    await _frames(5)
    var player: Player = main.get("player")
    var ranch := get_tree().get_first_node_in_group("ranch") as Ranch
    ranch.raids_enabled = false
    for k in [&"galinha", &"galinha", &"pintinho", &"vaca", &"bezerro", &"touro"]:
        ranch.add_animal(k)
    ranch.water = {&"galinheiro": 10, &"curral": 10}
    ranch.feed = {&"galinheiro": 10, &"curral": 10}
    ranch.toggle_gate(&"galinheiro")
    ranch._update_props()
    player.global_position = Vector2(700, 160)
    player.camera.reset_smoothing()
    await _frames(30)
    _shot("criacao")
    var wfx: WeatherFX = main.get_node("WeatherFX")
    Clock.minutes = 22 * 60
    Clock.time_changed.emit(Clock.minutes)
    wfx.refresh()
    await _frames(30)
    _shot("criacao_noite")
    GameState.day = Calendar.day_of(7, 1, 2)
    Clock.minutes = 10 * 60
    Clock.time_changed.emit(Clock.minutes)
    wfx.refresh()
    player.global_position = Vector2(400, 260)
    player.camera.reset_smoothing()
    await _frames(60)
    _shot("seca_ipe")
    GameState.day = 1
    Clock.minutes = 10 * 60
    wfx.refresh()
    var map: MapUI = main.get_node("MapUI")
    map.open()
    await _frames(10)
    _shot("mapa")
    map.close()
    main.change_region_now(&"vila")
    player.global_position = main.level.get_spawn_position()
    player.camera.reset_smoothing()
    await _frames(40)
    _shot("vila_missao")
    var e := Enemy.new().setup(&"raiz_torta", player.global_position + Vector2(40, 0), main.level)
    main.level.get_entities_root().add_child(e)
    e.set_process(false)
    e.take_hit(12, Vector2.RIGHT, 0.0)
    var b := Enemy.new().setup(&"guardiao_cristal", player.global_position + Vector2(-60, 10), main.level)
    main.level.get_entities_root().add_child(b)
    b.set_process(false)
    b.hp = 150
    await _frames(10)
    _shot("barras_vida")
    get_tree().quit()


func _frames(n: int) -> void:
    for i in n:
        await get_tree().process_frame


func _shot(name: String) -> void:
    var path := "user://capturas/%s.png" % name
    get_viewport().get_texture().get_image().save_png(path)
    print("salvo: ", ProjectSettings.globalize_path(path))
