extends Node2D
## Cena principal: guarda as regiões, cria o jogador e faz a troca de região.
##
## Todas as regiões ficam carregadas como filhas desta cena (Farm, Vila...);
## só a atual fica ativa (Level.set_active). O jogador é o mesmo nó, movido
## de uma região para outra.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const FADE_TIME := 0.25

## Região atual.
var level: Level
var player: Player
var regions: Dictionary = {}

var _changing := false
var _fade: ColorRect


func _ready() -> void:
    _configure_scaling()
    Clock.passed_out.connect(_on_passed_out)
    GameState.fainted.connect(_on_fainted)
    EventBus.region_change_requested.connect(change_region)
    _build_fade()
    for child in get_children():
        if child is Level:
            regions[child.region_id] = child
            child.set_active(false)
    level = regions[&"farm"]
    level.set_active(true)
    player = PLAYER_SCENE.instantiate() as Player
    player.position = level.get_spawn_position()
    level.get_entities_root().add_child(player)
    player.set_camera_limits(level.get_world_rect())
    if SaveManager.has_save() and SaveManager.load_game():
        EventBus.show_message("Bem-vindo de volta! %s." % Calendar.format_date(GameState.day), 3.0)
    else:
        EventBus.show_message("Fazenda do Pequi. Pegue a enxada e bora capinar a roça!", 3.5)


func get_region(id: StringName) -> Level:
    return regions.get(id)


## Troca de região com escurecida rápida (usado pelas saídas do mapa).
func change_region(id: StringName, spawn: StringName = &"") -> void:
    if _changing or not regions.has(id) or (level and level.region_id == id):
        return
    _changing = true
    player.input_enabled = false
    var t := create_tween()
    t.tween_property(_fade, "color:a", 1.0, FADE_TIME)
    await t.finished
    change_region_now(id, spawn)
    var t2 := create_tween()
    t2.tween_property(_fade, "color:a", 0.0, FADE_TIME)
    await t2.finished
    player.input_enabled = true
    _changing = false


## Troca imediata (carregar save, apagar de cansaço, testes).
func change_region_now(id: StringName, spawn: StringName = &"") -> void:
    var target: Level = regions.get(id)
    if target == null:
        push_warning("Região desconhecida: %s" % id)
        return
    if target != level:
        player.get_parent().remove_child(player)
        level.set_active(false)
        level = target
        level.get_entities_root().add_child(player)
        level.set_active(true)
    player.global_position = level.get_spawn_position(spawn)
    player.velocity = Vector2.ZERO
    player.set_camera_limits(level.get_world_rect(), level.indoor)
    EventBus.show_message(level.display_name, 2.0)
    EventBus.region_entered.emit(level.region_id)


## Desktop: escala inteira (pixel perfeito, pode sobrar borda).
## Celular: escala fracionária para ocupar a tela toda — telas de celular
## raramente são múltiplos exatos de 640x360 e a borda preta fica enorme.
func _configure_scaling() -> void:
    var is_mobile := OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
    if is_mobile:
        get_tree().root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_fullscreen"):
        Settings.toggle_fullscreen()
        get_viewport().set_input_as_handled()


## 02:00: o jogador apaga de cansaço e acorda em casa no dia seguinte.
func _on_passed_out() -> void:
    GameState.sleep()
    _wake_at_home()
    SaveManager.save_game()
    EventBus.show_message("Você apagou de cansaço e acordou em casa. %s." % Calendar.format_date(GameState.day), 4.0)


## Vida zerou: desmaia, acorda em casa no dia seguinte e perde um pouco de dinheiro.
func _on_fainted() -> void:
    var lost := mini(GameState.money / 10, 100)
    GameState.money -= lost
    GameState.money_changed.emit(GameState.money)
    GameState.sleep()
    _wake_at_home()
    SaveManager.save_game()
    EventBus.show_message("Você desmaiou... Alguém te levou pra casa. (-R$ %d)" % lost, 4.0)


## Acorda na cama, dentro de casa (ou na porta da fazenda, se não tiver casa).
func _wake_at_home() -> void:
    if regions.has(&"casa"):
        change_region_now(&"casa", &"cama")
    else:
        change_region_now(&"farm")


func _build_fade() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 10
    layer.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(layer)
    _fade = ColorRect.new()
    _fade.color = Color(0.08, 0.06, 0.05, 0.0)
    _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fade.set_anchors_preset(Control.PRESET_FULL_RECT)
    layer.add_child(_fade)
