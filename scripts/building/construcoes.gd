class_name Construcoes
extends RefCounted
## Catálogo do modo construção (B): o que dá pra construir na fazenda, quanto
## custa e o que precisa pra liberar. Cada peça ocupa um quadrado.
##   cost  — itens gastos (devolve metade ao recolher)
##   money — dinheiro gasto (não volta)
##   req   — {"skill": [habilidade, nível]} e/ou {"flag": flag, "flag_text": texto}
##   max   — quantas dá pra ter (0 = sem limite)
##   type  — "obra" (Construcao), "decor" (objeto de decoração) ou "bau"

const ALL := {
    &"caminho_terra": {"name": "Caminho de terra", "desc": "Anda mais rápido em cima. Mato não nasce.",
        "cost": {}, "money": 5, "type": "obra", "floor": true},
    &"caminho_pedra": {"name": "Caminho de pedra", "desc": "Anda mais rápido em cima. Mato não nasce.",
        "cost": {"pedra": 2}, "money": 0, "type": "obra", "floor": true, "req": {"skill": ["mineracao", 1]}},
    &"caminho_madeira": {"name": "Assoalho de madeira", "desc": "Anda mais rápido em cima. Mato não nasce.",
        "cost": {"madeira": 2}, "money": 0, "type": "obra", "floor": true, "req": {"skill": ["coleta", 1]}},
    &"cerca": {"name": "Cerca de madeira", "desc": "Bloqueia a passagem (de gente e de bicho).",
        "cost": {"madeira": 2}, "money": 0, "type": "obra", "solid": true},
    &"banco_madeira": {"name": "Banco de madeira", "desc": "Decoração.",
        "cost": {"madeira": 6}, "money": 0, "type": "decor", "req": {"skill": ["artesanato", 1]}},
    &"vaso_flores": {"name": "Vaso de flores", "desc": "Decoração.",
        "cost": {"pedra": 3}, "money": 20, "type": "decor"},
    &"lampiao": {"name": "Lampião", "desc": "Acende de noite. Perto do cercado ajuda a defender a criação.",
        "cost": {"madeira": 2, "minerio_ferro": 1}, "money": 30, "type": "decor", "req": {"skill": ["artesanato", 2]}},
    &"espantalho": {"name": "Espantalho", "desc": "Guarda a roça (e dá personalidade).",
        "cost": {"madeira": 5, "couro": 1}, "money": 0, "type": "decor", "req": {"skill": ["agricultura", 2]}},
    &"bau": {"name": "Baú", "desc": "Guarda 18 itens.",
        "cost": {"madeira": 12, "minerio_ferro": 2}, "money": 0, "type": "bau", "req": {"skill": ["artesanato", 1]}},
    &"poco": {"name": "Poço", "desc": "Enche o regador perto da roça.",
        "cost": {"pedra": 25, "madeira": 10}, "money": 300, "type": "obra", "solid": true, "max": 3,
        "req": {"skill": ["mineracao", 3]}},
    &"cerca_espinhos": {"name": "Cerca de espinhos", "desc": "Bloqueia e machuca as criaturas do Silêncio que encostam.",
        "cost": {"madeira": 4, "fragmento_silencio": 2}, "money": 0, "type": "obra", "solid": true,
        "req": {"skill": ["combate", 2]}},
    &"totem_protecao": {"name": "Totem de proteção", "desc": "Cristal que espanta o Silêncio: +2 de defesa pros cercados perto dele.",
        "cost": {"cristal_vale": 1, "quartzo": 3, "pedra": 15}, "money": 500, "type": "obra", "solid": true, "max": 2,
        "req": {"skill": ["combate", 4], "flag": "ato1_completo", "flag_text": "terminar o Ato 1"}},
}
## Ordem no menu.
const ORDER := [&"caminho_terra", &"caminho_pedra", &"caminho_madeira", &"cerca", &"vaso_flores", &"banco_madeira",
    &"bau", &"lampiao", &"espantalho", &"poco", &"cerca_espinhos", &"totem_protecao"]


## Texto do que falta pra liberar ("" = liberado).
static func missing_req(id: StringName) -> String:
    var req: Dictionary = ALL[id].get("req", {})
    var parts := PackedStringArray()
    if req.has("skill"):
        var sk := StringName(req.skill[0])
        if GameState.skill_level(sk) < int(req.skill[1]):
            parts.append("%s nível %d" % [GameState.SKILL_NAMES.get(sk, String(sk)), int(req.skill[1])])
    if req.has("flag") and not GameState.has_flag(StringName(req.flag)):
        parts.append(String(req.get("flag_text", req.flag)))
    return ", ".join(parts)


## Texto do que falta de material/dinheiro ("" = dá pra pagar).
static func missing_cost(id: StringName) -> String:
    var info: Dictionary = ALL[id]
    var parts := PackedStringArray()
    for k in info.cost:
        var have := GameState.get_item_count(StringName(k))
        if have < int(info.cost[k]):
            parts.append("%s %d/%d" % [_item_name(k), have, int(info.cost[k])])
    if GameState.money < int(info.money):
        parts.append("R$ %d" % int(info.money))
    return ", ".join(parts)


static func cost_text(id: StringName) -> String:
    var info: Dictionary = ALL[id]
    var parts := PackedStringArray()
    for k in info.cost:
        parts.append("%d %s" % [int(info.cost[k]), _item_name(k)])
    if int(info.money) > 0:
        parts.append("R$ %d" % int(info.money))
    return ", ".join(parts) if not parts.is_empty() else "grátis"


static func _item_name(id: String) -> String:
    var it := ItemDB.get_item(StringName(id))
    return it.display_name.to_lower() if it else id


## Quantas já tem construídas.
static func count_built(tree: SceneTree, id: StringName) -> int:
    return tree.get_nodes_in_group("construcao_" + String(id)).size()


## Pode construir agora? "" = sim; senão o motivo.
static func can_build(tree: SceneTree, id: StringName) -> String:
    var r := missing_req(id)
    if r != "":
        return "Precisa: " + r
    var mx := int(ALL[id].get("max", 0))
    if mx > 0 and count_built(tree, id) >= mx:
        return "Máximo de %d" % mx
    var c := missing_cost(id)
    if c != "":
        return "Falta: " + c
    return ""


static func pay(id: StringName) -> void:
    var info: Dictionary = ALL[id]
    for k in info.cost:
        GameState.inventory.remove(StringName(k), int(info.cost[k]))
    if int(info.money) > 0:
        GameState.spend_money(int(info.money))
    GameState.add_xp(&"artesanato", 2 + int(info.cost.size()) * 2)


## Recolher devolve metade dos materiais (arredondando pra baixo).
static func refund(id: StringName) -> void:
    var info: Dictionary = ALL[id]
    for k in info.cost:
        var n := int(info.cost[k]) / 2
        if n > 0:
            GameState.add_item(StringName(k), n)
