extends Node
## Ferramenta de dev: abre o jogo, posiciona o jogador e salva prints em user://capturas/.
## Uso: godot --path . res://tools/captura/captura.tscn

const SHOTS := [
    {"name": "casa", "pos": Vector2(464, 150), "dir": 0},
    {"name": "pomar", "pos": Vector2(700, 200), "dir": 4},
    {"name": "lagoa", "pos": Vector2(220, 380), "dir": 6},
]

func _ready() -> void:
    var main: Node = load("res://scenes/main/main.tscn").instantiate()
    add_child(main)
    DirAccess.make_dir_recursive_absolute("user://capturas")
    var player: Player = main.get("player")
    for shot in SHOTS:
        player.global_position = shot.pos
        player.face(shot.dir)
        player.camera.reset_smoothing()
        for i in 30:
            await get_tree().process_frame
        if shot.name == "pomar":
            player.try_interact()
            await get_tree().create_timer(0.3).timeout
        var img := get_viewport().get_texture().get_image()
        var path := "user://capturas/%s.png" % shot.name
        img.save_png(path)
        print("salvo: ", ProjectSettings.globalize_path(path))
    get_tree().quit()
