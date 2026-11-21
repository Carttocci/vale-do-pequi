extends Node
## Som do jogo (autoload "Audio"): efeitos e música com troca suave.
##
## Os arquivos são gerados por tools/gerar_audio.py (síntese, sem samples).
## Música por contexto: dia, noite (19h+), mina (mina e ruínas), festa
## (vila em dia de festa). Efeitos tocam por sinais do jogo e por Audio.play().

const BUS_MUSIC := &"Musica"
const BUS_SFX := &"Efeitos"
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/musica/"
const SFX := [&"capinar", &"regar", &"pegar", &"moeda", &"golpe", &"acerto", &"dano", &"picareta", &"pedra_quebra",
    &"comer", &"agua", &"nivel", &"missao", &"porta", &"clique", &"dialogo", &"chefe", &"latido",
    &"passo_grama", &"passo_terra", &"passo_pedra", &"passo_madeira"]
const TRACKS := [&"dia", &"noite", &"mina", &"festa"]
const FADE := 1.5
const VOICES := 8

var current_track: StringName = &""
var last_sfx: StringName = &""
var _sfx: Dictionary = {}
var _music: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _last_played: Dictionary = {}
var _money := -1
var _health := -1
var _levels: Dictionary = {}


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_bus(BUS_MUSIC)
    _ensure_bus(BUS_SFX)
    for id in SFX:
        var path := SFX_DIR + String(id) + ".wav"
        if ResourceLoader.exists(path):
            _sfx[id] = load(path)
    for id in TRACKS:
        var path := MUSIC_DIR + String(id) + ".wav"
        if ResourceLoader.exists(path):
            var s := load(path) as AudioStreamWAV
            if s:
                s.loop_mode = AudioStreamWAV.LOOP_FORWARD
                s.loop_begin = 0
                s.loop_end = int(s.get_length() * s.mix_rate)
            _music[id] = s
    for i in VOICES:
        var p := AudioStreamPlayer.new()
        p.bus = BUS_SFX
        add_child(p)
        _players.append(p)
    _music_a = _make_music_player()
    _music_b = _make_music_player()
    _connect_game_signals()


func _make_music_player() -> AudioStreamPlayer:
    var p := AudioStreamPlayer.new()
    p.bus = BUS_MUSIC
    p.volume_db = -80.0
    add_child(p)
    return p


func _ensure_bus(bus_name: StringName) -> void:
    if AudioServer.get_bus_index(bus_name) != -1:
        return
    AudioServer.add_bus()
    var idx := AudioServer.bus_count - 1
    AudioServer.set_bus_name(idx, bus_name)
    AudioServer.set_bus_send(idx, &"Master")


## Volume 0..1 (0 = mudo).
func set_bus_volume(bus_name: StringName, value: float) -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx == -1:
        return
    AudioServer.set_bus_mute(idx, value <= 0.001)
    AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.001)))


## Toca um efeito. Repetições muito juntas do mesmo som são ignoradas.
func play(id: StringName, pitch_jitter: float = 0.06) -> void:
    if not _sfx.has(id):
        return
    var now := Time.get_ticks_msec()
    if now - int(_last_played.get(id, -1000)) < 40:
        return
    _last_played[id] = now
    last_sfx = id
    var p := _players[_next_voice]
    _next_voice = (_next_voice + 1) % VOICES
    p.stream = _sfx[id]
    p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
    p.play()


## Troca de música com fade. Mesmo nome = continua tocando.
func play_music(id: StringName) -> void:
    if id == current_track or not _music.has(id):
        return
    current_track = id
    var old := _music_a if _music_a.playing and _music_a.volume_db > -40.0 else _music_b
    var new := _music_b if old == _music_a else _music_a
    new.stream = _music[id]
    new.volume_db = -40.0
    new.play()
    var t := create_tween().set_parallel(true)
    t.tween_property(new, "volume_db", 0.0, FADE)
    if old.playing:
        t.tween_property(old, "volume_db", -80.0, FADE)
        t.chain().tween_callback(old.stop)


## Música certa para agora (região, hora, festa). Sem jogo aberto: "dia".
func music_for_context() -> StringName:
    var main := get_tree().get_first_node_in_group("save_root")
    if main == null or not "level" in main or main.level == null:
        return &"dia"
    var region: StringName = main.level.region_id
    if region in [&"mina", &"ruinas"]:
        return &"mina"
    if region == &"vila" and Festivals.today(GameState.day) != &"" and Clock.minutes < 22 * 60:
        return &"festa"
    if Clock.minutes >= 19 * 60:
        return &"noite"
    return &"dia"


func update_music() -> void:
    play_music(music_for_context())


func _connect_game_signals() -> void:
    EventBus.region_entered.connect(func(_r: StringName) -> void: update_music())
    Clock.time_changed.connect(func(m: int) -> void:
        if m % 60 == 0:
            update_music())
    Clock.day_started.connect(func(_d: int, _w: int) -> void: update_music())
    EventBus.item_collected.connect(func(_id: StringName, _n: int, _t: int) -> void: play(&"pegar"))
    EventBus.dialogue_requested.connect(func(_s: String, _l: PackedStringArray, _o: PackedStringArray, _c: Callable) -> void:
        play(&"dialogo"))
    GameState.money_changed.connect(func(m: int) -> void:
        if _money >= 0 and m > _money:
            play(&"moeda")
        _money = m)
    GameState.health_changed.connect(func(h: int, _mx: int) -> void:
        if _health >= 0 and h < _health:
            play(&"dano")
        _health = h)
    GameState.skill_changed.connect(func(skill: StringName, lvl: int, _xp: int) -> void:
        if lvl > int(_levels.get(skill, lvl)):
            play(&"nivel")
        _levels[skill] = lvl)
    Quests.quest_completed.connect(func(_id: String) -> void: play(&"missao"))
