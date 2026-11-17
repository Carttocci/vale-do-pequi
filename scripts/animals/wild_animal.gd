class_name WildAnimal
extends Node2D
## Bicho do Cerrado na mata: anda perto de casa, foge se o jogador chegar
## perto demais e pode ser OBSERVADO (registra no caderno de campo).
## Só o javali (espécie invasora) pode ser caçado — ver GDD §9.

const SPECIES := {
    &"capivara": {"name": "Capivara", "sci": "Hydrochoerus hydrochaeris", "w": 24, "speed": 14.0, "flee": 26.0},
    &"cutia": {"name": "Cutia", "sci": "Dasyprocta azarae", "w": 16, "speed": 24.0, "flee": 34.0},
    &"quati": {"name": "Quati", "sci": "Nasua nasua", "w": 20, "speed": 22.0, "flee": 30.0},
    &"seriema": {"name": "Seriema", "sci": "Cariama cristata", "w": 16, "speed": 26.0, "flee": 36.0},
    &"ema": {"name": "Ema", "sci": "Rhea americana", "w": 24, "speed": 30.0, "flee": 40.0},
    &"veado": {"name": "Veado-campeiro", "sci": "Ozotoceros bezoarticus", "w": 24, "speed": 30.0, "flee": 44.0},
    &"javali": {"name": "Javali (invasor)", "sci": "Sus scrofa", "w": 24, "speed": 18.0, "flee": 30.0},
}

var species: StringName
var home := Vector2.ZERO
var level: Level

var _target := Vector2.ZERO
var _wait := 0.0
var _flee := 0.0
var _anim := 0.0
var _rng := RandomNumberGenerator.new()
var sprite: Sprite2D
var interactable: Interactable


func setup(sp: StringName, at: Vector2, lvl: Level) -> WildAnimal:
    species = sp
    home = at
    level = lvl
    position = at
    _target = at
    var info: Dictionary = SPECIES[sp]
    sprite = Sprite2D.new()
    sprite.texture = load("res://assets/animals/%s_placeholder.png" % sp)
    sprite.hframes = 4
    sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 1)
    add_child(sprite)
    interactable = Interactable.new()
    var shape := CollisionShape2D.new()
    var c := CircleShape2D.new()
    c.radius = 38.0  # dá para observar de longe, antes de ele fugir
    shape.shape = c
    shape.position = Vector2(0, -6)
    interactable.add_child(shape)
    add_child(interactable)
    interactable.interacted.connect(func(_a: Node) -> void: observe())
    _update_prompt()
    return self


func display_name() -> String:
    return SPECIES[species].name


func observe() -> void:
    var info: Dictionary = SPECIES[species]
    if GameState.log_species(species):
        GameState.add_xp(&"caca", 30)
        EventBus.show_message("Anotado no caderno de campo: %s (%s)." % [info.name, info.sci], 3.5)
    else:
        GameState.add_xp(&"caca", 2)
        EventBus.show_message("%s. Já está no caderno." % info.name, 1.5)
    _update_prompt()


func _update_prompt() -> void:
    interactable.prompt = "Observar " + SPECIES[species].name.to_lower()


func _process(delta: float) -> void:
    var info: Dictionary = SPECIES[species]
    var player := get_tree().get_first_node_in_group("player") as Node2D
    var speed: float = info.speed
    if player and player.global_position.distance_to(global_position) < info.flee:
        _flee = 1.2
        var away := (global_position - player.global_position).normalized()
        _target = global_position + away * 48.0
    if _flee > 0.0:
        _flee -= delta
        speed *= 2.5
    if global_position.distance_to(_target) < 1.5:
        _anim = 0.0
        _wait -= delta
        if _wait <= 0.0:
            _target = home + Vector2(_rng.randf_range(-70, 70), _rng.randf_range(-40, 40))
            _wait = _rng.randf_range(2.0, 6.0)
    else:
        var dir := (_target - global_position).normalized()
        var next := global_position + dir * speed * delta
        if level == null or level.is_walkable(next):
            global_position = next
        else:
            _target = global_position
        sprite.flip_h = dir.x < 0
        _anim += delta
    sprite.frame = int(_anim * 8.0) % 4
