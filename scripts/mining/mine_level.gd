class_name MineLevel
extends Level
## Mina abandonada da Serra do Cristal: andares 1 a 10 gerados na hora
## (caverna por autômato celular, sempre conectada). Minérios mudam com a
## profundidade; o andar 10 é a arena do Guardião de Cristal.
## O andar mais fundo alcançado fica em GameState ("mina_fundo").

const W := 40
const H := 23
const LAST_FLOOR := 10

var floor_number: int = 0
var pending_floor: int = 1
var ladder_down: Prop
var ladder_up: Prop
var boss: Boss

var _spawn := Vector2(320, 300)
var _dyn: Node2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    save_as_region = &"serra"
    save_as_spawn = &"da_mina"
    super._ready()


func set_active(value: bool) -> void:
    super.set_active(value)
    if value:
        build_floor(pending_floor)


func get_spawn_position(_spawn_name: StringName = &"") -> Vector2:
    return _spawn


## Monta o andar `n` do zero (chão, pedras, inimigos, escadas).
func build_floor(n: int) -> void:
    floor_number = clampi(n, 1, LAST_FLOOR)
    pending_floor = floor_number
    if _dyn:
        get_entities_root().remove_child(_dyn)
        _dyn.queue_free()
    _dyn = Node2D.new()
    _dyn.name = "Andar"
    _dyn.y_sort_enabled = true
    get_entities_root().add_child(_dyn)
    boss = null
    ladder_down = null
    display_name = "Mina do Cristal — andar %d" % floor_number
    if int(GameState.get_flag(&"mina_fundo", 0)) < floor_number:
        GameState.set_flag(&"mina_fundo", floor_number)
    _rng.seed = hash(["mina", floor_number, GameState.day])
    if floor_number == LAST_FLOOR:
        _build_arena()
    else:
        _build_cave()
    invalidate_nav()
    _refresh_nav_later()


func _refresh_nav_later() -> void:
    await get_tree().physics_frame
    invalidate_nav()


# --- caverna -----------------------------------------------------------------

func _build_cave() -> void:
    var cells := _cave_cells()
    var floor_cells: Array = cells[0]
    var dist: Dictionary = cells[1]
    var start: Vector2i = cells[2]
    var far := start
    for c in dist:
        if dist[c] > dist[far]:
            far = c
    ground.load_from_text(_to_text(cells[3]))
    _spawn = ground.map_to_local(start)
    ladder_up = _add_ladder(false, _spawn + Vector2(0, -12))
    ladder_down = _add_ladder(true, ground.map_to_local(far))
    var free: Array = floor_cells.filter(func(c: Vector2i) -> bool:
        return dist.get(c, 0) > 6 and c.distance_to(far) > 2)
    _shuffle(free)
    var n_rocks := 14 + floor_number * 2
    for i in mini(n_rocks, free.size()):
        var r := Rock.new()
        r.kind = _ore_for_depth()
        r.position = ground.map_to_local(free[i]) + Vector2(0, 6)
        _dyn.add_child(r)
    var n_enemies := 2 + floor_number / 2
    for i in n_enemies:
        var idx := n_rocks + i
        if idx >= free.size():
            break
        var e := Enemy.new().setup(_enemy_for_depth(), ground.map_to_local(free[idx]), self, 1.0 + floor_number * 0.12)
        _dyn.add_child(e)


func _ore_for_depth() -> StringName:
    var roll := _rng.randf()
    if floor_number <= 3:
        return &"ferro" if roll < 0.3 else &"pedra"
    if floor_number <= 6:
        return &"quartzo" if roll < 0.25 else (&"ferro" if roll < 0.55 else &"pedra")
    if roll < 0.08:
        return &"cristal"
    if roll < 0.22:
        return &"ouro"
    return &"quartzo" if roll < 0.45 else (&"ferro" if roll < 0.65 else &"pedra")


func _enemy_for_depth() -> StringName:
    var pool: Array[StringName] = [&"morcego", &"lodo_cinza"]
    if floor_number >= 4:
        pool.append(&"raiz_torta")
    if floor_number >= 7:
        pool.append(&"javali_corrompido")
    return pool[_rng.randi() % pool.size()]


## [células livres, distâncias desde a entrada, entrada, grade]
func _cave_cells() -> Array:
    for attempt in 20:
        var g := []
        for y in H:
            var row := []
            for x in W:
                var border := x < 1 or y < 1 or x >= W - 1 or y >= H - 1
                row.append(true if border else _rng.randf() < 0.42)
            g.append(row)
        for i in 4:
            g = _smooth(g)
        var start := Vector2i(-1, -1)
        for tries in 200:
            var c := Vector2i(_rng.randi_range(3, W - 4), _rng.randi_range(H - 7, H - 3))
            if not g[c.y][c.x]:
                start = c
                break
        if start.x < 0:
            continue
        var dist := _bfs(g, start)
        if dist.size() < 260:
            continue
        # tudo que não se alcança vira rocha; garante 3x3 livre na entrada
        for y in H:
            for x in W:
                if not dist.has(Vector2i(x, y)):
                    g[y][x] = true
        return [dist.keys(), dist, start, g]
    # plano B: salão retangular
    var g2 := []
    for y in H:
        var row := []
        for x in W:
            row.append(x < 2 or y < 2 or x >= W - 2 or y >= H - 2)
        g2.append(row)
    var s := Vector2i(4, H - 4)
    var d := _bfs(g2, s)
    return [d.keys(), d, s, g2]


func _smooth(g: Array) -> Array:
    var out := []
    for y in H:
        var row := []
        for x in W:
            if x < 1 or y < 1 or x >= W - 1 or y >= H - 1:
                row.append(true)
                continue
            var walls := 0
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    if g[y + dy][x + dx]:
                        walls += 1
            row.append(walls >= 5)
        out.append(row)
    return out


func _bfs(g: Array, start: Vector2i) -> Dictionary:
    var dist := {start: 0}
    var queue: Array[Vector2i] = [start]
    while not queue.is_empty():
        var c: Vector2i = queue.pop_front()
        for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var n: Vector2i = c + d
            if n.x < 0 or n.y < 0 or n.x >= W or n.y >= H or g[n.y][n.x] or dist.has(n):
                continue
            dist[n] = dist[c] + 1
            queue.append(n)
    return dist


func _to_text(g: Array) -> String:
    var lines := PackedStringArray()
    for y in H:
        var s := ""
        for x in W:
            s += "r" if g[y][x] else "c"
        lines.append(s)
    return "\n".join(lines)


func _shuffle(arr: Array) -> void:
    for i in range(arr.size() - 1, 0, -1):
        var j := _rng.randi_range(0, i)
        var t: Variant = arr[i]
        arr[i] = arr[j]
        arr[j] = t


# --- andar 10: arena do Guardião ----------------------------------------------

func _build_arena() -> void:
    var g := []
    var center := Vector2(W / 2.0, H / 2.0)
    for y in H:
        var row := []
        for x in W:
            var d := Vector2((x + 0.5 - center.x) / 17.0, (y + 0.5 - center.y) / 9.5)
            row.append(d.length() > 1.0)
        g.append(row)
    ground.load_from_text(_to_text(g))
    _spawn = ground.map_to_local(Vector2i(W / 2, H - 4))
    ladder_up = _add_ladder(false, _spawn + Vector2(0, -12))
    if not GameState.has_flag(&"guardiao_derrotado"):
        boss = Boss.new().setup(&"guardiao_cristal", ground.map_to_local(Vector2i(W / 2, 7)), self) as Boss
        boss.died.connect(func(_e: Enemy) -> void:
            GameState.set_flag(&"guardiao_derrotado")
            EventBus.show_message("O Guardião se desfaz em pó de cristal. Algo pulsa no chão...", 3.5))
        _dyn.add_child(boss)
        EventBus.show_message("O chão treme... o Guardião de Cristal desperta!", 3.0)
        Audio.play(&"chefe")
    else:
        for i in 6:
            var r := Rock.new()
            r.kind = &"cristal" if i < 2 else &"ouro"
            r.position = ground.map_to_local(Vector2i(14 + i * 2, 8)) + Vector2(0, 6)
            _dyn.add_child(r)


# --- escadas -----------------------------------------------------------------

func _add_ladder(down: bool, pos: Vector2) -> Prop:
    var p := Prop.new().setup("escada_desce" if down else "escada_sobe", Vector2.ZERO,
        ("Descer para o andar %d" % (floor_number + 1)) if down else "Subir para a serra", 12.0)
    p.position = pos
    p.used.connect(func(_a: Node) -> void:
        if down:
            go_down()
        else:
            EventBus.region_change_requested.emit(&"serra", &"da_mina"))
    _dyn.add_child(p)
    return p


func go_down() -> void:
    build_floor(floor_number + 1)
    var player := get_tree().get_first_node_in_group("player") as Player
    if player:
        player.global_position = _spawn
        player.velocity = Vector2.ZERO
        player.camera.reset_smoothing()
    EventBus.show_message(display_name, 2.0)
    EventBus.region_entered.emit(region_id)


## Inimigos vivos no andar (testes e chefe).
func enemies() -> Array:
    return _dyn.get_children().filter(func(c: Node) -> bool: return c is Enemy and not c.is_dead()) if _dyn else []


func rocks() -> Array:
    return _dyn.get_children().filter(func(c: Node) -> bool: return c is Rock and not c.is_broken()) if _dyn else []
