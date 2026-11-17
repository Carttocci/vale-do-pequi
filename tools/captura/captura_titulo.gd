extends Node
## Ferramenta de dev: print da tela de título e do menu de opções.

func _ready() -> void:
    SaveManager.save_path = "user://captura_save.json"
    GameState.new_game()
    SaveManager.save_game()
    var t: Node = load("res://scenes/title/title.tscn").instantiate()
    add_child(t)
    for i in 10:
        await get_tree().process_frame
    get_viewport().get_texture().get_image().save_png("user://capturas/titulo.png")
    t.options.open()
    for i in 5:
        await get_tree().process_frame
    get_viewport().get_texture().get_image().save_png("user://capturas/opcoes.png")
    SaveManager.delete_save()
    get_tree().quit()
