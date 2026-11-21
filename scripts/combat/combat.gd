class_name CombatComponent
extends Node2D
## Combate do jogador (filho do Player): golpes, combo de 3, golpe carregado,
## arco e esquiva. Lê a arma do item selecionado (ItemData com damage > 0).

signal attacked(weapon: ItemData, combo: int, charged: bool)

const COMBO_WINDOW := 0.55
const CHARGE_TIME := 0.6
const DODGE_TIME := 0.18
const DODGE_DIST := 70.0
const DODGE_COOLDOWN := 0.45
const DODGE_ENERGY := 4
const CHARGE_ENERGY := 5

var combo: int = 0
var cooldown: float = 0.0
var dodge_cooldown: float = 0.0
var dodging: float = 0.0
var charge: float = -1.0       # < 0 = não está carregando
var _since_last := 99.0
var _dodge_dir := Vector2.ZERO
var _slash: Sprite2D

@onready var player: Player = get_parent()


func _ready() -> void:
    _slash = Sprite2D.new()
    _slash.texture = load("res://assets/effects/golpe_placeholder.png")
    _slash.visible = false
    add_child(_slash)


func weapon() -> ItemData:
    var item := GameState.get_selected_item()
    return item if item and item.is_weapon() else null


## Botão de atacar sem arma na mão: pega a melhor arma da barra de itens
## (se tiver) e coloca na mão. Sem arma na barra, não ataca.
func equip_best_weapon() -> bool:
    if weapon():
        return true
    var best := -1
    var best_dmg := -1
    for i in GameState.HOTBAR_SIZE:
        var id := GameState.inventory.get_item_id(i)
        var it := ItemDB.get_item(id) if id != &"" else null
        if it and it.is_weapon() and not it.ranged and it.damage > best_dmg:
            best = i
            best_dmg = it.damage
    if best < 0:
        return false
    GameState.select_slot(best)
    return true




func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
    _since_last += delta
    if charge >= 0.0:
        charge += delta
        _slash.visible = charge >= CHARGE_TIME and int(charge * 10) % 2 == 0
        _slash.position = Vector2(0, -10)
    if dodging > 0.0:
        dodging -= delta
        player.velocity = _dodge_dir * (DODGE_DIST / DODGE_TIME)
        player.move_and_slide()
        if dodging <= 0.0:
            player.velocity = Vector2.ZERO
            player.modulate.a = 1.0


func is_invulnerable() -> bool:
    return dodging > 0.0


## Golpe normal (ou flecha). Retorna true se atacou.
func attack() -> bool:
    var w := weapon()
    if w == null or cooldown > 0.0 or dodging > 0.0:
        return false
    if w.ranged:
        return _shoot(w)
    combo = combo + 1 if _since_last <= COMBO_WINDOW and combo < 3 else 1
    _since_last = 0.0
    cooldown = w.attack_cooldown * (0.85 if combo == 3 else 1.0)
    var mult := GameState.melee_multiplier() * (1.6 if combo == 3 else 1.0)
    Audio.play(&"golpe")
    _hit(w, int(round((w.damage + ToolUpgrades.weapon_bonus(w.id)) * mult)), w.knockback * (1.5 if combo == 3 else 1.0), false)
    attacked.emit(w, combo, false)
    return true


## Começa a segurar o botão (golpe carregado ao soltar).
func begin_charge() -> void:
    if weapon() and not weapon().ranged:
        charge = 0.0


## Soltou o botão: se carregou o suficiente, giro que acerta tudo em volta.
func release_charge() -> bool:
    var held := charge
    charge = -1.0
    _slash.visible = false
    var w := weapon()
    if w == null or held < CHARGE_TIME or not GameState.use_energy(CHARGE_ENERGY):
        return false
    cooldown = w.attack_cooldown
    _hit(w, int(round(w.damage * 2.0 * GameState.melee_multiplier())), w.knockback * 1.3, true)
    attacked.emit(w, 0, true)
    return true


func dodge(dir: Vector2) -> bool:
    if dodge_cooldown > 0.0 or dodging > 0.0:
        return false
    var cost := maxi(1, DODGE_ENERGY - int(GameState.paths[&"explorador"]))
    if not GameState.use_energy(cost):
        return false
    _dodge_dir = dir.normalized() if dir != Vector2.ZERO else Player.DIRECTIONS[player.facing_index]
    dodging = DODGE_TIME
    dodge_cooldown = DODGE_COOLDOWN * maxf(0.4, 1.0 - GameState.paths[&"explorador"] * 0.1)
    player.modulate.a = 0.5
    return true


func _hit(w: ItemData, dmg: int, kb: float, spin: bool) -> void:
    var facing := Player.DIRECTIONS[player.facing_index]
    var center := player.global_position + Vector2(0, -6)
    _show_slash(facing, spin)
    var targets := get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("huntable")
    for e in targets:
        var en := e as Node2D
        if not en.is_visible_in_tree() or (en.has_method("is_dead") and en.is_dead()):
            continue
        var to := en.global_position + Vector2(0, -6) - center
        var hit := false
        if spin:
            hit = to.length() <= w.reach * 1.3
        else:
            var along := to.dot(facing)
            var across := absf(to.dot(Vector2(-facing.y, facing.x)))
            hit = along >= -4.0 and along <= w.reach + 8.0 and across <= w.arc_width * 0.75 + 4.0
        if hit:
            en.take_hit(dmg, to if to != Vector2.ZERO else facing, kb, w.stun)
    # mato cai no golpe; machado também derruba árvore e toco
    for f in get_tree().get_nodes_in_group("debris_field"):
        f.slash(center, facing, w.reach * (1.3 if spin else 1.0), w.arc_width * (3.0 if spin else 1.0), w)


func _shoot(w: ItemData) -> bool:
    if GameState.get_item_count(w.ammo_item) <= 0:
        EventBus.show_message("Sem flechas! O Toninho vende." if w.ammo_item == &"flecha"
            else "Sem munição: precisa de %s." % ItemDB.get_item(w.ammo_item).display_name.to_lower(), 2.0)
        return false
    GameState.inventory.remove(w.ammo_item, 1)
    cooldown = w.attack_cooldown
    var dir := Player.DIRECTIONS[player.facing_index]
    var main := get_tree().get_first_node_in_group("save_root")
    var level: Level = main.level if main else null
    var arrow := Arrow.new().setup(dir, int(round(w.damage * GameState.ranged_multiplier())), level)
    if w.ammo_item == &"pedra":
        arrow.get_child(0).texture = load("res://assets/items/pedra_placeholder.png")
        arrow.get_child(0).scale = Vector2(0.5, 0.5)
    arrow.global_position = player.global_position + Vector2(0, -8) + dir * 8.0
    (level.get_entities_root() if level else player.get_parent()).add_child(arrow)
    attacked.emit(w, 1, false)
    return true


func _show_slash(dir: Vector2, spin: bool) -> void:
    _slash.visible = true
    _slash.position = Vector2(0, -8) + dir * 12.0
    _slash.rotation = dir.angle()
    _slash.scale = Vector2(1.6, 1.6) if spin else Vector2.ONE
    var t := create_tween()
    if spin:
        t.tween_property(_slash, "rotation", _slash.rotation + TAU, 0.2)
    else:
        t.tween_interval(0.08)
    t.tween_callback(func() -> void: _slash.visible = false)
