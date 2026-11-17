class_name Npc
extends Node2D
## Morador da vila: segue a rotina do NpcData andando pelo mapa (A* da região),
## conversa (falas por hora, clima, período e amizade) e, se tiver loja,
## oferece Comprar/Vender enquanto está no balcão.

signal arrived(marker: StringName)

const SPEED := 42.0
const FRAMES_PER_DIRECTION := 4
const TALK_FRIENDSHIP := 10
## Pontos de amizade por coração (máximo 10 corações).
const HEART_POINTS := 100
const GIFT_POINTS := {&"love": 80, &"like": 45, &"neutral": 20, &"hate": -20}
const GIFT_LINES := {
    &"love": ["Nossa, %s! É o que eu mais gosto nesse mundo. Muito obrigado!", "Ô trem bão! %s! Você me conhece mesmo."],
    &"like": ["%s? Que agrado! Obrigado.", "Gostei do %s, viu? Brigado."],
    &"neutral": ["Ah, %s. Obrigado pela lembrança.", "Um %s... valeu."],
    &"hate": ["%s?! Isso aí eu não suporto, viu...", "Hum... %s. Não precisava."],
}

@export var data: NpcData

var friendship: int = 0
var met: bool = false
var last_talk_day: int = 0
var gift_day: int = 0
var inside: bool = false

var _path := PackedVector2Array()
var _target_marker: StringName = &""
var _facing: int = 0
var _anim: float = 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var interactable: Interactable = $Interactable


func _ready() -> void:
    add_to_group("npc")
    add_to_group("persistent")
    sprite.texture = data.sprite
    sprite.hframes = 4
    sprite.vframes = data.sheet_rows
    if data.sheet_rows == 1:
        sprite.offset = Vector2(0, -16)
    interactable.prompt = "Conversar com " + data.display_name
    interactable.target_priority = 1
    interactable.interacted.connect(func(_a: Node) -> void: talk())
    Clock.time_changed.connect(func(_m: int) -> void: _follow_schedule())
    Clock.day_started.connect(func(_d: int, _w: int) -> void: snap_to_schedule())
    snap_to_schedule.call_deferred()


func _process(delta: float) -> void:
    if _path.is_empty():
        _anim = 0.0
        _update_frame()
        return
    var target := _path[0]
    var to := target - global_position
    var step := SPEED * delta
    if to.length() <= step:
        global_position = target
        _path.remove_at(0)
        if _path.is_empty():
            _on_arrived()
    else:
        var dir := to.normalized()
        global_position += dir * step
        _facing = Player.direction_to_index(dir)
        _anim += delta
    _update_frame()


func get_level() -> Level:
    var n := get_parent()
    while n and not n is Level:
        n = n.get_parent()
    return n as Level


func is_at_marker(marker: StringName) -> bool:
    var level := get_level()
    var m := level.get_marker(marker) if level else null
    return m != null and not inside and _path.is_empty() and global_position.distance_to(m.global_position) < 4.0


func is_shop_open() -> bool:
    return data.has_shop() and is_at_marker(data.shop_marker)


## Vai direto para onde deveria estar agora (ao carregar, ao trocar de região,
## ao começar o dia).
func snap_to_schedule() -> void:
    var entry := data.schedule_entry_at(GameState.day, Clock.minutes)
    var level := get_level()
    if entry.is_empty() or level == null:
        return
    var m := level.get_marker(entry.marker)
    if m == null:
        push_warning("Npc %s: marcador '%s' não existe" % [data.id, entry.marker])
        return
    _path.clear()
    _target_marker = entry.marker
    global_position = m.global_position
    _set_inside(entry.inside)
    _face_marker(m)


## A cada 10 min de jogo: se a rotina mudou, sai andando para o novo lugar.
func _follow_schedule() -> void:
    var level_now := get_level()
    if level_now == null or not level_now.active:
        return  # região fora de cena: ao voltar, snap_to_schedule() acerta a posição
    var entry := data.schedule_entry_at(GameState.day, Clock.minutes)
    if entry.is_empty() or entry.marker == _target_marker:
        return
    var level := get_level()
    var m := level.get_marker(entry.marker) if level else null
    if m == null:
        return
    _target_marker = entry.marker
    _set_inside(false)
    _path = level.find_path(global_position, m.global_position)
    if _path.is_empty():
        global_position = m.global_position  # sem caminho: não trava a rotina
        _on_arrived()


func _on_arrived() -> void:
    var entry := data.schedule_entry_at(GameState.day, Clock.minutes)
    var level := get_level()
    var m := level.get_marker(_target_marker) if level else null
    if m:
        _face_marker(m)
    if entry.get("marker") == _target_marker and entry.get("inside", false):
        _set_inside(true)
    arrived.emit(_target_marker)


func _set_inside(value: bool) -> void:
    inside = value
    visible = not value
    interactable.enabled = not value


func _face_marker(m: Marker2D) -> void:
    _facing = int(m.get_meta("facing", 0))
    _update_frame()


func _update_frame() -> void:
    if data.sheet_rows == 1:
        sprite.frame = int(Time.get_ticks_msec() / 150) % FRAMES_PER_DIRECTION
        return
    var step := int(_anim * 8.0) % FRAMES_PER_DIRECTION if not _path.is_empty() else 0
    sprite.frame = _facing * FRAMES_PER_DIRECTION + step


# --- conversa ----------------------------------------------------------------

func talk() -> void:
    EventBus.npc_talked.emit(data.id)
    var quest := Quests.dialogue_for(String(data.id))
    if not quest.is_empty():
        met = true
        EventBus.dialogue_requested.emit(data.display_name, quest.lines, PackedStringArray(),
            func(_i: int) -> void: Quests.finish_talk(quest.quest))
        return
    var ev := HeartEvents.pending(String(data.id), hearts())
    if not ev.is_empty() and met:
        EventBus.dialogue_requested.emit(data.display_name, PackedStringArray(ev.lines), PackedStringArray(),
            func(_i: int) -> void: HeartEvents.complete(ev, data.display_name))
        return
    var lines := pick_lines()
    var first_today := last_talk_day != GameState.day
    if first_today:
        friendship += TALK_FRIENDSHIP
        last_talk_day = GameState.day
    met = true
    var options := PackedStringArray()
    if is_shop_open():
        options = PackedStringArray(["Comprar", "Vender", "Tchau"])
    EventBus.dialogue_requested.emit(data.display_name, lines, options, _on_option)


## Escolhe as falas da conversa de agora (sem efeitos colaterais).
func pick_lines() -> PackedStringArray:
    if not met and not data.intro.is_empty():
        return data.intro
    if last_talk_day == GameState.day and not data.lines_repeat.is_empty():
        return PackedStringArray([_pick(data.lines_repeat, 1)])
    var pool := PackedStringArray()
    pool.append_array(data.lines_generic)
    var h := Clock.hour()
    if h < 12:
        pool.append_array(data.lines_morning)
    elif h < 18:
        pool.append_array(data.lines_afternoon)
    else:
        pool.append_array(data.lines_evening)
    if Calendar.period(GameState.day) == Calendar.PERIOD_DRY:
        pool.append_array(data.lines_dry)
    if friendship >= NpcData.FRIEND_THRESHOLD:
        pool.append_array(data.lines_friend)
    # Chuva tem prioridade: é o assunto do dia.
    if Clock.is_raining() and not data.lines_rain.is_empty():
        pool = data.lines_rain
    return PackedStringArray([_pick(pool, 0)])


func _pick(pool: PackedStringArray, salt: int) -> String:
    if pool.is_empty():
        return "..."
    var rng := RandomNumberGenerator.new()
    rng.seed = hash([data.id, GameState.day, salt])
    return pool[rng.randi_range(0, pool.size() - 1)]


func _on_option(index: int) -> void:
    match index:
        0:
            EventBus.shop_requested.emit(_shop_dict(0))
        1:
            EventBus.shop_requested.emit(_shop_dict(1))


func _shop_dict(tab: int) -> Dictionary:
    return {"title": data.shop_title, "sells": data.shop_sells, "buys": data.shop_buys, "tab": tab, "npc": self}


# --- presentes e corações -----------------------------------------------------

func hearts() -> int:
    return clampi(friendship / HEART_POINTS, 0, 10)


## "love", "like", "hate" ou "neutral".
func gift_taste(item_id: StringName) -> StringName:
    var s := String(item_id)
    if s in data.gifts_love:
        return &"love"
    if s in data.gifts_like:
        return &"like"
    if s in data.gifts_hate:
        return &"hate"
    return &"neutral"


func can_receive_gift() -> bool:
    return gift_day != GameState.day


## Recebe 1 unidade do item (o chamador tira da mochila). Retorna o gosto.
func receive_gift(item: ItemData) -> StringName:
    var taste := gift_taste(item.id)
    friendship = maxi(0, friendship + int(GIFT_POINTS[taste]))
    gift_day = GameState.day
    met = true
    var lines: Array = GIFT_LINES[taste]
    var line: String = lines[(GameState.day + String(data.id).length()) % lines.size()]
    EventBus.dialogue_requested.emit(data.display_name,
        PackedStringArray([line % item.display_name.to_lower()]), PackedStringArray(), Callable())
    return taste


# --- save --------------------------------------------------------------------

func get_save_data() -> Dictionary:
    return {"friendship": friendship, "met": met, "last_talk_day": last_talk_day, "gift_day": gift_day}


func load_save_data(d: Dictionary) -> void:
    friendship = maxi(0, int(d.get("friendship", 0)))
    met = bool(d.get("met", false))
    last_talk_day = int(d.get("last_talk_day", 0))
    gift_day = int(d.get("gift_day", 0))
    snap_to_schedule()
