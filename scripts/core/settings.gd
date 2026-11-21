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
const ZOOM_MAX := 3.0
const ZOOM_STEP := 0.25
var camera_zoom: float = 1.75 if DisplayServer.is_touchscreen_available() else 1.0
## Já mexeu no zoom alguma vez? Se não, o celular começa perto do personagem.
var zoom_touched := false




const FONT_SYMBOLS := preload("res://assets/fonts/Simbolos.ttf")
## Fonte de destaque (título, botões do menu, nomes de chefe, cabeçalhos):
## Upheaval, de Brian Kent. Grade de 20 px, só maiúsculas e larga, por isso
## não serve pro texto corrido (que continua na Micro 5).
const FONT_DISPLAY := preload("res://assets/fonts/Upheaval.ttf")
const DISPLAY_GRID := 20


## Põe a fonte de destaque num controle, no múltiplo de 20 mais perto de `size`.
func display_font(c: Control, size: int = DISPLAY_GRID) -> void:
    c.add_theme_font_override("font", FONT_DISPLAY)
    c.add_theme_font_size_override("font_size", maxi(1, roundi(size / float(DISPLAY_GRID))) * DISPLAY_GRID)


func _ready() -> void:
    load_settings()
    lock_escape_key()
    _add_symbol_fallback()
    get_tree().node_added.connect(func(n: Node) -> void:
        if n is Control:
            _pixel_font.call_deferred(n))


## Fonte de pixel só fica nítida no tamanho da grade dela. A Micro 5 é de 11 px:
## texto normal vira 11, texto grande (20+) vira 22. Fonte escolhida a dedo (título) fica.
func _pixel_font(c: Control) -> void:
    if not is_instance_valid(c):
        return
    # caixas com LabelSettings (relógio do HUD) também entram na grade
    if c is Label and (c as Label).label_settings and (c as Label).label_settings.font_size > 0:
        var ls := (c as Label).label_settings
        ls.font_size = 22 if ls.font_size >= 20 else 11
    if not c.has_theme_font_size_override("font_size"):
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
        zoom_touched = bool(cfg.get_value("jogo", "zoom_mexido", false))
    apply()


func save_settings() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("audio", "musica", music_volume)
    cfg.set_value("audio", "efeitos", sfx_volume)
    cfg.set_value("jogo", "dica_missao", show_quest_hint)
    cfg.set_value("jogo", "zoom", camera_zoom)
    cfg.set_value("jogo", "zoom_mexido", zoom_touched)
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


func set_camera_zoom(v: float, snap := true) -> void:
    zoom_touched = true
    camera_zoom = clampf(snappedf(v, ZOOM_STEP) if snap else v, ZOOM_MIN, ZOOM_MAX)
    apply()
    save_settings()


func apply() -> void:
    Audio.set_bus_volume(Audio.BUS_MUSIC, music_volume)
    Audio.set_bus_volume(Audio.BUS_SFX, sfx_volume)
    changed.emit()



## Símbolos (★ ♥ → ✓ ♪ ...) que a fonte principal não tem vêm da fonte de
## símbolos em pixel (tools/gerar_fonte_simbolos.py). Vale pra qualquer fonte do tema.
func _add_symbol_fallback() -> void:
    var fonts: Array[Font] = []
    var theme := ThemeDB.get_project_theme()
    if theme and theme.default_font:
        fonts.append(theme.default_font)
    fonts.append(ThemeDB.fallback_font)
    fonts.append(FONT_DISPLAY)
    for f in fonts:
        if f and not FONT_SYMBOLS in f.fallbacks:
            var list := f.fallbacks.duplicate()
            list.append(FONT_SYMBOLS)
            f.fallbacks = list


func has_glyph(ch: String) -> bool:
    var theme := ThemeDB.get_project_theme()
    var f: Font = theme.default_font if theme and theme.default_font else ThemeDB.fallback_font
    if f.has_char(ch.unicode_at(0)):
        return true
    for fb in f.fallbacks:
        if fb.has_char(ch.unicode_at(0)):
            return true
    return false


# --- versão nova (navegador) ---------------------------------------------------
# O jogo é um app instalável (PWA): o navegador guarda os arquivos e às vezes
# segura a versão velha. Ao abrir, o jogo lê versao.json (sem cache) e, se tiver
# versão nova no site, oferece atualizar: apaga o cache e recarrega a página.

signal update_available(version: String)

var latest_version := ""


func current_version() -> String:
    return str(ProjectSettings.get_setting("application/config/version", ""))


func check_for_update() -> void:
    if not OS.has_feature("web"):
        return
    JavaScriptBridge.eval("""
        window.__valeVersao = '';
        fetch('versao.json?t=' + Date.now(), {cache: 'no-store'})
            .then(r => r.ok ? r.json() : {})
            .then(j => { window.__valeVersao = (j && j.versao) ? String(j.versao) : '-'; })
            .catch(() => { window.__valeVersao = '-'; });
    """, true)
    for i in 100:
        await get_tree().create_timer(0.1).timeout
        var v = JavaScriptBridge.eval("window.__valeVersao", true)
        if v is String and v != "":
            if v != "-" and v != current_version():
                latest_version = v
                update_available.emit(v)
            return


## Apaga o cache do app e recarrega a página com a versão nova.
func update_now() -> void:
    if not OS.has_feature("web"):
        return
    JavaScriptBridge.eval("""
        (async () => {
            try {
                if ('serviceWorker' in navigator) {
                    for (const r of await navigator.serviceWorker.getRegistrations()) await r.unregister();
                }
                if (window.caches) {
                    for (const k of await caches.keys()) await caches.delete(k);
                }
            } catch (e) {}
            location.replace(location.pathname + '?v=' + Date.now());
        })();
    """, true)
