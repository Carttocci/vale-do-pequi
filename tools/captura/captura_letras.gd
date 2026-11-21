extends Node
## Prints do HUD e da conversa em cada tamanho de letra (Opções → Letra).

func _ready() -> void:
    SaveManager.save_path = "user://captura_save.json"
    SaveManager.delete_save()
    Quests.skip_tutorial = false
    GameState.new_game()
    Quests.reset()
    var main: Node = load("res://scenes/main/main.tscn").instantiate()
    add_child(main)
    DirAccess.make_dir_recursive_absolute("user://capturas")
    Clock.running = false
    await _frames(10)
    var player: Player = main.get("player")
    main.change_region_now(&"vila")
    player.global_position = main.level.get_spawn_position()
    player.camera.reset_smoothing()
    EventBus.show_message("Vila de Santa Pequiria", 30.0)
    EventBus.dialogue_requested.emit("Helena", PackedStringArray(["Opa! Você que é da família lá da Fazenda do Pequi? A vila inteira tá comentando."]), PackedStringArray(), Callable())
    for s in [10, 12, 14, 16, 20]:
        Settings.set_text_size(s)
        await _frames(10)
        get_viewport().get_texture().get_image().save_png("user://capturas/letra_%d.png" % s)
    Settings.set_text_size(20)
    get_tree().quit()


func _frames(n: int) -> void:
    for i in n:
        await get_tree().process_frame
