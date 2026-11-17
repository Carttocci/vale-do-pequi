extends Node
## Ferramenta de dev: abre o jogo, monta algumas cenas e salva prints em
## user://capturas/. Uso: godot --path . res://tools/captura/captura.tscn

func _ready() -> void:
    SaveManager.save_path = "user://captura_save.json"
    SaveManager.delete_save()
    GameState.new_game()
    var main: Node = load("res://scenes/main/main.tscn").instantiate()
    add_child(main)
    DirAccess.make_dir_recursive_absolute("user://capturas")
    await _frames(5)
    var player: Player = main.get("player")
    var field: FarmField = main.get_node("Farm/FarmField")
    # Roça com plantas em vários estágios
    var crops := [&"milho", &"feijao", &"abobora", &"mandioca"]
    for x in range(7, 17):
        for y in range(10, 16):
            var cell := Vector2i(x, y)
            field.till(cell)
            if y < 15:
                var crop: StringName = crops[(x - 7) % 4]
                field.plant(cell, crop)
                field.cells[cell].age = (y - 10) * 2
                field.cells[cell].watered = (x + y) % 2 == 0
                field._refresh(cell)
    player.global_position = Vector2(200, 268)
    player.face(4)
    player.camera.reset_smoothing()
    GameState.select_slot(0)
    await _frames(20)
    _shot("roca")
    var ui: InventoryUI = main.get_node("InventoryUI")
    ui.open_inventory()
    await _frames(5)
    _shot("mochila")
    ui.close()
    ui.open_chest(main.get_node("Farm/Entities/BauDoAvo"))
    await _frames(5)
    _shot("bau")
    ui.close()
    # Fase 3: horários e climas
    Clock.running = false
    var wfx: WeatherFX = main.get_node("WeatherFX")
    for cfg in [["tarde", 18 * 60 + 30, Clock.Weather.ENSOLARADO], ["noite", 23 * 60, Clock.Weather.ENSOLARADO],
            ["chuva", 12 * 60, Clock.Weather.CHUVA], ["neblina", 6 * 60 + 30, Clock.Weather.NEBLINA]]:
        Clock.minutes = cfg[1]
        Clock.weather = cfg[2]
        wfx.refresh()
        main.get_node("HUD").update_clock()
        await _frames(30)
        _shot(cfg[0])
    Clock.minutes = 9 * 60
    Clock.weather = Clock.Weather.ENSOLARADO
    wfx.refresh()
    # Fase 4: vila com moradores, conversa e loja
    main.change_region_now(&"vila")
    GameState.day = 2
    Clock.minutes = 10 * 60
    Clock.time_changed.emit(Clock.minutes)
    for n in get_tree().get_nodes_in_group("npc"):
        n.snap_to_schedule()
    player.global_position = Vector2(560, 330)
    player.camera.reset_smoothing()
    await _frames(20)
    _shot("vila")
    var helena: Npc = null
    for n in get_tree().get_nodes_in_group("npc"):
        if n.data.id == &"helena":
            helena = n
    player.global_position = helena.global_position + Vector2(0, 16)
    player.face(4)
    player.camera.reset_smoothing()
    await _frames(10)
    helena.talk()
    await _frames(5)
    _shot("conversa")
    main.get_node("DialogueUI").choose(0)
    await _frames(5)
    _shot("loja")
    main.get_node("ShopUI").close()
    main.change_region_now(&"farm")
    var tc: TouchControls = main.get_node("TouchControls")
    tc.set_touch_mode(true)
    await _frames(10)
    _shot("roca_toque")
    SaveManager.delete_save()
    get_tree().quit()


func _frames(n: int) -> void:
    for i in n:
        await get_tree().process_frame


func _shot(name: String) -> void:
    var path := "user://capturas/%s.png" % name
    get_viewport().get_texture().get_image().save_png(path)
    print("salvo: ", ProjectSettings.globalize_path(path))
