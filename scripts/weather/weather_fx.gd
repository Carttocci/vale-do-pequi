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

var _flash_timer: float = 0.0
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

    Clock.time_changed.connect(func(_m: int) -> void: refresh())
    Clock.day_started.connect(func(_d: int, _w: int) -> void: refresh())
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
    rain.emitting = raining
    rain.visible = raining
    rain.amount = 320 if Clock.weather == Clock.Weather.TEMPESTADE else 160
    # Neblina de manhã: forte às 6h, some até as 10h.
    var fog_alpha := 0.0
    if Clock.weather == Clock.Weather.NEBLINA:
        fog_alpha = clampf(1.0 - (Clock.minutes - Clock.DAY_START) / 240.0, 0.0, 1.0) * 0.45
    fog.color.a = fog_alpha
    if Clock.weather != Clock.Weather.TEMPESTADE:
        flash.color.a = 0.0


func _fit_rain() -> void:
    var size := get_viewport().get_visible_rect().size
    rain.position = Vector2(size.x / 2.0 + 40.0, -10.0)
    rain.emission_rect_extents = Vector2(size.x / 2.0 + 60.0, 4.0)
