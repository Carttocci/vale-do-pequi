class_name Boss
extends Enemy
## Chefe: persegue devagar e, a cada SPECIAL_EVERY segundos, usa um ataque
## especial. Abaixo de metade da vida chama ajudantes (uma vez).
##   Guardião de Cristal: estilhaços em círculo + investida.
##   Eco do Silêncio: some e reaparece perto do jogador + orbes que roubam energia.

signal phase_changed(phase: int)

const SPECIAL_EVERY := 3.2

var phase: int = 1
var _special := SPECIAL_EVERY
var _summoned := false


func _process(delta: float) -> void:
    super._process(delta)
    if is_dead() or _stun > 0.0:
        return
    _special -= delta
    if _special <= 0.0:
        _special = SPECIAL_EVERY * (0.75 if phase == 2 else 1.0)
        special_attack()


## A segunda fase começa no golpe que leva a vida abaixo da metade.
func take_hit(amount: int, dir: Vector2, knockback: float, stun: float = 0.0) -> void:
    super.take_hit(amount, dir, knockback, stun)
    if not is_dead() and phase == 1 and hp <= max_hp * 0.5:
        phase = 2
        phase_changed.emit(2)
        if not _summoned:
            _summoned = true
            _summon.call_deferred()


func special_attack() -> void:
    var player := get_tree().get_first_node_in_group("player") as Node2D
    match kind:
        &"guardiao_cristal":
            var n := 8 if phase == 1 else 12
            for i in n:
                _fire(Vector2.RIGHT.rotated(TAU * i / n), 10, 100.0, 0, Color(0.8, 0.7, 1.0))
            if player:
                _charge_dir = (player.global_position - global_position).normalized()
                _charge_time = 0.4
        &"eco_silencio":
            if player:
                var side := Vector2.RIGHT.rotated(randf() * TAU) * 50.0
                if level == null or level.is_walkable(player.global_position + side):
                    global_position = player.global_position + side
                for i in 3:
                    var d := (player.global_position - global_position).normalized().rotated((i - 1) * 0.35)
                    _fire(d, 8, 80.0, 10, Color(0.6, 0.6, 0.8))


func _fire(d: Vector2, dmg: int, spd: float, drain: int, color: Color) -> void:
    var p := Projectile.new().setup(d, dmg, spd, drain, color)
    p.global_position = global_position + Vector2(0, -12)
    get_parent().add_child(p)


func _summon() -> void:
    var helper := &"morcego" if kind == &"guardiao_cristal" else &"lodo_cinza"
    for i in 2:
        var e := Enemy.new().setup(helper, global_position + Vector2(-30 + i * 60, 10), level)
        get_parent().add_child(e)
