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
    lock_escape_key()
    get_tree().node_added.connect(func(n: Node) -> void:
        if n is Control:
            _pixel_font.call_deferred(n))


## Fonte de pixel só fica nítida no tamanho da grade dela. A Micro 5 é de 11 px:
## texto normal vira 11, texto grande (20+) vira 22. Fonte escolhida a dedo (título) fica.
func _pixel_font(c: Control) -> void:
    if not is_instance_valid(c) or not c.has_theme_font_size_override("font_size"):
        return
    if c.has_theme_font_override("font"):
        return
    var size := c.get_theme_font_size("font_size")
    c.add_theme_font_size_override("font_size", 22 if size >= 20 else 11)


## No navegador, em tela cheia o Esc é do navegador (sai da tela cheia antes de
## chegar no jogo). Com o Keyboard Lock (Chrome/Edge) o Esc vem pro jogo e, pra
## sair da tela cheia, segura o Esc. Firefox/Safari não têm: lá o F11/botão sai.
func lock_escape_key() -> void:
    if not OS.has_feature("web"):
        return
    JavaScriptBridge.eval("""
        (function () {
            var lock = function () {
                if (navigator.keyboard && navigator.keyboard.lock) {
                    navigator.keyboard.lock(['Escape']).catch(function () {});
                }
            };
            lock();
            document.addEventListener('fullscreenchange', lock);
        })();
    """, true)


func is_fullscreen() -> bool:
    return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func toggle_fullscreen() -> void:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen() else DisplayServer.WINDOW_MODE_FULLSCREEN)
    lock_escape_key()


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
