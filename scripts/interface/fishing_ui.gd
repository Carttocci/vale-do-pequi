class_name FishingUI
extends CanvasLayer
## Minijogo de pesca de UM botão (E / botão verde / A):
##   1. Esperar: a boia fica parada. Apertar cedo espanta o peixe.
##   2. Fisgada: "FISGOU!" — aperte em até 1 s.
##   3. Briga: um marcador vai e volta numa barra; aperte quando ele estiver
##      na faixa verde. Acertos necessários e tamanho da faixa dependem do peixe.

enum Phase { IDLE, WAIT, BITE, REEL }

const BAR_W := 160.0
const BITE_WINDOW := 1.0
const MAX_MISSES := 3

var phase: Phase = Phase.IDLE
var fish: FishData
var marker: float = 0.0       # 0..1 na barra
var zone_center: float = 0.5
var zone_width: float = 0.3   # fração da barra
var hits: int = 0
var misses: int = 0
var hits_needed: int = 2

var _timer: float = 0.0
var _dir: float = 1.0
var _speed: float = 0.8       # barras por segundo
var _rng := RandomNumberGenerator.new()

var _panel: PanelContainer
var _label: Label
var _bar: Control


func _ready() -> void:
    layer = 4
    _build()
    _panel.hide()
    EventBus.fishing_started.connect(start)


func start(f: FishData) -> void:
    fish = f
    phase = Phase.WAIT
    hits = 0
    misses = 0
    var lvl := GameState.skill_level(&"pesca")
    _timer = _rng.randf_range(1.2, 4.0) * (1.0 - lvl * 0.04) * (0.5 if GameState.buff == &"pesca" else 1.0)
    hits_needed = 2 + (1 if f.difficulty >= 4 else 0) + (1 if f.difficulty >= 5 else 0)
    zone_width = clampf(lerpf(0.42, 0.14, (f.difficulty - 1) / 4.0) + lvl * 0.012, 0.1, 0.5)
    _speed = 0.7 + f.difficulty * 0.25
    _panel.show()
    _refresh()


func _process(delta: float) -> void:
    match phase:
        Phase.WAIT:
            _timer -= delta
            if _timer <= 0.0:
                phase = Phase.BITE
                _timer = BITE_WINDOW
                Audio.play(&"agua")
                _refresh()
        Phase.BITE:
            _timer -= delta
            if _timer <= 0.0:
                _finish(false, "Escapou! Faltou fisgar a tempo.")
        Phase.REEL:
            marker += _dir * _speed * delta
            if marker >= 1.0:
                marker = 1.0
                _dir = -1.0
            elif marker <= 0.0:
                marker = 0.0
                _dir = 1.0
            _bar.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
    if phase == Phase.IDLE:
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("use_item"):
        press()
        get_viewport().set_input_as_handled()


## O botão foi apertado (público para os testes).
func press() -> void:
    match phase:
        Phase.WAIT:
            _finish(false, "Puxou cedo demais e espantou o peixe.")
        Phase.BITE:
            phase = Phase.REEL
            marker = 0.0
            _dir = 1.0
            _new_zone()
            _refresh()
        Phase.REEL:
            if absf(marker - zone_center) <= zone_width / 2.0:
                hits += 1
                if hits >= hits_needed:
                    _finish(true, "")
                    return
                _new_zone()
            else:
                misses += 1
                if misses >= MAX_MISSES:
                    _finish(false, "A linha afrouxou e o peixe fugiu.")
                    return
            _refresh()


func is_active() -> bool:
    return phase != Phase.IDLE


func _new_zone() -> void:
    zone_center = _rng.randf_range(zone_width / 2.0, 1.0 - zone_width / 2.0)


func _finish(success: bool, message: String) -> void:
    phase = Phase.IDLE
    _panel.hide()
    if message != "":
        EventBus.show_message(message, 2.0)
    EventBus.fishing_finished.emit(success, fish)


func _refresh() -> void:
    match phase:
        Phase.WAIT:
            _label.text = "Esperando beliscar..."
        Phase.BITE:
            _label.text = "FISGOU! Aperte agora!"
        Phase.REEL:
            _label.text = "Puxe na faixa verde!  %d/%d   erros %d/%d" % [hits, hits_needed, misses, MAX_MISSES]
    _bar.visible = phase == Phase.REEL
    _bar.queue_redraw()


func _draw_bar() -> void:
    var r := Rect2(Vector2.ZERO, _bar.size)
    _bar.draw_rect(r, Color(0.1, 0.08, 0.07))
    var zx := (zone_center - zone_width / 2.0) * r.size.x
    _bar.draw_rect(Rect2(zx, 0, zone_width * r.size.x, r.size.y), Color(0.35, 0.65, 0.3))
    _bar.draw_rect(Rect2(marker * r.size.x - 1.5, -2, 3, r.size.y + 4), Color(0.96, 0.77, 0.11))
    _bar.draw_rect(r, Color(0.72, 0.47, 0.22), false, 1.0)


func _build() -> void:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.15, 0.12, 0.11, 0.92)
    box.border_color = Color(0.72, 0.47, 0.22, 1)
    box.set_border_width_all(1)
    box.set_corner_radius_all(3)
    box.set_content_margin_all(6)
    _panel = PanelContainer.new()
    _panel.add_theme_stylebox_override("panel", box)
    _panel.anchor_left = 0.5
    _panel.anchor_right = 0.5
    _panel.anchor_top = 1.0
    _panel.anchor_bottom = 1.0
    _panel.offset_left = -95
    _panel.offset_right = 95
    _panel.offset_top = -100
    _panel.offset_bottom = -44
    add_child(_panel)
    var col := VBoxContainer.new()
    _panel.add_child(col)
    _label = Label.new()
    _label.add_theme_font_size_override("font_size", 10)
    _label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86))
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(_label)
    _bar = Control.new()
    _bar.custom_minimum_size = Vector2(BAR_W, 12)
    _bar.draw.connect(_draw_bar)
    col.add_child(_bar)
