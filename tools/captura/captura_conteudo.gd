extends Node
## Ferramenta de dev: prints da Fase 8 (fogão, bancada, festas, receitas, amizades).
## Uso: godot --path . res://tools/captura/captura_conteudo.tscn

func _ready() -> void:
    SaveManager.save_path = "user://captura_save.json"
    SaveManager.delete_save()
    GameState.new_game()
    Clock.running = false
    var main: Node = load("res://scenes/main/main.tscn").instantiate()
    add_child(main)
    DirAccess.make_dir_recursive_absolute("user://capturas")
    await _frames(5)
    Clock.minutes = 11 * 60
    var player: Player = main.get("player")
    for it in ["milho", "leite", "acucar", "pequi", "arroz", "madeira", "pedra"]:
        GameState.add_item(StringName(it), 10)
    GameState.add_item(&"lampiao", 1)
    player.global_position = Vector2(470, 175)
    player.face(4)
    player.camera.reset_smoothing()
    await _frames(10)
    _shot("fazenda_fogao_bancada")
    var ui: RecipeUI = main.get_node("RecipeUI")
    ui.open("cozinha")
    await _frames(5)
    _shot("receitas")
    ui.close()
    GameState.day = Calendar.day_of(11, 5)
    Clock.minutes = 11 * 60
    main.change_region_now(&"vila")
    for n in get_tree().get_nodes_in_group("npc"):
        n.met = true
        n.snap_to_schedule()
    player.global_position = Vector2(416, 380)
    player.face(4)
    player.camera.reset_smoothing()
    await _frames(10)
    _shot("festa_pequi")
    GameState.day = Calendar.day_of(5, 24, 2)
    main.get_region(&"vila").refresh_festival()
    Clock.minutes = 19 * 60
    Clock.time_changed.emit(Clock.minutes)
    for n in get_tree().get_nodes_in_group("npc"):
        n.snap_to_schedule()
    await _frames(10)
    _shot("festa_junina")
    for n in get_tree().get_nodes_in_group("npc"):
        n.friendship = 230
    var j: JournalUI = main.get_node("JournalUI")
    j.open(3)
    await _frames(5)
    _shot("amizades")
    get_tree().quit()


func _frames(n: int) -> void:
    for i in n:
        await get_tree().process_frame


func _shot(name: String) -> void:
    var path := "user://capturas/%s.png" % name
    get_viewport().get_texture().get_image().save_png(path)
    print("salvo: ", ProjectSettings.globalize_path(path))
