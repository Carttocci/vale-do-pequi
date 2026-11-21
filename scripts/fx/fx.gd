class_name FX
extends RefCounted
## Efeitos de "impacto" (juice): número de dano subindo, faíscas/folhas voando
## e tremidinha de tela. Tudo leve: some sozinho, sem textura.

const FONT_SIZE := 11

## Quantas tremidas já começaram (testes).
static var shakes: int = 0


## Número que sobe e some em cima de quem apanhou.
static func damage_number(parent: Node, pos: Vector2, amount: int, color := Color(1, 0.95, 0.75)) -> Label:
    if parent == null or not parent.is_inside_tree():
        return null
    var l := Label.new()
    l.text = str(amount)
    l.add_theme_font_size_override("font_size", FONT_SIZE)
    l.add_theme_color_override("font_color", color)
    l.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.04))
    l.add_theme_constant_override("outline_size", 3)
    l.z_index = 20
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.size = Vector2(30, 14)
    l.position = pos + Vector2(-15 + randf_range(-4, 4), -30)
    l.add_to_group("fx")
    parent.add_child(l)
    var t := l.create_tween().set_parallel(true)
    t.tween_property(l, "position:y", l.position.y - 14, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
    t.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.35)
    t.chain().tween_callback(l.queue_free)
    return l


## Pedacinhos voando (folhas do mato, lascas de madeira, faísca na pedra).
static func burst(parent: Node, pos: Vector2, colors: Array, amount: int = 8) -> CPUParticles2D:
    if parent == null or not parent.is_inside_tree():
        return null
    var p := CPUParticles2D.new()
    p.one_shot = true
    p.explosiveness = 1.0
    p.amount = amount
    p.lifetime = 0.45
    p.direction = Vector2.UP
    p.spread = 70.0
    p.initial_velocity_min = 30.0
    p.initial_velocity_max = 70.0
    p.gravity = Vector2(0, 220)
    p.scale_amount_min = 1.0
    p.scale_amount_max = 2.0
    var g := Gradient.new()
    g.set_color(0, colors[0])
    g.set_color(1, colors[min(1, colors.size() - 1)])
    p.color_ramp = g
    p.position = pos
    p.z_index = 15
    p.add_to_group("fx")
    parent.add_child(p)
    p.emitting = true
    p.finished.connect(p.queue_free)
    return p


## Tremidinha na câmera do jogador.
static func shake(tree: SceneTree, strength: float = 2.0, duration: float = 0.15) -> void:
    var player := tree.get_first_node_in_group("player") as Player
    if player == null or player.camera == null:
        return
    var cam := player.camera
    shakes += 1
    var t := cam.create_tween()
    var steps := 4
    for i in steps:
        var k := 1.0 - float(i) / steps
        t.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * k, duration / steps)
    t.tween_property(cam, "offset", Vector2.ZERO, duration / steps)


const LEAVES := [Color(0.45, 0.68, 0.28), Color(0.3, 0.5, 0.2)]
const WOOD := [Color(0.72, 0.5, 0.3), Color(0.5, 0.32, 0.2)]
const STONE := [Color(0.8, 0.8, 0.84), Color(0.5, 0.5, 0.56)]
const BLOOD_SILENCE := [Color(0.75, 0.6, 1.0), Color(0.35, 0.25, 0.5)]
