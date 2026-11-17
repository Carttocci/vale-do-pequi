class_name SerraLevel
extends Level
## Serra do Cristal: boca da mina (com "elevador" nos andares 5 e 10) a oeste,
## portal das Ruínas do Cerrado a leste. Pedras e quartzo renascem todo dia.

const ROCK_SPOTS := 12

var mine_entrance: Prop
var portal: Prop
var _rocks_root: Node2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    super._ready()
    mine_entrance = Prop.new().setup("boca_mina", Vector2(56, 12), "Entrar na mina", 22.0)
    mine_entrance.name = "BocaMina"
    mine_entrance.position = Vector2(144, 76)
    mine_entrance.used.connect(func(_a: Node) -> void: open_mine_menu())
    get_entities_root().add_child(mine_entrance)
    portal = Prop.new().setup("portal_ruina_fechado", Vector2(40, 10), "Examinar portal", 22.0)
    portal.name = "PortalRuinas"
    portal.position = Vector2(496, 76)
    portal.used.connect(func(_a: Node) -> void: use_portal())
    get_entities_root().add_child(portal)
    _rocks_root = Node2D.new()
    _rocks_root.name = "Pedras"
    _rocks_root.y_sort_enabled = true
    get_entities_root().add_child(_rocks_root)
    Clock.day_started.connect(func(_d: int, _w: int) -> void: respawn_rocks())
    GameState.flag_set.connect(func(_f: StringName) -> void: _refresh_portal())
    _refresh_portal()


func set_active(value: bool) -> void:
    super.set_active(value)
    if value:
        _refresh_portal()
        if _rocks_root.get_child_count() == 0:
            respawn_rocks()


## Andares que dá para descer direto (o 1 sempre; 5 e 10 depois de alcançados).
func mine_floors_available() -> Array[int]:
    var out: Array[int] = [1]
    var deepest := int(GameState.get_flag(&"mina_fundo", 0))
    for f in [5, 10]:
        if deepest >= f:
            out.append(f)
    return out


func open_mine_menu() -> void:
    var floors := mine_floors_available()
    if floors.size() == 1:
        enter_mine(1)
        return
    var opts := PackedStringArray()
    for f in floors:
        opts.append("Andar %d" % f)
    opts.append("Voltar")
    EventBus.dialogue_requested.emit("Mina do Cristal",
        PackedStringArray(["O velho elevador de corda ainda funciona. Para qual andar?"]), opts,
        func(i: int) -> void:
            if i >= 0 and i < floors.size():
                enter_mine(floors[i]))


func enter_mine(floor_number: int) -> void:
    var main := get_tree().get_first_node_in_group("save_root")
    var mine: MineLevel = main.get_region(&"mina") if main else null
    if mine == null:
        return
    mine.pending_floor = floor_number
    EventBus.region_change_requested.emit(&"mina", &"")


func use_portal() -> void:
    if GameState.has_flag(&"guardiao_derrotado"):
        EventBus.region_change_requested.emit(&"ruinas", &"da_serra")
    else:
        EventBus.show_message("Um portal de pedra antiga, fechado. No centro há um encaixe em forma de coração...", 3.5)


func _refresh_portal() -> void:
    if portal == null:
        return
    var open := GameState.has_flag(&"guardiao_derrotado")
    portal.set_texture("portal_ruina_aberto" if open else "portal_ruina_fechado")
    portal.interactable.prompt = "Entrar nas ruínas" if open else "Examinar portal"


func respawn_rocks() -> void:
    if _rocks_root == null:
        return
    for c in _rocks_root.get_children():
        _rocks_root.remove_child(c)
        c.queue_free()
    _rng.seed = hash(["serra", GameState.day])
    var placed := 0
    var tries := 0
    while placed < ROCK_SPOTS and tries < 400:
        tries += 1
        var cell := Vector2i(_rng.randi_range(3, 36), _rng.randi_range(10, 20))
        var ch := ground.get_cell_atlas_coords(cell).x
        if ch in [3, 11]:  # trilha e rocha ficam livres
            continue
        var pos := ground.map_to_local(cell) + Vector2(0, 6)
        if pos.distance_to(get_spawn_position(&"da_mata")) < 40:
            continue
        var r := Rock.new()
        var roll := _rng.randf()
        r.kind = &"quartzo" if roll < 0.25 else (&"ferro" if roll < 0.5 else &"pedra")
        r.position = pos
        _rocks_root.add_child(r)
        placed += 1
    invalidate_nav()
