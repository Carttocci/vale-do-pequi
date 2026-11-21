class_name Rock
extends StaticBody2D
## Pedra/minério que se quebra com a picareta. Deixa itens e XP de mineração.
## Com `persistent_rock`, fica quebrada para sempre (ex.: pedregulhos da trilha).

signal broken(rock: Rock)

const KINDS := {
    &"pedra": {"name": "pedra", "hp": 2, "tex": "rocha_pedra", "drops": [["pedra", 1, 2]], "xp": 2},
    &"ferro": {"name": "minério de ferro", "hp": 3, "tex": "rocha_ferro", "drops": [["minerio_ferro", 1, 2], ["pedra", 0, 1]], "xp": 5},
    &"quartzo": {"name": "quartzo", "hp": 3, "tex": "rocha_quartzo", "drops": [["quartzo", 1, 1], ["pedra", 0, 1]], "xp": 7},
    &"ouro": {"name": "ouro", "hp": 4, "tex": "rocha_ouro", "drops": [["ouro", 1, 1]], "xp": 12},
    &"cristal": {"name": "cristal do vale", "hp": 5, "tex": "rocha_cristal", "drops": [["cristal_vale", 1, 1]], "xp": 20},
    &"pedregulho": {"name": "pedregulho", "hp": 4, "tex": "pedregulho", "drops": [["pedra", 2, 3]], "xp": 6},
}

@export var kind: StringName = &"pedra"
@export var persistent_rock: bool = false

var hp: int = 1
var info: Dictionary
var _sprite: Sprite2D


func _ready() -> void:
    add_to_group("rock")
    if persistent_rock:
        add_to_group("persistent")
    collision_layer = 1
    collision_mask = 0
    info = KINDS[kind]
    hp = int(info.hp)
    _sprite = Sprite2D.new()
    _sprite.texture = load("res://assets/environments/%s_placeholder.png" % info.tex)
    _sprite.offset = Vector2(0, -_sprite.texture.get_height() / 2.0 + 1)
    add_child(_sprite)
    var shape := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(16, 10) if kind == &"pedregulho" else Vector2(12, 8)
    shape.shape = r
    shape.position = Vector2(0, -r.size.y / 2.0)
    add_child(shape)


func display_name() -> String:
    return info.name


## Uma picaretada. Retorna true se quebrou.
func hit(power: int = 1) -> bool:
    if hp <= 0:
        return false
    hp -= power
    Audio.play(&"picareta")
    FX.burst(get_parent(), position + Vector2(0, -4), FX.STONE, 5)
    var t := create_tween()
    _sprite.position = Vector2(1, 0)
    t.tween_property(_sprite, "position", Vector2.ZERO, 0.1)
    if hp > 0:
        return false
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    for d: Array in info.drops:
        var n := rng.randi_range(int(d[1]), int(d[2]))
        if n > 0:
            var pk := Pickup.new().setup(StringName(d[0]), n)
            pk.position = position + Vector2(rng.randf_range(-4, 4), 2)
            get_parent().add_child(pk)
    GameState.add_xp(&"mineracao", int(info.xp))
    Audio.play(&"pedra_quebra")
    broken.emit(self)
    var level := _level()
    collision_layer = 0
    hide()
    if level:
        level.invalidate_nav()
    if not persistent_rock:
        queue_free()
    return true


func is_broken() -> bool:
    return hp <= 0


func _level() -> Level:
    var n := get_parent()
    while n and not n is Level:
        n = n.get_parent()
    return n as Level


func get_save_data() -> Dictionary:
    return {"broken": hp <= 0}


func load_save_data(d: Dictionary) -> void:
    if bool(d.get("broken", false)):
        hp = 0
        collision_layer = 0
        hide()
    else:
        hp = int(info.hp)
        collision_layer = 1
        show()
    var level := _level()
    if level:
        level.invalidate_nav()
