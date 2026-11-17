class_name Arrow
extends Node2D
## Flecha disparada pelo arco: voa reto e acerta o primeiro inimigo.

const SPEED := 230.0
const LIFE := 0.9

var dir := Vector2.RIGHT
var damage := 10
var level: Level
var _life := LIFE


func setup(d: Vector2, dmg: int, lvl: Level) -> Arrow:
    dir = d.normalized()
    damage = dmg
    level = lvl
    rotation = dir.angle()
    var s := Sprite2D.new()
    s.texture = load("res://assets/effects/flecha_voo_placeholder.png")
    add_child(s)
    return self


func _process(delta: float) -> void:
    position += dir * SPEED * delta
    _life -= delta
    for e in get_tree().get_nodes_in_group("enemy"):
        var en := e as Node2D
        if en.is_visible_in_tree() and not en.is_dead() and en.global_position.distance_to(global_position + Vector2(0, 6)) < 10.0:
            en.take_hit(damage, dir, 80.0)
            queue_free()
            return
    for w in get_tree().get_nodes_in_group("huntable"):
        if w.is_visible_in_tree() and w.global_position.distance_to(global_position + Vector2(0, 6)) < 10.0:
            w.take_hit(damage, dir, 80.0)
            queue_free()
            return
    if _life <= 0.0:
        queue_free()
