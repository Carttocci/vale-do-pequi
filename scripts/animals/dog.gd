class_name Dog
extends Node2D
## Pipoca, o vira-lata caramelo da fazenda (era do vovô). Segue você pela
## fazenda, late quando vem ataque, morde as criaturas do Silêncio e aceita
## carinho uma vez por dia. Quando você sai da fazenda, ele fica em casa.

const SPEED := 70.0
const BITE_DAMAGE := 6
const BITE_EVERY := 1.1
## Testes desligam o cachorro (ele morderia os inimigos dos outros testes).
static var active := true

var ranch: Ranch
var sprite: Sprite2D
var interactable: Interactable
var _anim := 0.0
var _bite := 0.0
var _home := Vector2.ZERO


func _ready() -> void:
    add_to_group("dog")
    _home = position
    sprite = Sprite2D.new()
    sprite.texture = load("res://assets/animals/cachorro_placeholder.png")
    sprite.hframes = 4
    sprite.offset = Vector2(0, -7)
    add_child(sprite)
    interactable = Interactable.new()
    interactable.target_priority = 1
    var shape := CollisionShape2D.new()
    var c := CircleShape2D.new()
    c.radius = 9.0
    shape.shape = c
    shape.position = Vector2(0, -5)
    interactable.add_child(shape)
    add_child(interactable)
    interactable.prompt = "Fazer carinho no Pipoca"
    interactable.interacted.connect(func(_a: Node) -> void:
        if ranch:
            ranch.pet_dog())


func bark() -> void:
    Audio.play(&"latido")
    var t := create_tween()
    t.tween_property(sprite, "position:y", -3.0, 0.08)
    t.tween_property(sprite, "position:y", 0.0, 0.08)


func _level() -> Level:
    var n := get_parent()
    while n and not n is Level:
        n = n.get_parent()
    return n as Level


func _process(delta: float) -> void:
    var level := _level()
    if not active or (level and not level.active):
        interactable.enabled = active
        return
    # com arma na mão o clique ataca; carinho fica pra quando estiver de mão livre
    var held := GameState.get_selected_item()
    interactable.enabled = not (held and held.is_weapon())
    _bite = maxf(0.0, _bite - delta)
    var target := _home
    var enemy := _nearest_enemy(140.0)
    if enemy:
        target = enemy.global_position
        if global_position.distance_to(target) < 14.0:
            if _bite <= 0.0:
                _bite = BITE_EVERY
                bark()
                enemy.take_hit(BITE_DAMAGE, (target - global_position).normalized(), 60.0, 0.1)
            target = global_position
    else:
        var player := get_tree().get_first_node_in_group("player") as Node2D
        if player and level and level.is_ancestor_of(player):
            target = player.global_position + Vector2(-18, 6)
            if global_position.distance_to(target) < 22.0:
                target = global_position
    var to := target - global_position
    if to.length() > 2.0:
        var step := to.normalized() * minf(SPEED * delta, to.length())
        var next := global_position + step
        if level == null or level.is_walkable(next):
            global_position = next
        sprite.flip_h = to.x < 0
        _anim += delta
    else:
        _anim = 0.0
    sprite.frame = int(_anim * 10.0) % 4


func _nearest_enemy(radius: float) -> Enemy:
    var best: Enemy = null
    var best_d := radius
    for n in get_tree().get_nodes_in_group("enemy"):
        var e := n as Enemy
        if e == null or e.is_dead() or not e.is_visible_in_tree():
            continue
        var d := e.global_position.distance_to(global_position)
        if d < best_d:
            best_d = d
            best = e
    return best
