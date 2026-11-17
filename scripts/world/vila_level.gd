class_name VilaLevel
extends Level
## Vila de Santa Pequiria. Em dia de festa monta a decoração e as atrações
## na praça (bandeirinhas, barraca, fogueira, foliões, arquibancada...).

const BARRACA_POS := Vector2(416, 330)
const ATRACAO_POS := Vector2(312, 300)
const ATRACAO2_POS := Vector2(520, 300)

const BARRACA_ITEMS := {
    &"festa_pequi": ["arroz_pequi", "pamonha", "canjica"],
    &"folia_reis": ["canjica", "pao_queijo"],
    &"cavalhadas": ["mascara_cavalhada", "pao_queijo", "canjica"],
    &"festa_junina": ["pamonha", "canjica", "pao_queijo"],
}

var festival: StringName = &""
var festa_root: Node2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    super._ready()
    Clock.day_started.connect(func(_d: int, _w: int) -> void:
        refresh_festival()
        if festival != &"":
            EventBus.show_message("Hoje tem %s na praça da vila!" % Festivals.name_of(festival), 4.0))
    refresh_festival()


func set_active(value: bool) -> void:
    super.set_active(value)
    if value:
        refresh_festival()


## Monta (ou desmonta) a festa conforme o dia.
func refresh_festival() -> void:
    var today := Festivals.today(GameState.day)
    if today == festival and (festa_root != null) == (today != &""):
        return
    festival = today
    if festa_root:
        get_entities_root().remove_child(festa_root)
        festa_root.queue_free()
        festa_root = null
    if festival == &"":
        invalidate_nav()
        return
    festa_root = Node2D.new()
    festa_root.name = "Festa"
    festa_root.y_sort_enabled = true
    get_entities_root().add_child(festa_root)
    var flags := Bandeirinhas.new()
    flags.z_index = 5
    festa_root.add_child(flags)
    var barraca := _prop("barraca", BARRACA_POS, Vector2(30, 8), "Barraca da festa")
    barraca.used.connect(func(_a: Node) -> void:
        EventBus.shop_requested.emit({"title": "Barraca — " + Festivals.name_of(festival),
            "sells": PackedStringArray(BARRACA_ITEMS[festival]), "buys": PackedInt32Array(), "tab": 0}))
    match festival:
        &"festa_pequi":
            _prop("trofeu_pequi", ATRACAO_POS, Vector2(12, 6), "Concurso do pequi").used.connect(
                func(_a: Node) -> void: concurso_pequi())
        &"folia_reis":
            _prop("bandeira_folia", ATRACAO_POS, Vector2(8, 6), "Receber a Folia de Reis").used.connect(
                func(_a: Node) -> void: receber_folia())
        &"cavalhadas":
            _prop("arquibancada", ATRACAO_POS, Vector2(38, 10), "Assistir às Cavalhadas").used.connect(
                func(_a: Node) -> void: assistir_cavalhadas())
        &"festa_junina":
            _prop("fogueira", ATRACAO_POS, Vector2(14, 8), "Dançar a quadrilha").used.connect(
                func(_a: Node) -> void: dancar_quadrilha())
            _prop("barraca", ATRACAO2_POS, Vector2(30, 8), "Pescaria (R$ 10)").used.connect(
                func(_a: Node) -> void: pescaria())
    invalidate_nav()


func _prop(tex: String, pos: Vector2, body: Vector2, prompt: String) -> Prop:
    var p := Prop.new().setup(tex, body, prompt, 20.0)
    p.position = pos
    festa_root.add_child(p)
    return p


func _year_key(id: String) -> String:
    return "%s_ano%d" % [id, Calendar.year(GameState.day)]


func _done_this_year(id: String) -> bool:
    return GameState.has_flag(StringName("festa_" + _year_key(id)))


func _mark_year(id: String) -> void:
    GameState.set_flag(StringName("festa_" + _year_key(id)))
    GameState.add_memory(_year_key(id), "%s, ano %d" % [Festivals.name_of(festival), Calendar.year(GameState.day)])


func _all_friends(amount: int) -> void:
    for n in get_tree().get_nodes_in_group("npc"):
        if is_ancestor_of(n):
            n.friendship += amount


# --- atrações ----------------------------------------------------------------

func concurso_pequi() -> void:
    if _done_this_year("concurso_pequi"):
        EventBus.show_message("Você já é o campeão do pequi deste ano!", 2.5)
        return
    var have := GameState.get_item_count(&"pequi")
    if have < 10:
        EventBus.show_message("Concurso do pequi: traga 10 pequis bonitos (você tem %d)." % have, 3.0)
        return
    GameState.inventory.remove(&"pequi", 10)
    GameState.add_item(&"trofeu_pequi", 1)
    GameState.add_money(300)
    _all_friends(10)
    _mark_year("concurso_pequi")
    EventBus.dialogue_requested.emit("Festa do Pequi", PackedStringArray([
        "E o campeão do pequi deste ano é... a Fazenda do Pequi! Palmas pra ela!",
        "Leva o troféu e R$ 300. Seu avô ganhava esse concurso todo ano, sabia?"]), PackedStringArray(), Callable())


func receber_folia() -> void:
    if _done_this_year("folia_reis"):
        EventBus.show_message("Os foliões já passaram pela sua casa este ano.", 2.5)
        return
    var food := &""
    for i in GameState.inventory.size():
        var id := GameState.inventory.get_item_id(i)
        var it := ItemDB.get_item(id) if id != &"" else null
        if it and it.category == ItemData.Category.FOOD:
            food = id
            break
    if food == &"":
        EventBus.show_message("Os foliões pedem um prato de comida para a jornada. Traga uma comida pronta!", 3.0)
        return
    GameState.inventory.remove(food, 1)
    GameState.set_buff(&"folego")
    _all_friends(15)
    _mark_year("folia_reis")
    EventBus.dialogue_requested.emit("Folia de Reis", PackedStringArray([
        "♪ Ô de casa, ô de fora, os Três Reis chegaram agora... ♪",
        "O mestre da folia agradece o prato e passa a bandeira por cima da sua cabeça.",
        "\"Que essa casa tenha fartura o ano inteiro.\" Você se sente leve (Fôlego até dormir)."]),
        PackedStringArray(), Callable())


func assistir_cavalhadas() -> void:
    var first := not _done_this_year("cavalhadas")
    EventBus.dialogue_requested.emit("Cavalhadas", PackedStringArray([
        "Doze cavaleiros cristãos de azul e doze mouros de vermelho entram no campo ao som da banda.",
        "As lanças se cruzam, os cavalos enfeitados correm, o povo grita a cada argolinha tirada.",
        "Os mascarados passam fazendo graça, com máscaras de boi e flores de papel.",
        "No fim, os mouros se convertem e todos saem juntos. A tradição continua viva mais um ano."]),
        PackedStringArray(), Callable())
    if first:
        _all_friends(10)
        _mark_year("cavalhadas")


func dancar_quadrilha() -> void:
    var first := not _done_this_year("festa_junina")
    EventBus.dialogue_requested.emit("Festa Junina", PackedStringArray([
        "Anarriê! Os pares se juntam em volta da fogueira.",
        "\"Olha a chuva!\" \"É mentira!\" \"Olha a cobra!\" \"É mentira!\"",
        "Caminho da roça, túnel, grande roda... o Seu Benedito ainda dança melhor que todo mundo.",
        "Viva São João! Viva o povo do vale!"]), PackedStringArray(), Callable())
    if first:
        _all_friends(10)
        _mark_year("festa_junina")


## Pescaria de festa junina: paga R$ 10 e tira um prêmio.
func pescaria() -> Variant:
    if not GameState.spend_money(10):
        EventBus.show_message("A pescaria custa R$ 10.", 2.0)
        return null
    _rng.randomize()
    var roll := _rng.randf()
    var prize: StringName = &""
    if roll < 0.4:
        prize = &"pamonha"
    elif roll < 0.65:
        prize = &"doce_leite"
    elif roll < 0.8:
        prize = &"vaso_flores"
    if prize == &"":
        EventBus.show_message("Pescou... um sapato velho! Não foi dessa vez.", 2.5)
    else:
        GameState.add_item(prize, 1)
        EventBus.show_message("Pescou um prêmio: %s!" % ItemDB.get_item(prize).display_name, 2.5)
    return prize
