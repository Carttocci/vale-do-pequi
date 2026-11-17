extends Node2D
## Cena principal: carrega a região atual e coloca o jogador nela.
##
## O jogador não fica "dentro" do .tscn da fazenda de propósito: quando
## existirem várias regiões (vila, mata, rio), a troca de região só
## move o mesmo jogador de um nível para outro.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

@onready var level: FarmLevel = $Farm

var player: Player


func _ready() -> void:
    _configure_scaling()
    player = PLAYER_SCENE.instantiate() as Player
    player.position = level.get_spawn_position()
    level.get_entities_root().add_child(player)
    player.set_camera_limits(level.get_world_rect())
    if SaveManager.has_save() and SaveManager.load_game():
        EventBus.show_message("Bem-vindo de volta! Dia %d." % GameState.day, 3.0)
    else:
        EventBus.show_message("Fazenda do Pequi. Pegue a enxada e bora capinar a roça!", 3.5)


## Desktop: escala inteira (pixel perfeito, pode sobrar borda).
## Celular: escala fracionária para ocupar a tela toda — telas de celular
## raramente são múltiplos exatos de 640x360 e a borda preta fica enorme.
func _configure_scaling() -> void:
    var is_mobile := OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
    if is_mobile:
        get_tree().root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_fullscreen"):
        var mode := DisplayServer.window_get_mode()
        if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        else:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        get_viewport().set_input_as_handled()
