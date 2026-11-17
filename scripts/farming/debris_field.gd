class_name DebrisField
extends Node2D
## Fazenda bagunçada: mato, galhos, pedrinhas, árvores e tocos espalhados
## pela grama. Tudo que sai daqui vira recurso:
##   mato      → E arranca (ou enxada, ou golpe de arma)       → às vezes semente
##   galho     → E pega                                          → galho
##   pedrinha  → E pega (ou picareta)                            → pedra
##   árvore    → machado (E ou golpe), 5 golpes                  → madeira + galho, fica o toco
##   toco      → machado, 3 golpes                               → madeira
##   pedra grande → picareta, 4 golpes                          → pedras (às vezes minério)
## Galho, árvore, toco e pedra grande bloqueiam a passagem.
## Todo dia nasce mais mato e cai galho das árvores. Salva tudo (grupo persistent).

const KINDS := {
    &"mato": {"tex": "mato", "hp": 1, "solid": false, "prompt": "Arrancar mato"},
    &"galho": {"tex": "galho", "hp": 1, "solid": true, "prompt": "Pegar galho"},
    &"pedrinha": {"tex": "pedrinha", "hp": 1, "solid": false, "prompt": "Pegar pedra"},
    &"arvore": {"tex": "arvore_cerrado", "hp": 5, "solid": true, "prompt": "Cortar árvore"},
    &"toco": {"tex": "toco", "hp": 3, "solid": true, "prompt": "Arrancar toco"},
    &"pedra_grande": {"tex": "pedra_grande", "hp": 4, "solid": true, "prompt": "Quebrar pedra grande"},
}
## Chance por célula de grama livre no jogo novo.
const DENSITY := {&"mato": 0.16, &"galho": 0.035, &"pedrinha": 0.025, &"arvore": 0.035, &"pedra_grande": 0.02}
const GRASS_TILES := [0, 1, 2]
const DAILY_WEEDS := 4
const DAILY_TWIGS := 2
const MAX_WEEDS := 320
const SAFE_RADIUS := 3  # células livres em volta da porta, do baú, do poço...

@export var ground_path: NodePath = ^"../../Ground"

var ground: FarmGround
var cells: Dictionary = {}      # Vector2i -> {"kind", "hp", "node"}
var _rng := RandomNumberGenerator.new()
var _loaded := false
## Testes antigos precisam de fazenda limpa e sem mato nascendo.
var growth_enabled := true
var _safe_points: Array[Vector2] = []


## Portas, baú, poço, fogão, saídas... ficam com um respiro sem bagunça.
func _collect_safe_points() -> void:
    _safe_points.clear()
    var level := _level()
    if level == null:
        return
    for n in level.find_children("*", "Area2D", true, false):
        if n is Interactable or n is RegionExit:
            _safe_points.append((n as Node2D).global_position)


func _ready() -> void:
    add_to_group("item_target")
    add_to_group("cell_interaction")
    add_to_group("debris_field")
    add_to_group("persistent")
    y_sort_enabled = true
    ground = get_node(ground_path) as FarmGround
    Clock.day_started.connect(func(_d: int, _w: int) -> void: grow_daily())
    _generate_if_new.call_deferred()


## Jogo novo (ou save antigo sem bagunça salva): espalha depois que o save carregou.
func _generate_if_new() -> void:
    if not _loaded and cells.is_empty():
        generate()


func _level() -> Level:
    var n := get_parent()
    while n and not n is Level:
        n = n.get_parent()
    return n as Level


# --- consulta ------------------------------------------------------------------

func cell_at(pos: Vector2) -> Vector2i:
    return ground.local_to_map(ground.to_local(pos))


func kind_at(cell: Vector2i) -> StringName:
    return cells[cell].kind if cells.has(cell) else &""


func count(kind: StringName) -> int:
    return cells.values().filter(func(c: Dictionary) -> bool: return c.kind == kind).size()


func is_blocked(cell: Vector2i) -> bool:
    return cells.has(cell)


func _here() -> bool:
    var level := _level()
    return level == null or level.active


# --- ações com a mão (botão E) --------------------------------------------------------

func get_cell_prompt(pos: Vector2) -> String:
    if not _here():
        return ""
    var k := kind_at(cell_at(pos))
    if k in [&"mato", &"galho", &"pedrinha"]:
        return KINDS[k].prompt
    return ""


func interact_cell(pos: Vector2, _actor: Node) -> bool:
    if not _here():
        return false
    var cell := cell_at(pos)
    var k := kind_at(cell)
    if not k in [&"mato", &"galho", &"pedrinha"]:
        return false
    if k == &"mato" and not GameState.use_energy(1):
        return false
    _clear(cell, true)
    return true


# --- ações com ferramenta ------------------------------------------------------------

func get_item_action(item: ItemData, pos: Vector2, _actor: Node) -> Dictionary:
    if item == null or not _here():
        return {}
    var k := kind_at(cell_at(pos))
    if k in [&"arvore", &"toco"]:
        if item.id == &"machado":
            return {"prompt": KINDS[k].prompt, "priority": 20}
        return {}
    if k == &"mato" and item.tool_type == ItemData.ToolType.HOE:
        return {"prompt": "Capinar mato", "priority": 20}
    if k == &"pedrinha" and item.tool_type == ItemData.ToolType.PICKAXE:
        return {"prompt": "Quebrar pedra", "priority": 20}
    if k == &"pedra_grande" and item.tool_type == ItemData.ToolType.PICKAXE:
        return {"prompt": KINDS[k].prompt, "priority": 20}
    return {}


func use_item(item: ItemData, pos: Vector2, _actor: Node) -> bool:
    if get_item_action(item, pos, null).is_empty():
        return false
    var cell := cell_at(pos)
    var k := kind_at(cell)
    if k in [&"arvore", &"toco", &"pedra_grande"]:
        if not GameState.use_energy(2):
            return false
        hit(cell, 1)
        return true
    if not GameState.use_energy(1):
        return false
    _clear(cell, true)
    return true


## Golpe de arma (Combat): corta mato no arco; o machado também derruba árvore.
func slash(center: Vector2, facing: Vector2, reach: float, width: float, weapon: ItemData) -> int:
    if not _here():
        return 0
    var hits := 0
    for cell in cells.keys():
        var to := ground.to_global(ground.map_to_local(cell)) - center
        var along := to.dot(facing)
        var across := absf(to.dot(Vector2(-facing.y, facing.x)))
        if along < -4.0 or along > reach + 8.0 or across > width * 0.75 + 6.0:
            continue
        var k: StringName = cells[cell].kind
        if k == &"mato":
            _clear(cell, true)
            hits += 1
        elif k in [&"arvore", &"toco"] and weapon and weapon.id == &"machado":
            hit(cell, 1)
            hits += 1
    return hits


## Machadada numa árvore/toco.
func hit(cell: Vector2i, power: int) -> void:
    if not cells.has(cell):
        return
    var c: Dictionary = cells[cell]
    c.hp -= power
    Audio.play(&"picareta" if c.kind == &"pedra_grande" else &"acerto")
    var node: Node2D = c.node
    var t := node.create_tween()
    node.position.x += 1
    t.tween_property(node, "position:x", node.position.x - 1, 0.1)
    if c.hp > 0:
        return
    GameState.add_xp(&"coleta", 6)
    if c.kind == &"arvore":
        _drop(cell, &"madeira", _rng.randi_range(3, 5))
        _drop(cell, &"galho", _rng.randi_range(1, 2))
        _remove(cell)
        _add(cell, &"toco")
        EventBus.show_message("Timbeeer! A árvore caiu.", 1.5)
    elif c.kind == &"pedra_grande":
        _drop(cell, &"pedra", _rng.randi_range(3, 5))
        if _rng.randf() < 0.25:
            _drop(cell, &"minerio_ferro", 1)
        GameState.add_xp(&"mineracao", 5)
        Audio.play(&"pedra_quebra")
        _remove(cell)
    else:
        _drop(cell, &"madeira", _rng.randi_range(1, 2))
        _remove(cell)


func _clear(cell: Vector2i, give: bool) -> void:
    var k: StringName = cells[cell].kind
    _remove(cell)
    if not give:
        return
    match k:
        &"mato":
            Audio.play(&"capinar")
            GameState.add_xp(&"coleta", 1)
            if randf() < 0.05:
                GameState.add_item(&"semente_milho", 1)
        &"galho":
            GameState.add_item(&"galho", 1)
            GameState.add_xp(&"coleta", 1)
        &"pedrinha":
            GameState.add_item(&"pedra", 1)
            GameState.add_xp(&"coleta", 1)


func _drop(cell: Vector2i, item: StringName, n: int) -> void:
    if n <= 0:
        return
    var pk := Pickup.new().setup(item, n)
    pk.position = ground.map_to_local(cell) + Vector2(_rng.randf_range(-5, 5), 6)
    add_child(pk)


# --- criar / remover ------------------------------------------------------------------

func _add(cell: Vector2i, kind: StringName, hp: int = -1) -> void:
    var info: Dictionary = KINDS[kind]
    var body := StaticBody2D.new()
    body.position = ground.map_to_local(cell) + Vector2(0, 6)
    body.collision_layer = 1 if info.solid else 0
    body.collision_mask = 0
    var sp := Sprite2D.new()
    sp.texture = load("res://assets/environments/%s_placeholder.png" % info.tex)
    sp.offset = Vector2(0, -sp.texture.get_height() / 2.0 + 1)
    body.add_child(sp)
    if info.solid:
        var shape := CollisionShape2D.new()
        var r := RectangleShape2D.new()
        r.size = {&"arvore": Vector2(12, 6), &"galho": Vector2(14, 8), &"pedra_grande": Vector2(16, 10)}.get(kind, Vector2(12, 8))
        shape.shape = r
        shape.position = Vector2(0, -3)
        body.add_child(shape)
    add_child(body)
    cells[cell] = {"kind": kind, "hp": hp if hp > 0 else int(info.hp), "node": body}


func _remove(cell: Vector2i) -> void:
    if not cells.has(cell):
        return
    var node: Node = cells[cell].node
    cells.erase(cell)
    node.queue_free()


func clear_all() -> void:
    for cell in cells.keys():
        _remove(cell)


## Célula de grama livre (sem chão especial, sem roça, sem objeto em volta).
func is_free(cell: Vector2i, field: FarmField = null) -> bool:
    if cells.has(cell) or ground.get_cell_source_id(cell) == -1:
        return false
    if not ground.get_cell_atlas_coords(cell).x in GRASS_TILES:
        return false
    if field and field.cells.has(cell):
        return false
    var level := _level()
    if level == null:
        return true
    var world := ground.to_global(ground.map_to_local(cell))
    if not level.is_walkable(world):
        return false
    for p: Vector2 in _safe_points:
        if p.distance_to(world) < SAFE_RADIUS * 16:
            return false
    var spawn := level.get_spawn_position(&"")
    return spawn.distance_to(world) >= SAFE_RADIUS * 16


## Jogo novo: espalha a bagunça (semente fixa = toda fazenda começa igual).
func generate(seed: int = 42) -> void:
    clear_all()
    _collect_safe_points()
    _rng.seed = seed
    var field := _field()
    var size := ground.get_used_rect()
    for y in range(size.position.y, size.end.y):
        for x in range(size.position.x, size.end.x):
            var cell := Vector2i(x, y)
            if not is_free(cell, field):
                continue
            var roll := _rng.randf()
            var acc := 0.0
            for k: StringName in DENSITY:
                acc += DENSITY[k]
                if roll < acc:
                    if k in [&"arvore", &"pedra_grande"] and _has_tree_near(cell):
                        break
                    _add(cell, k)
                    break
    var level := _level()
    if level:
        level.invalidate_nav()


func _has_tree_near(cell: Vector2i) -> bool:
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            if kind_at(cell + Vector2i(dx, dy)) in [&"arvore", &"toco", &"pedra_grande"]:
                return true
    return false


## Todo dia: mato novo aqui e ali, e galho caído perto das árvores.
func grow_daily() -> void:
    if not growth_enabled:
        return
    _rng.seed = hash(["mato", GameState.day])
    _collect_safe_points()
    var field := _field()
    var size := ground.get_used_rect()
    var weeds := 0
    var tries := 0
    while weeds < DAILY_WEEDS and count(&"mato") < MAX_WEEDS and tries < 200:
        tries += 1
        var cell := Vector2i(_rng.randi_range(size.position.x, size.end.x - 1), _rng.randi_range(size.position.y, size.end.y - 1))
        if is_free(cell, field):
            _add(cell, &"mato")
            weeds += 1
    var trees := cells.keys().filter(func(c: Vector2i) -> bool: return cells[c].kind == &"arvore")
    for i in mini(DAILY_TWIGS, trees.size()):
        var t: Vector2i = trees[_rng.randi() % trees.size()]
        for attempt in 8:  # cai em volta da árvore, onde tiver grama livre
            var cell: Vector2i = t + Vector2i(_rng.randi_range(-2, 2), _rng.randi_range(-1, 2))
            if is_free(cell, field):
                _add(cell, &"galho")
                break


func _field() -> FarmField:
    var level := _level()
    return level.get_node_or_null("FarmField") as FarmField if level else null


# --- save -------------------------------------------------------------------------

func get_save_data() -> Dictionary:
    var list := []
    for cell: Vector2i in cells:
        list.append([cell.x, cell.y, String(cells[cell].kind), int(cells[cell].hp)])
    return {"cells": list}


func load_save_data(d: Dictionary) -> void:
    _loaded = true
    clear_all()
    for e in d.get("cells", []):
        if KINDS.has(StringName(e[2])):
            _add(Vector2i(int(e[0]), int(e[1])), StringName(e[2]), int(e[3]))
