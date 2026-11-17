class_name Bandeirinhas
extends Node2D
## Varais de bandeirinhas coloridas sobre a praça (desenho simples, sem textura).

const LINES := [[Vector2(300, 214), Vector2(536, 214)], [Vector2(300, 214), Vector2(416, 262)],
    [Vector2(536, 214), Vector2(416, 262)], [Vector2(300, 262), Vector2(536, 262)]]
const COLORS := [Color(0.85, 0.2, 0.2), Color(0.98, 0.8, 0.2), Color(0.2, 0.5, 0.85), Color(0.3, 0.65, 0.3),
    Color(0.95, 0.5, 0.75), Color(1, 1, 1)]


func _draw() -> void:
    var i := 0
    for l in LINES:
        var a: Vector2 = l[0] - Vector2(0, 30)
        var b: Vector2 = l[1] - Vector2(0, 30)
        draw_line(a, b, Color(0.3, 0.25, 0.2), 1.0)
        var n := int(a.distance_to(b) / 8.0)
        for k in n:
            var p := a.lerp(b, (k + 0.5) / n)
            var c: Color = COLORS[i % COLORS.size()]
            draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 0), p + Vector2(3, 0), p + Vector2(0, 5)]), c)
            i += 1
