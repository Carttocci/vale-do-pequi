class_name NightLight
extends PointLight2D
## Luz quente que acende ao escurecer (lampiões, janelas das casas, a lanterna
## do jogador). A força acompanha a escuridão da hora (Clock.daylight_color).

const BUILDINGS := ["casa_principal", "casa_amarela", "casa_azul", "bar", "clinica", "ferreiro", "igreja", "mercearia"]

static var _tex: GradientTexture2D

var strength := 1.0


static func glow_texture() -> GradientTexture2D:
    if _tex == null:
        var g := Gradient.new()
        g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
        g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
        _tex = GradientTexture2D.new()
        _tex.gradient = g
        _tex.fill = GradientTexture2D.FILL_RADIAL
        _tex.fill_from = Vector2(0.5, 0.5)
        _tex.fill_to = Vector2(1.0, 0.5)
        _tex.width = 128
        _tex.height = 128
    return _tex


## Põe uma luz em `node` (deslocada `offset`, alcance `radius` px).
static func attach(node: Node2D, offset: Vector2, radius: float, col := Color(1.0, 0.78, 0.45), power := 1.0) -> NightLight:
    var l := NightLight.new()
    l.name = "NightLight"
    l.position = offset
    l.texture = glow_texture()
    l.texture_scale = radius / 64.0
    l.color = col
    l.strength = power
    node.add_child(l)
    return l


## Quão escuro está (0 = dia claro, 1 = noite fechada).
static func darkness() -> float:
    var c := Clock.daylight_color(Clock.minutes, Clock.weather)
    return clampf((1.0 - c.get_luminance()) / 0.55, 0.0, 1.0)


func _ready() -> void:
    add_to_group("night_light")
    blend_mode = Light2D.BLEND_MODE_ADD
    shadow_enabled = false
    refresh()


func refresh() -> void:
    var d := darkness()
    energy = d * 1.1 * strength
    enabled = d > 0.05
