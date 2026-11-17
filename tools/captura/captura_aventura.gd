extends Node
## Ferramenta de dev: prints da Fase 7 (serra, mina, chefe, ruínas, diário).
## Uso: godot --path . res://tools/captura/captura_aventura.tscn

func _ready() -> void:
    SaveManager.save_path = "user://captura_save.json"
    SaveManager.delete_save()
    GameState.new_game()
    Clock.running = false
    Clock.minutes = 11 * 60
    var main: Node = load("res://scenes/main/main.tscn").instantiate()
    add_child(main)
    DirAccess.make_dir_recursive_absolute("user://capturas")
    await _frames(5)
    var player: Player = main.get("player")
    main.change_region_now(&"mata")
    player.global_position = Vector2(472, 70)
    player.face(4)
    player.camera.reset_smoothing()
    await _frames(10)
    _shot("trilha_serra")
    main.change_region_now(&"serra", &"da_mata")
    player.global_position = Vector2(320, 140)
    player.camera.reset_smoothing()
    await _frames(10)
    _shot("serra")
    var mine: MineLevel = main.get_region(&"mina")
    mine.pending_floor = 3
    main.change_region_now(&"mina")
    player.camera.reset_smoothing()
    await _frames(10)
    _shot("mina_andar3")
    mine.pending_floor = 10
    main.change_region_now(&"mina")
    player.global_position = Vector2(320, 220)
    player.camera.reset_smoothing()
    await _frames(40)
    _shot("guardiao")
    GameState.set_flag(&"guardiao_derrotado")
    main.change_region_now(&"ruinas", &"da_serra")
    player.global_position = Vector2(320, 260)
    player.face(4)
    player.camera.reset_smoothing()
    await _frames(10)
    _shot("ruinas")
    var j: JournalUI = main.get_node("JournalUI")
    j.open(0)
    await _frames(5)
    _shot("diario")
    get_tree().quit()


func _frames(n: int) -> void:
    for i in n:
        await get_tree().process_frame


func _shot(name: String) -> void:
    var path := "user://capturas/%s.png" % name
    get_viewport().get_texture().get_image().save_png(path)
    print("salvo: ", ProjectSettings.globalize_path(path))
