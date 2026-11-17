class_name MataLevel
extends Level
## Mata dos Ipês + Rio das Araras: bichos do Cerrado aparecem conforme hora
## e período; pegadas de javali surgem todo dia.

## espécie: [quantidade, zona, hora início, hora fim, período ("" = qualquer)]
const FAUNA := {
    &"capivara": [3, "rio", 6, 19, ""],
    &"cutia": [2, "mata", 6, 18, ""],
    &"quati": [2, "mata", 7, 17, ""],
    &"seriema": [2, "campo", 6, 18, ""],
    &"ema": [1, "campo", 7, 17, "seco"],
    &"veado": [1, "campo", 6, 10, ""],
    &"javali": [3, "mata", 16, 26, ""],
}
## Zonas (retângulos em pixels) onde cada tipo de bicho aparece.
@export var zones := {
    "rio": Rect2(80, 340, 800, 24),
    "mata": Rect2(80, 60, 360, 240),
    "campo": Rect2(560, 60, 320, 240),
}

var _rng := RandomNumberGenerator.new()
var _fauna_root: Node2D


func _ready() -> void:
    super._ready()
    _fauna_root = Node2D.new()
    _fauna_root.name = "Fauna"
    _fauna_root.y_sort_enabled = true
    get_entities_root().add_child(_fauna_root)
    Clock.day_started.connect(func(_d: int, _w: int) -> void: respawn())
    Clock.time_changed.connect(func(_m: int) -> void: _update_visibility())


func set_active(value: bool) -> void:
    super.set_active(value)
    if value:
        if _fauna_root.get_child_count() == 0:
            respawn()
        _update_visibility()


func respawn() -> void:
    if _fauna_root == null:
        return
    for c in _fauna_root.get_children():
        _fauna_root.remove_child(c)
        c.queue_free()
    _rng.seed = hash(["mata", GameState.day])
    var period := Calendar.period(GameState.day)
    for sp: StringName in FAUNA:
        var cfg: Array = FAUNA[sp]
        if cfg[4] != "" and String(period) != cfg[4]:
            continue
        for i in int(cfg[0]):
            var pos := _random_spot(zones[cfg[1]])
            if pos != Vector2.INF:
                var a := WildAnimal.new().setup(sp, pos, self)
                a.set_meta("hours", [cfg[2], cfg[3]])
                _fauna_root.add_child(a)
                if sp == &"javali":
                    _add_tracks(pos)
    # Criaturas corrompidas saem à noite (19h às 2h)
    for k in [&"raiz_torta", &"raiz_torta", &"javali_corrompido", &"lodo_cinza"]:
        var pos := _random_spot(zones["mata"])
        if pos != Vector2.INF:
            var e := Enemy.new().setup(k, pos, self)
            e.set_meta("hours", [19, 26])
            _fauna_root.add_child(e)
    _update_visibility()


func enemies() -> Array:
    return _fauna_root.get_children().filter(func(c: Node) -> bool: return c is Enemy)


func _add_tracks(pos: Vector2) -> void:
    var spot := _random_spot(Rect2(pos - Vector2(60, 40), Vector2(120, 80)))
    if spot == Vector2.INF:
        return
    var dir: String = ["norte", "sul", "leste", "oeste"][_rng.randi_range(0, 3)]
    var t := InspectSpot.new().setup("Examinar pegadas",
        "Pegadas de javali, fundas e frescas, indo para o %s. Ele aparece no fim da tarde e à noite." % dir,
        load("res://assets/environments/pegadas_placeholder.png"))
    t.position = spot
    t.add_to_group("tracks")
    t.inspected.connect(func() -> void: GameState.add_xp(&"caca", 5))
    _fauna_root.add_child(t)


func _random_spot(rect: Rect2) -> Vector2:
    for i in 30:
        var p := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
        if is_walkable(p):
            return p
    return Vector2.INF


func _update_visibility() -> void:
    if _fauna_root == null:
        return
    var h := Clock.minutes / 60.0
    for a in _fauna_root.get_children():
        if a.has_meta("hours"):
            var hours: Array = a.get_meta("hours")
            var on: bool = h >= float(hours[0]) and h < float(hours[1])
            a.visible = on
            a.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func animals() -> Array:
    return _fauna_root.get_children().filter(func(c: Node) -> bool: return c is WildAnimal)
