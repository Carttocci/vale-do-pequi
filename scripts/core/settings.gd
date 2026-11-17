extends Node
## Opções do jogador (autoload "Settings"): volume da música e dos efeitos,
## tela cheia. Ficam em user://opcoes.cfg, separadas do save do jogo.

signal changed

var path := "user://opcoes.cfg"
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var show_quest_hint: bool = true
## Zoom da câmera (1 = visão normal). No celular começa mais perto do personagem.
const ZOOM_MIN := 1.0
const ZOOM_MAX := 2.5
const ZOOM_STEP := 0.25
var camera_zoom: float = 1.75 if DisplayServer.is_touchscreen_available() else 1.0


func _ready() -> void:
    load_settings()


func load_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(path) == OK:
        music_volume = clampf(float(cfg.get_value("audio", "musica", music_volume)), 0.0, 1.0)
        sfx_volume = clampf(float(cfg.get_value("audio", "efeitos", sfx_volume)), 0.0, 1.0)
        show_quest_hint = bool(cfg.get_value("jogo", "dica_missao", show_quest_hint))
        camera_zoom = clampf(float(cfg.get_value("jogo", "zoom", camera_zoom)), ZOOM_MIN, ZOOM_MAX)
    apply()


func save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "musica", music_volume)
    cfg.set_value("audio", "efeitos", sfx_volume)
    cfg.set_value("jogo", "dica_missao", show_quest_hint)
    cfg.set_value("jogo", "zoom", camera_zoom)
    cfg.save(path)


func set_music_volume(v: float) -> void:
    music_volume = clampf(v, 0.0, 1.0)
    apply()
    save_settings()


func set_sfx_volume(v: float) -> void:
    sfx_volume = clampf(v, 0.0, 1.0)
    apply()
    save_settings()


func set_show_quest_hint(v: bool) -> void:
    show_quest_hint = v
    apply()
    save_settings()


func set_camera_zoom(v: float) -> void:
    camera_zoom = clampf(snappedf(v, ZOOM_STEP), ZOOM_MIN, ZOOM_MAX)
    apply()
    save_settings()


func apply() -> void:
    Audio.set_bus_volume(Audio.BUS_MUSIC, music_volume)
    Audio.set_bus_volume(Audio.BUS_SFX, sfx_volume)
    changed.emit()
