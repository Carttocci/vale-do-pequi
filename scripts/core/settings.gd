extends Node
## Opções do jogador (autoload "Settings"): volume da música e dos efeitos,
## tela cheia. Ficam em user://opcoes.cfg, separadas do save do jogo.

signal changed

var path := "user://opcoes.cfg"
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var show_quest_hint: bool = true


func _ready() -> void:
    load_settings()


func load_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(path) == OK:
        music_volume = clampf(float(cfg.get_value("audio", "musica", music_volume)), 0.0, 1.0)
        sfx_volume = clampf(float(cfg.get_value("audio", "efeitos", sfx_volume)), 0.0, 1.0)
        show_quest_hint = bool(cfg.get_value("jogo", "dica_missao", show_quest_hint))
    apply()


func save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "musica", music_volume)
    cfg.set_value("audio", "efeitos", sfx_volume)
    cfg.set_value("jogo", "dica_missao", show_quest_hint)
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


func apply() -> void:
    Audio.set_bus_volume(Audio.BUS_MUSIC, music_volume)
    Audio.set_bus_volume(Audio.BUS_SFX, sfx_volume)
    changed.emit()
