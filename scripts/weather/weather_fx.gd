class_name WeatherFX
extends Node
## Visual do tempo: luz do dia/noite (CanvasModulate no mundo) e efeitos de
## clima por cima do mapa (chuva, relâmpago, neblina). Só apresentação:
## lê o estado do Clock e não muda nada no jogo.

const RAIN_TEXTURE: Texture2D = preload("res://assets/effects/gota_chuva_placeholder.png")

var daylight: CanvasModulate
var overlay: CanvasLayer
var rain: CPUParticles2D
var fog: ColorRect
var flash: ColorRect
## Estação: folhas/pétalas caindo de dia e vaga-lumes nas noites de chuva.
var leaves: CPUParticles2D
var fireflies: CPUParticles2D
const OUTDOOR := [&"farm", &"vila", &"mata", &"serra"]

var _flash_timer: float = 0.0
## Quantas vezes a chuva recomeçou (testes: não pode subir enquanto continua chovendo).
var rain_restarts: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    daylight = CanvasModulate.new()
    daylight.name = "Daylight"
    add_child(daylight)

    overlay = CanvasLayer.new()
    overlay.name = "Overlay"
    overlay.layer = 1
    add_child(overlay)

    rain = CPUParticles2D.new()
    rain.name = "Rain"
    rain.texture = RAIN_TEXTURE
    rain.amount = 160
    rain.lifetime = 0.9
    rain.preprocess = 1.0
    rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    rain.direction = Vector2(-0.25, 1.0)
    rain.spread = 3.0
    rain.gravity = Vector2.ZERO
    rain.initial_velocity_min = 380.0
    rain.initial_velocity_max = 460.0
    rain.emitting = false
    overlay.add_child(rain)

    fog = ColorRect.new()
    fog.name = "Fog"
    fog.color = Color(0.92, 0.92, 0.95, 0.0)
    fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fog.set_anchors_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(fog)

    flash = ColorRect.new()
    flash.name = "Flash"
    flash.color = Color(1, 1, 1, 0)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    flash.set_anchors_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(flash)

    leaves = _make_drift("Leaves", 14, 6.0)
    leaves.direction = Vector2(-0.6, 1.0)
    leaves.initial_velocity_min = 14.0
    leaves.initial_velocity_max = 26.0
    leaves.angular_velocity_min = -90.0
    leaves.angular_velocity_max = 90.0
    leaves.scale_amount_min = 3.0
    leaves.scale_amount_max = 4.0
    fireflies = _make_drift("Fireflies", 18, 4.0)
    fireflies.direction = Vector2(0, -1)
    fireflies.spread = 180.0
    fireflies.initial_velocity_min = 4.0
    fireflies.initial_velocity_max = 10.0
    fireflies.scale_amount_min = 1.5
    fireflies.scale_amount_max = 2.0
    var blink := Gradient.new()
    blink.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
    blink.colors = PackedColorArray([Color(0.9, 1, 0.4, 0), Color(0.9, 1, 0.4, 1), Color(0.9, 1, 0.4, 0.15),
        Color(0.9, 1, 0.4, 1), Color(0.9, 1, 0.4, 0)])
    fireflies.color_ramp = blink

    Clock.time_changed.connect(func(_m: int) -> void: refresh())
    Clock.day_started.connect(func(_d: int, _w: int) -> void: refresh())
    EventBus.region_entered.connect(func(_r: StringName) -> void: refresh.call_deferred())
    _attach_lights.call_deferred()
    get_viewport().size_changed.connect(_fit_rain)
    _fit_rain()
    refresh()


func _process(delta: float) -> void:
    if Clock.weather != Clock.Weather.TEMPESTADE:
        return
    _flash_timer -= delta
    if _flash_timer <= 0.0:
        _flash_timer = _rng.randf_range(5.0, 12.0)
        var t := create_tween()
        t.tween_property(flash, "color:a", 0.55, 0.05)
        t.tween_property(flash, "color:a", 0.0, 0.35)


func refresh() -> void:
    daylight.color = Clock.daylight_color(Clock.minutes, Clock.weather)
    var raining := Clock.is_raining()
    # Mexer em `amount` ou religar `emitting` reinicia as partículas (a chuva
    # "pisca" e recomeça do topo). Então só mexe quando o tempo muda de verdade.
    var amount := 320 if Clock.weather == Clock.Weather.TEMPESTADE else 160
    if rain.amount != amount:
        rain.amount = amount
        rain_restarts += 1
    if rain.emitting != raining:
        rain.emitting = raining
        if raining:
            rain_restarts += 1
    rain.visible = raining
    # Neblina de manhã: forte às 6h, some até as 10h.
    var fog_alpha := 0.0
    if Clock.weather == Clock.Weather.NEBLINA:
        fog_alpha = clampf(1.0 - (Clock.minutes - Clock.DAY_START) / 240.0, 0.0, 1.0) * 0.45
    fog.color.a = fog_alpha
    if Clock.weather != Clock.Weather.TEMPESTADE:
        flash.color.a = 0.0
    apply_season()
    for l in get_tree().get_nodes_in_group("night_light"):
        (l as NightLight).refresh()


## Janelas acesas nas casas e a lanterninha do jogador.
func _attach_lights() -> void:
    for lv in get_tree().get_nodes_in_group("level"):
        for n in (lv as Level).get_entities_root().get_children():
            var f := String(n.scene_file_path).get_file().get_basename()
            if f in NightLight.BUILDINGS and n is Node2D and n.get_node_or_null("NightLight") == null:
                NightLight.attach(n, Vector2(0, -14), 70.0)
    var player := get_tree().get_first_node_in_group("player") as Node2D
    if player and player.get_node_or_null("NightLight") == null:
        NightLight.attach(player, Vector2(0, -8), 60.0, Color(1.0, 0.9, 0.7), 0.6)
    refresh()


func _make_drift(node_name: String, amount: int, life: float) -> CPUParticles2D:
    var p := CPUParticles2D.new()
    p.name = node_name
    p.amount = amount
    p.lifetime = life
    p.preprocess = life
    p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
    p.gravity = Vector2.ZERO
    p.emitting = false
    overlay.add_child(p)
    return p


func _current_region() -> StringName:
    var main := get_tree().get_first_node_in_group("save_root")
    if main and "level" in main and main.level:
        return main.level.region_id
    return &""


## Mato amarela na seca: tinge o chão das regiões a céu aberto.
func apply_season() -> void:
    var tint := Calendar.season_tint(GameState.day)
    for lv in get_tree().get_nodes_in_group("level"):
        var level := lv as Level
        if level and level.ground:
            level.ground.modulate = tint if level.region_id in OUTDOOR else Color.WHITE
    var outside := _current_region() in OUTDOOR
    var dry := Calendar.period(GameState.day) == Calendar.PERIOD_DRY
    var ipe := Calendar.is_ipe_bloom(GameState.day)
    var night := Clock.minutes >= 19 * 60 + 30 or Clock.minutes < 5 * 60
    var falling := outside and (dry or ipe) and not night and not Clock.is_raining()
    if falling:
        var g := Gradient.new()
        if ipe:  # pétalas amarelas e rosas de ipê
            g.colors = PackedColorArray([Color(1, 0.85, 0.2), Color(0.95, 0.5, 0.7)])
        else:    # folha seca
            g.colors = PackedColorArray([Color(0.78, 0.55, 0.25), Color(0.6, 0.42, 0.2)])
        leaves.color_initial_ramp = g
    var want := 40 if ipe else 18
    if leaves.amount != want:
        leaves.amount = want
    if leaves.emitting != falling:
        leaves.emitting = falling
    leaves.visible = falling
    var glow := outside and not dry and night and Clock.weather != Clock.Weather.TEMPESTADE
    if fireflies.emitting != glow:
        fireflies.emitting = glow
    fireflies.visible = glow


func _fit_rain() -> void:
    var size := get_viewport().get_visible_rect().size
    rain.position = Vector2(size.x / 2.0 + 40.0, -10.0)
    rain.emission_rect_extents = Vector2(size.x / 2.0 + 60.0, 4.0)
    # gota tem que chegar até embaixo mesmo em tela alta (celular em pé)
    var life := (size.y + 40.0) / 380.0
    if not is_equal_approx(rain.lifetime, life):
        rain.lifetime = life
        rain.preprocess = life
    for p in [leaves, fireflies]:
        if p:
            p.position = size / 2.0
            p.emission_rect_extents = size / 2.0 + Vector2(20, 20)
