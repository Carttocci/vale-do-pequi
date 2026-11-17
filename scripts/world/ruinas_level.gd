class_name RuinasLevel
extends Level
## Ruínas do Cerrado: três totens (sol, lua, chuva) que precisam ser acesos na
## ordem do mural; isso abre o selo da câmara do fundo, onde o Eco do Silêncio
## espera. Depois dele, a Mãe-do-Ouro aparece (fim do Ato 1).

const ORDER: Array[StringName] = [&"sol", &"chuva", &"lua"]
const TOTEM_POS := {&"sol": Vector2(160, 240), &"chuva": Vector2(480, 240), &"lua": Vector2(320, 296)}
const MURAL_TEXT := "Mural antigo: \"Primeiro o sol acorda a terra. Depois a chuva a alimenta. Por fim a lua guarda o sono.\""

var totems: Dictionary = {}     # nome -> Prop
var lit: Array[StringName] = []
var seal: Prop
var mae_do_ouro: Npc
var boss: Boss


func _ready() -> void:
    save_as_region = &"serra"
    save_as_spawn = &"das_ruinas"
    super._ready()
    var root := get_entities_root()
    for t: StringName in TOTEM_POS:
        var p := Prop.new().setup("totem_%s_off" % t, Vector2(12, 8), "Tocar totem", 14.0)
        p.name = "Totem_" + String(t)
        p.position = TOTEM_POS[t]
        p.used.connect(func(_a: Node) -> void: touch_totem(t))
        root.add_child(p)
        totems[t] = p
    var mural := Prop.new().setup("mural", Vector2(28, 8), "Ler mural", 16.0)
    mural.name = "Mural"
    mural.position = Vector2(256, 212)
    mural.used.connect(func(_a: Node) -> void: EventBus.show_message(MURAL_TEXT, 4.5))
    root.add_child(mural)
    seal = Prop.new().setup("pedregulho", Vector2(32, 32), "", 0.0)
    seal.name = "Selo"
    seal.position = Vector2(320, 192)
    seal.sprite.scale = Vector2(2, 2)
    seal.sprite.modulate = Color(0.6, 0.55, 0.85)
    root.add_child(seal)
    mae_do_ouro = (load("res://scenes/npc/npc.tscn") as PackedScene).instantiate() as Npc
    mae_do_ouro.name = "MaeDoOuro"
    mae_do_ouro.data = load("res://data/npcs/mae_do_ouro.tres")
    mae_do_ouro.position = Vector2(320, 72)
    root.add_child(mae_do_ouro)
    var trigger := Area2D.new()
    trigger.name = "Camara"
    trigger.collision_layer = 0
    trigger.collision_mask = 2
    trigger.position = Vector2(320, 104)
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(380, 96)
    shape.shape = rect
    trigger.add_child(shape)
    trigger.body_entered.connect(func(b: Node) -> void:
        if b is Player:
            enter_chamber())
    add_child(trigger)
    GameState.flag_set.connect(func(_f: StringName) -> void: refresh())
    refresh()


func set_active(value: bool) -> void:
    super.set_active(value)
    if value:
        lit.clear()
        refresh()


## Ajusta selo, totens e a Mãe-do-Ouro conforme os marcos da história.
func refresh() -> void:
    if seal == null:
        return
    var solved := GameState.has_flag(&"totens_resolvidos")
    seal.visible = not solved
    seal.set_solid(not solved)
    for t: StringName in totems:
        var on := solved or t in lit
        (totems[t] as Prop).set_texture("totem_%s_%s" % [t, "on" if on else "off"])
    var appear := GameState.has_flag(&"eco_derrotado")
    mae_do_ouro.visible = appear
    mae_do_ouro.interactable.enabled = appear
    invalidate_nav()


func touch_totem(t: StringName) -> void:
    if GameState.has_flag(&"totens_resolvidos") or t in lit:
        return
    if ORDER[lit.size()] == t:
        lit.append(t)
        if lit.size() == ORDER.size():
            GameState.set_flag(&"totens_resolvidos")
            EventBus.show_message("Os três totens brilham juntos. O selo da câmara se desfaz!", 3.5)
        else:
            EventBus.show_message("O totem acende com um zumbido baixo.", 2.0)
    else:
        lit.clear()
        EventBus.show_message("Os totens se apagam todos. A ordem não era essa...", 2.5)
    refresh()


func enter_chamber() -> void:
    if not GameState.has_flag(&"totens_resolvidos") or GameState.has_flag(&"eco_derrotado"):
        return
    if boss and is_instance_valid(boss) and not boss.is_dead():
        return
    boss = Boss.new().setup(&"eco_silencio", Vector2(320, 64), self) as Boss
    boss.died.connect(func(_e: Enemy) -> void:
        GameState.set_flag(&"eco_derrotado")
        EventBus.show_message("O eco se desfaz em silêncio... e uma luz dourada surge no fundo da câmara.", 4.0))
    get_entities_root().add_child(boss)
    EventBus.show_message("O ar fica pesado e sem som. Algo sem rosto se forma na sua frente!", 3.0)
