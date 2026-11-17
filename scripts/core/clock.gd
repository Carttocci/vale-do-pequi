extends Node
## Relógio e clima do dia (autoload "Clock").
##
## O dia vai das 06:00 às 02:00. A cada `real_seconds_per_step` segundos reais
## passam 10 minutos no jogo (padrão 7 s → o dia dura ~14 minutos reais).
## Pausa junto com o jogo (menus, mochila). Às 02:00 o jogador "apaga"
## (sinal `passed_out`; a cena principal faz ele acordar em casa).
##
## O clima é sorteado no começo de cada dia conforme o período (chuvoso/seco)
## com semente fixa por save: o mesmo save sempre tem o mesmo clima no mesmo dia.

signal time_changed(minutes: int)
signal day_started(day: int, weather: Weather)
signal passed_out

enum Weather { ENSOLARADO, NUBLADO, CHUVA, TEMPESTADE, NEBLINA, VENTANIA }
const WEATHER_NAMES := ["Ensolarado", "Nublado", "Chuva", "Tempestade", "Neblina", "Ventania"]
const WEATHER_KEYS := ["ensolarado", "nublado", "chuva", "tempestade", "neblina", "ventania"]

## Chance de cada clima por período (somam 1).
const CHANCES_RAINY := {Weather.CHUVA: 0.40, Weather.TEMPESTADE: 0.12, Weather.NUBLADO: 0.20, Weather.ENSOLARADO: 0.28}
const CHANCES_DRY := {Weather.ENSOLARADO: 0.65, Weather.VENTANIA: 0.15, Weather.NEBLINA: 0.12, Weather.NUBLADO: 0.06, Weather.CHUVA: 0.02}

const DAY_START := 6 * 60
const DAY_END := 26 * 60  # 02:00 do dia seguinte
const STEP_MINUTES := 10

@export var real_seconds_per_step: float = 7.0

var minutes: int = DAY_START
var weather: Weather = Weather.ENSOLARADO
## Liga/desliga a passagem do tempo (testes, cutscenes, diálogos).
var running: bool = true
var world_seed: int = 0
## Força o clima de todos os dias (testes/depuração). -1 = sorteio normal.
var forced_weather: int = -1

var _acc: float = 0.0


func _ready() -> void:
    reset()


func _process(delta: float) -> void:
    if not running:
        return
    _acc += delta
    while _acc >= real_seconds_per_step:
        _acc -= real_seconds_per_step
        advance_minutes(STEP_MINUTES)


func reset(seed: int = -1) -> void:
    world_seed = seed if seed >= 0 else randi()
    minutes = DAY_START
    weather = Weather.ENSOLARADO  # primeiro dia sempre bonito
    _acc = 0.0
    time_changed.emit(minutes)


func advance_minutes(amount: int) -> void:
    if minutes >= DAY_END:
        return
    minutes = mini(minutes + amount, DAY_END)
    time_changed.emit(minutes)
    if minutes >= DAY_END:
        passed_out.emit()


## Começa um dia novo: 06:00 e sorteia o clima.
func start_day(day: int) -> void:
    minutes = DAY_START
    _acc = 0.0
    weather = roll_weather(day)
    time_changed.emit(minutes)
    day_started.emit(day, weather)


func roll_weather(day: int) -> Weather:
    if forced_weather >= 0:
        return forced_weather as Weather
    if day <= 1:
        return Weather.ENSOLARADO
    var rng := RandomNumberGenerator.new()
    rng.seed = hash([world_seed, day])
    rng.randf()  # descarta: sementes vizinhas dão primeiros valores parecidos
    rng.randf()
    var table: Dictionary = CHANCES_DRY if Calendar.period(day) == Calendar.PERIOD_DRY else CHANCES_RAINY
    var r := rng.randf()
    var acc := 0.0
    for w: Weather in table:
        acc += table[w]
        if r < acc:
            return w
    return Weather.ENSOLARADO


func is_raining() -> bool:
    return weather == Weather.CHUVA or weather == Weather.TEMPESTADE


func weather_name() -> String:
    return WEATHER_NAMES[weather]


func hour() -> int:
    return (minutes / 60) % 24


## Cor da luz do mundo (usada por WeatherFX). Função pura para poder testar.
static func daylight_color(at_minutes: int, w: Weather) -> Color:
    var h := at_minutes / 60.0
    var c: Color
    if h < 7.0:
        c = Color(0.85, 0.78, 0.82).lerp(Color.WHITE, clampf(h - 6.0, 0.0, 1.0))   # amanhecer
    elif h < 17.0:
        c = Color.WHITE
    elif h < 19.0:
        c = Color.WHITE.lerp(Color(1.0, 0.78, 0.6), (h - 17.0) / 2.0)                 # entardecer
    elif h < 21.0:
        c = Color(1.0, 0.78, 0.6).lerp(Color(0.38, 0.42, 0.66), (h - 19.0) / 2.0)     # anoitecer
    else:
        c = Color(0.38, 0.42, 0.66)                                                    # noite
    match w:
        Weather.CHUVA, Weather.NUBLADO:
            c *= Color(0.82, 0.84, 0.88)
        Weather.TEMPESTADE:
            c *= Color(0.66, 0.68, 0.76)
    c.a = 1.0
    return c


func to_data() -> Dictionary:
    return {"minutes": minutes, "weather": WEATHER_KEYS[weather], "seed": world_seed}


func from_data(data: Dictionary) -> void:
    minutes = clampi(int(data.get("minutes", DAY_START)), DAY_START, DAY_END - STEP_MINUTES)
    var key := String(data.get("weather", "ensolarado"))
    weather = WEATHER_KEYS.find(key) if key in WEATHER_KEYS else Weather.ENSOLARADO
    world_seed = int(data.get("seed", world_seed))
    _acc = 0.0
    time_changed.emit(minutes)
