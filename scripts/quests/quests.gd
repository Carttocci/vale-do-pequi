extends Node
## Missões (autoload "Quests"). Dados em data/quests.json.
##
## Tipos de etapa: talk, deliver, reach, flag, min_flag, kill, observe, collect.
## A história principal (main) começa sozinha e encadeia ("after:<id>");
## as secundárias aparecem no mural da praça ("board") a partir de `min_day`.
## Conversas de etapa (talk/deliver) substituem a fala normal do morador.

signal quest_started(id: String)
signal quest_completed(id: String)
signal quest_updated(id: String)

const DATA_PATH := "res://data/quests.json"

var defs: Dictionary = {}       # id -> definição
var order: Array = []
var active: Dictionary = {}     # id -> índice da etapa atual
var done: Dictionary = {}       # id -> true
var counters: Dictionary = {}   # id -> contador da etapa (kill)


func _ready() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    for q in parsed.quests:
        defs[q.id] = q
        order.append(q.id)
    EventBus.region_entered.connect(func(_r: StringName) -> void: check_all())
    EventBus.enemy_killed.connect(_on_enemy_killed)
    GameState.flag_set.connect(func(_f: StringName) -> void: check_all())
    GameState.journal_changed.connect(check_all)
    GameState.inventory.changed.connect(check_all)
    Clock.time_changed.connect(func(_m: int) -> void: check_all())
    reset()


func reset() -> void:
    active = {}
    done = {}
    counters = {}
    _start_auto()


func is_active(id: String) -> bool:
    return active.has(id)


func is_done(id: String) -> bool:
    return done.has(id)


func step(id: String) -> Dictionary:
    if not active.has(id):
        return {}
    return defs[id].steps[active[id]]


func start(id: String) -> bool:
    if not defs.has(id) or active.has(id) or done.has(id):
        return false
    active[id] = 0
    counters[id] = 0
    quest_started.emit(id)
    EventBus.show_message("Nova missão: %s" % defs[id].title, 3.0)
    check_all()
    return true


## Missões do mural que dá para aceitar hoje.
func board_available() -> Array:
    var out := []
    for id in order:
        var q: Dictionary = defs[id]
        if q.get("start", "") == "board" and not active.has(id) and not done.has(id) \
                and GameState.day >= int(q.get("min_day", 1)):
            out.append(id)
    return out


## Fala de missão para este morador agora (ou {} se nenhuma).
## Retorna {"lines": PackedStringArray, "quest": id}. A conversa conclui a etapa.
func dialogue_for(npc_id: String) -> Dictionary:
    for id in active:
        var s := step(id)
        if s.get("npc", "") != npc_id:
            continue
        if s.type == "talk":
            return {"lines": PackedStringArray(s.lines), "quest": id}
        if s.type == "deliver" and GameState.get_item_count(StringName(s.item)) >= int(s.count):
            return {"lines": PackedStringArray(s.lines), "quest": id}
    return {}


## Chamado pelo morador depois de mostrar a fala da missão.
func finish_talk(id: String) -> void:
    var s := step(id)
    if s.is_empty():
        return
    if s.type == "deliver":
        if not GameState.inventory.remove(StringName(s.item), int(s.count)):
            return
    for item in s.get("give", {}):
        GameState.add_item(StringName(item), int(s.give[item]))
    advance(id)


func advance(id: String) -> void:
    active[id] += 1
    counters[id] = 0
    if active[id] >= defs[id].steps.size():
        _complete(id)
    else:
        quest_updated.emit(id)
        check_all()


## Verifica etapas automáticas (lugar, marco, contadores, caderno, itens).
func check_all() -> void:
    var changed := true
    var guard := 0
    while changed and guard < 20:
        changed = false
        guard += 1
        for id in active.keys():
            if _step_done(id, step(id)):
                advance(id)
                changed = true
                break


func _step_done(id: String, s: Dictionary) -> bool:
    match s.get("type", ""):
        "reach":
            var main := get_tree().get_first_node_in_group("save_root")
            if main == null or main.level == null or String(main.level.region_id) != s.region:
                return false
            var h := Clock.minutes / 60.0
            return h >= float(s.get("from_hour", 0)) and h < float(s.get("to_hour", 99))
        "flag":
            return GameState.has_flag(StringName(s.flag))
        "min_flag":
            return int(GameState.get_flag(StringName(s.flag), 0)) >= int(s.value)
        "kill":
            return int(counters.get(id, 0)) >= int(s.count)
        "observe":
            return GameState.species_seen.size() >= int(s.count)
        "collect":
            return GameState.get_item_count(StringName(s.item)) >= int(s.count)
    return false


func _on_enemy_killed(kind: StringName) -> void:
    for id in active:
        var s := step(id)
        if s.get("type", "") == "kill" and s.enemy == String(kind):
            counters[id] = int(counters.get(id, 0)) + 1
            quest_updated.emit(id)
    check_all()


func _complete(id: String) -> void:
    active.erase(id)
    done[id] = true
    var r: Dictionary = defs[id].get("rewards", {})
    if r.has("money"):
        GameState.add_money(int(r.money))
    for item in r.get("items", {}):
        GameState.add_item(StringName(item), int(r.items[item]))
    for npc_id in r.get("friendship", {}):
        for n in get_tree().get_nodes_in_group("npc"):
            if String(n.data.id) == npc_id:
                n.friendship += int(r.friendship[npc_id])
    if r.has("flag"):
        GameState.set_flag(StringName(r.flag))
    quest_completed.emit(id)
    EventBus.show_message("Missão concluída: %s  (+R$ %d)" % [defs[id].title, int(r.get("money", 0))], 3.5)
    _start_auto()


func _start_auto() -> void:
    for id in order:
        var st: String = defs[id].get("start", "")
        if active.has(id) or done.has(id):
            continue
        if st == "auto" or (st.begins_with("after:") and done.has(st.trim_prefix("after:"))):
            active[id] = 0
            counters[id] = 0
            quest_started.emit(id)


func to_data() -> Dictionary:
    return {"active": active.duplicate(), "done": done.keys(), "counters": counters.duplicate()}


func from_data(d: Dictionary) -> void:
    active = {}
    done = {}
    counters = {}
    for id in d.get("done", []):
        if defs.has(id):
            done[id] = true
    var a: Dictionary = d.get("active", {})
    for id in a:
        if defs.has(id):
            active[id] = clampi(int(a[id]), 0, defs[id].steps.size() - 1)
    var c: Dictionary = d.get("counters", {})
    for id in c:
        counters[id] = int(c[id])
    _start_auto()
