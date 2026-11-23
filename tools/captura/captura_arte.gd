extends Node
## Ferramenta de dev: prints da arte nova (chão, personagens, casas, interiores).
## Uso: godot --path . res://tools/captura/captura_arte.tscn  (salva em user://capturas/)

const SHOTS := [
    ["farm", Vector2(464, 190), "fazenda_casa"],
    ["farm", Vector2(170, 380), "fazenda_lagoa"],
    ["farm", Vector2(720, 230), "fazenda_pequizal"],
    ["vila", Vector2(420, 260), "vila_praca"],
    ["vila", Vector2(180, 330), "vila_oeste"],
    ["vila", Vector2(600, 420), "vila_bar"],
    ["mata", Vector2(480, 300), "mata"],
    ["serra", Vector2(320, 200), "serra"],
]


func _ready() -> void:
    SaveManager.save_path = "user://captura_save.json"
    SaveManager.delete_save()
    Clock.running = false
    Clock.forced_weather = Clock.Weather.ENSOLARADO
    Clock.minutes = 10 * 60
    GameState.new_game()
    Dog.active = false
    var main: Node = load("res://scenes/main/main.tscn").instantiate()
    add_child(main)
    DirAccess.make_dir_recursive_absolute("user://capturas")
    await _frames(5)
    var player: Player = main.get("player")
    Settings.camera_zoom = 2.0
    player.apply_camera_zoom()
    var only := OS.get_environment("SO")
    for s in SHOTS:
        if only != "" and not String(s[2]).begins_with(only):
            continue
        main.change_region_now(StringName(s[0]))
        player.global_position = s[1]
        player.face(0)
        player.camera.reset_smoothing()
        await _frames(12)
        _shot(s[2])
    for id in ["casa", "casa_helena", "casa_alzira", "casa_toninho", "casa_mariana"]:
        if only != "" and not id.begins_with(only):
            continue
        if main.get_region(StringName(id)) == null:
            continue
        main.change_region_now(StringName(id))
        player.face(4)
        player.camera.reset_smoothing()
        await _frames(12)
        _shot("interior_" + id)
    get_tree().quit()


func _shot(name: String) -> void:
    var img := get_viewport().get_texture().get_image()
    img.save_png("user://capturas/%s.png" % name)
    print("captura: ", name)


func _frames(n: int) -> void:
    for i in n:
        await get_tree().process_frame
