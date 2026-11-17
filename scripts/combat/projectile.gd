class_name Projectile
extends Node2D
## Projétil de inimigo (estilhaço de cristal, orbe do Silêncio). Acerta o jogador.

var dir := Vector2.RIGHT
var speed := 110.0
var damage := 8
var drain_energy := 0
var life := 2.5


func setup(d: Vector2, dmg: int, spd: float = 110.0, drain: int = 0, color := Color.WHITE) -> Projectile:
    dir = d.normalized()
    damage = dmg
    speed = spd
    drain_energy = drain
    var s := Sprite2D.new()
    s.texture = load("res://assets/environments/estilhaco_placeholder.png")
    s.modulate = color
    add_child(s)
    add_to_group("projectile")
    return self


func _process(delta: float) -> void:
    position += dir * speed * delta
    life -= delta
    var player := get_tree().get_first_node_in_group("player") as Player
    if player and player.global_position.distance_to(global_position + Vector2(0, 6)) < 9.0:
        if player.take_damage(damage, dir) and drain_energy > 0:
            GameState.energy = maxi(0, GameState.energy - drain_energy)
            GameState.energy_changed.emit(GameState.energy, GameState.MAX_ENERGY)
        queue_free()
        return
    if life <= 0.0:
        queue_free()
