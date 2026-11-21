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
## Ataque à criação (Ranch): cercado-alvo.
var raid_ranch: Ranch
var raid_pen: StringName = &""
var _raid_target: Node2D
var _wander := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var sprite: Sprite2D
## Barrinha de vida em cima da criatura (aparece depois do primeiro golpe).
var hp_bar: Node2D


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
    if info.ai != "boss":  # chefe tem barra grande no HUD
        hp_bar = Node2D.new()
        hp_bar.name = "HpBar"
        hp_bar.position = Vector2(0, -sprite.texture.get_height() - 3)
        hp_bar.visible = false
        hp_bar.draw.connect(_draw_hp_bar)
        add_child(hp_bar)
    add_to_group("enemy")
    _rng.randomize()
    return self


func _draw_hp_bar() -> void:
    var w := maxf(12.0, float(info.w) * 0.8)
    var r := Rect2(-w / 2.0, 0, w, 3)
    hp_bar.draw_rect(r.grow(1), Color(0.08, 0.06, 0.06, 0.85))
    var f := clampf(float(hp) / max_hp, 0.0, 1.0)
    var col := Color(0.4, 0.85, 0.35) if f > 0.5 else (Color(0.95, 0.75, 0.2) if f > 0.25 else Color(0.9, 0.25, 0.2))
    hp_bar.draw_rect(Rect2(r.position, Vector2(w * f, 3)), col)


func is_dead() -> bool:
    return hp <= 0


## Recebe um golpe. `dir` = direção do empurrão.
func take_hit(amount: int, dir: Vector2, knockback: float, stun: float = 0.0) -> void:
    if is_dead():
        return
    hp -= amount
    if hp_bar:
        hp_bar.visible = hp > 0
        hp_bar.queue_redraw()
    Audio.play(&"acerto")
    _knock = dir.normalized() * knockback
    _stun = maxf(_stun, stun + 0.15)
    sprite.modulate = Color(2, 2, 2)
    var t := create_tween()
    t.tween_property(sprite, "modulate", Color.WHITE, 0.15)
    FX.damage_number(get_parent(), position, amount)
    FX.burst(get_parent(), position + Vector2(0, -8), FX.BLOOD_SILENCE, 6)
    FX.shake(get_tree(), 1.5 if hp > 0 else 3.0, 0.12)
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
    # ataque à criação: vai atrás da porteira/dos bichos, a não ser que você chegue perto
    if raid_ranch and (player == null or dist > 70.0) and _process_raid(delta):
        sprite.frame = int(_anim * 8.0) % 4
        return
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


## Anda até o alvo do ataque à criação e bate nele. Retorna false se não tem alvo.
func _process_raid(delta: float) -> bool:
    if _raid_target == null or not is_instance_valid(_raid_target) or not _raid_target.is_inside_tree():
        _raid_target = raid_ranch.raid_target(raid_pen)
        if _raid_target == null:
            return false
    var to := _raid_target.global_position - global_position
    if to.length() > info.range + 4.0:
        _move(to.normalized() * info.speed * delta, true)
    elif _cooldown <= 0.0:
        _cooldown = info.cooldown
        raid_ranch.raid_hit(_raid_target, int(info.damage))
        _raid_target = null  # escolhe de novo (porteira pode ter quebrado, bicho fugido)
    sprite.flip_h = to.x < 0
    return true


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
