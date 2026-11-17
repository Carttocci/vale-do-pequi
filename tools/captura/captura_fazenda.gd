extends Node
## Ferramenta de dev: print da fazenda bagunçada (mato, galhos, pedras, árvores) com zoom.

func _ready() -> void:
    SaveManager.save_path = "user://captura_save.json"
    SaveManager.delete_save()
    GameState.new_game()
    Clock.running = false
    Clock.forced_weather = Clock.Weather.CHUVA
    var main: Node = load("res://scenes/main/main.tscn").instantiate()
    add_child(main)
    DirAccess.make_dir_recursive_absolute("user://capturas")
    for i in 6:
        await get_tree().process_frame
    Clock.minutes = 10 * 60
    Clock.start_day(GameState.day)
    var player: Player = main.get("player")
    player.global_position = Vector2(560, 260)
    player.camera.reset_smoothing()
    Settings.camera_zoom = 1.0
    Settings.apply()
    for i in 10:
        await get_tree().process_frame
    get_viewport().get_texture().get_image().save_png("user://capturas/fazenda_baguncada.png")
    Settings.camera_zoom = 1.75
    Settings.apply()
    player.camera.reset_smoothing()
    for i in 10:
        await get_tree().process_frame
    get_viewport().get_texture().get_image().save_png("user://capturas/fazenda_zoom.png")
    get_tree().quit()
