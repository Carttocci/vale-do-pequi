class_name Enemy
extends Node2D
## Criatura corrompida pelo Silêncio. Tipos em KINDS (dados), um script só.
##   chaser  — anda até o jogador e bate (raiz-torta)
##   hopper  — pula em direção ao jogador (lodo-cinza)
##   flyer   — voa em zigue-zague, ignora obstáculos (morcego)
##   charger — mira e investe em linha reta (javali corrompido)
##   boss    — usado pelos chefes (ver Boss)

signal died(enemy: Enemy)

const KINDS := {
    &"raiz_torta": {"name": "Raiz-torta", "hp": 30, "damage": 8, "speed": 22.0, "aggro": 90.0, "range": 14.0,
        "cooldown": 1.1, "ai": "chaser", "w": 20, "drops": [["madeira", 1, 2, 1.0], ["fragmento_silencio", 1, 1, 0.15]], "xp": 8},
    &"lodo_cinza": {"name": "Lodo-cinza", "hp": 22, "damage": 6, "speed": 30.0, "aggro": 80.0, "range": 12.0,
        "cooldown": 1.0, "ai": "hopper", "w": 16, "drops": [["fragmento_silencio", 1, 1, 0.25]], "xp": 6},
    &"morcego": {"name": "Morcego-de-gruta", "hp": 14, "damage": 5, "speed": 48.0, "aggro": 110.0, "range": 10.0,
        "cooldown": 0.9, "ai": "flyer", "w": 16, "drops": [["fragmento_silencio", 1, 1, 0.1]], "xp": 5},
    &"javali_corrompido": {"name": "Javali corrompido", "hp": 45, "damage": 12, "speed": 26.0, "aggro": 100.0, "range": 14.0,
        "cooldown": 1.4, "ai": "charger", "w": 24, "drops": [["carne_javali", 1, 2, 1.0], ["couro", 1, 1, 0.6], ["fragmento_silencio", 1, 1, 0.3]], "xp": 12},
    &"guardiao_cristal": {"name": "Guardião de Cristal", "hp": 260, "damage": 14, "speed": 16.0, "aggro": 400.0, "range": 18.0,
        "cooldown": 1.2, "ai": "boss", "w": 40, "drops": [["coracao_cristal", 1, 1, 1.0], ["cristal_vale", 2, 3, 1.0]], "xp": 120},
    &"eco_silencio": {"name": "Eco do Silêncio", "hp": 320, "damage": 12, "speed": 20.0, "aggro": 400.0, "range": 16.0,
        "cooldown": 1.2, "ai": "boss", "w": 32, "drops": [["fragmento_silencio", 5, 5, 1.0]], "xp": 200},
}

var kind: StringName
var info: Dictionary
var hp: int = 1
var max_hp: int = 1
var level: Level
var home := Vector2.ZERO

var _cooldown := 0.0
var _stun := 0.0
var _knock := Vector2.ZERO
var _anim := 0.0
var _charge_dir := Vector2.ZERO
var _charge_time := 0.0
var _wander := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var sprite: Sprite2D


func setup(k: StringName, at: Vector2, lvl: Level, hp_scale: float = 1.0) -> Enemy:
    kind = k
    info = KINDS[k]
    level = lvl
    position = at
    home = at
    max_hp = int(info.hp * hp_scale)
    hp = max_hp
    sprite = Sprite2D.new()
    sprite.texture = load("res://assets/enemies/%s_placeholder.png" % k)
    sprite.hframes = 4
    sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 1)
    add_child(sprite)
    add_to_group("enemy")
    _rng.randomize()
    return self


func is_dead() -> bool:
    return hp <= 0


## Recebe um golpe. `dir` = direção do empurrão.
func take_hit(amount: int, dir: Vector2, knockback: float, stun: float = 0.0) -> void:
    if is_dead():
        return
    hp -= amount
    Audio.play(&"acerto")
    _knock = dir.normalized() * knockback
    _stun = maxf(_stun, stun + 0.15)
    sprite.modulate = Color(2, 2, 2)
    var t := create_tween()
    t.tween_property(sprite, "modulate", Color.WHITE, 0.15)
    if hp <= 0:
        _die()


func _die() -> void:
    GameState.add_xp(&"combate", int(info.xp))
    EventBus.enemy_killed.emit(kind)
    for d: Array in info.drops:
        if _rng.randf() <= float(d[3]):
            var pk := Pickup.new().setup(StringName(d[0]), _rng.randi_range(int(d[1]), int(d[2])))
            pk.position = position + Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-4, 4))
            get_parent().add_child(pk)
    died.emit(self)
    var t := create_tween()
    t.tween_property(self, "modulate:a", 0.0, 0.25)
    t.tween_callback(queue_free)


func _process(delta: float) -> void:
    if is_dead():
        return
    _cooldown = maxf(0.0, _cooldown - delta)
    if _knock.length() > 1.0:
        _move(_knock * delta, true)
        _knock = _knock.move_toward(Vector2.ZERO, 600.0 * delta)
    if _stun > 0.0:
        _stun -= delta
        return
    var player := get_tree().get_first_node_in_group("player") as Player
    var to_player := player.global_position - global_position if player else Vector2.INF
    var dist := to_player.length() if player else INF
    _anim += delta
    match info.ai:
        "chaser", "boss":
            if _charge_time > 0.0:
                _charge_time -= delta
                _move(_charge_dir * info.speed * 6.0 * delta)
                if dist <= info.range + 6.0:
                    _try_hit(player, to_player)
            elif dist < info.aggro:
                if dist > info.range:
                    _move(to_player.normalized() * info.speed * delta)
                else:
                    _try_hit(player, to_player)
            else:
                _idle(delta)
        "hopper":
            if dist < info.aggro:
                var hop := 0.5 + 0.5 * sin(_anim * 6.0)
                if dist > info.range:
                    _move(to_player.normalized() * info.speed * hop * 1.6 * delta)
                else:
                    _try_hit(player, to_player)
            else:
                _idle(delta)
        "flyer":
            if dist < info.aggro:
                var side := Vector2(-to_player.y, to_player.x).normalized() * sin(_anim * 5.0) * 0.8
                if dist > info.range:
                    _move((to_player.normalized() + side) * info.speed * delta, true)
                else:
                    _try_hit(player, to_player)
            else:
                _idle(delta)
        "charger":
            if _charge_time > 0.0:
                _charge_time -= delta
                _move(_charge_dir * info.speed * 4.0 * delta)
                if dist <= info.range + 4.0:
                    _try_hit(player, to_player)
            elif dist < info.aggro and _cooldown <= 0.0:
                _charge_dir = to_player.normalized()
                _charge_time = 0.5
                _cooldown = info.cooldown
            elif dist < info.aggro:
                pass  # se preparando
            else:
                _idle(delta)
    if to_player != Vector2.INF:
        sprite.flip_h = to_player.x < 0
    sprite.frame = int(_anim * 8.0) % 4


func _try_hit(player: Player, to_player: Vector2) -> void:
    if _cooldown > 0.0 or player == null:
        return
    _cooldown = info.cooldown
    player.take_damage(int(info.damage), to_player)


func _idle(delta: float) -> void:
    if _wander == Vector2.ZERO or global_position.distance_to(_wander) < 2.0:
        _wander = home + Vector2(_rng.randf_range(-40, 40), _rng.randf_range(-30, 30))
    _move((_wander - global_position).normalized() * info.speed * 0.4 * delta)


func _move(step: Vector2, ignore_walls: bool = false) -> void:
    var next := global_position + step
    if ignore_walls and info.ai == "flyer":
        global_position = next
    elif level == null or level.is_walkable(next):
        global_position = next
    elif level.is_walkable(global_position + Vector2(step.x, 0)):
        global_position.x += step.x
    elif level.is_walkable(global_position + Vector2(0, step.y)):
        global_position.y += step.y
