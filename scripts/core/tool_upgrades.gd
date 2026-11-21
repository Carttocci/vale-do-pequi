class_name ToolUpgrades
extends RefCounted
## Melhorias de ferramenta na forja do Toninho: comum → de ferro → de ouro.
## O nível fica numa flag ("nivel_enxada" etc.), então vai junto no save.
##   enxada   — ferro: capina 3 em linha; ouro: 3×3
##   regador  — +5/+15 de água; ferro: rega 3 em linha; ouro: 3×3
##   picareta — +1 de força por nível (pedra grande e minério quebram mais rápido)
##   machado  — +1 de força em árvore/toco por nível e +5 de dano na briga

const TOOLS := [&"enxada", &"regador", &"picareta", &"machado"]
const NAMES := ["", "de ferro", "de ouro"]
const COSTS := [
    {},
    {"money": 500, "minerio_ferro": 5},
    {"money": 1500, "ouro": 3, "quartzo": 2},
]
const MAX_LEVEL := 2


static func level(tool: StringName) -> int:
    return int(GameState.get_flag(StringName("nivel_" + String(tool)), 0))


static func cost(tool: StringName) -> Dictionary:
    var lv := level(tool)
    return COSTS[lv + 1] if lv < MAX_LEVEL else {}


static func cost_text(c: Dictionary) -> String:
    var parts := PackedStringArray()
    for k in c:
        if k == "money":
            continue
        var item := ItemDB.get_item(StringName(k))
        parts.append("%d %s" % [c[k], item.display_name.to_lower() if item else k])
    return ", ".join(parts)


static func display_name(tool: StringName) -> String:
    var item := ItemDB.get_item(tool)
    var base := item.display_name if item else String(tool).capitalize()
    var lv := level(tool)
    return base if lv == 0 else "%s %s" % [base, NAMES[lv]]


## Paga e melhora. Retorna "" se deu certo, senão o motivo.
static func upgrade(tool: StringName) -> String:
    var c := cost(tool)
    if c.is_empty():
        return "Já está no máximo."
    if GameState.get_item_count(tool) <= 0 and not _owns(tool):
        return "Traga a ferramenta primeiro."
    if GameState.money < int(c.money):
        return "Dinheiro não dá."
    for k in c:
        if k != "money" and GameState.get_item_count(StringName(k)) < int(c[k]):
            return "Falta material: %s." % cost_text(c)
    GameState.spend_money(int(c.money))
    for k in c:
        if k != "money":
            GameState.inventory.remove(StringName(k), int(c[k]))
    GameState.set_flag(StringName("nivel_" + String(tool)), level(tool) + 1)
    if tool == &"regador":
        GameState.refill_water()
    return ""


static func _owns(tool: StringName) -> bool:
    return GameState.get_item_count(tool) > 0


## Força do golpe da picareta/machado (pedra grande, minério, árvore, toco).
static func power(tool: StringName) -> int:
    return 1 + level(tool)


static func weapon_bonus(item_id: StringName) -> int:
    return 5 * level(&"machado") if item_id == &"machado" else 0


static func water_bonus() -> int:
    return [0, 5, 15][level(&"regador")]


## Células atingidas pela enxada/regador a partir da célula mirada.
static func area(tool: StringName, cell: Vector2i, facing: Vector2) -> Array[Vector2i]:
    var out: Array[Vector2i] = [cell]
    var lv := level(tool)
    if lv == 0:
        return out
    var f := Vector2i(roundi(facing.x), roundi(facing.y))
    if f == Vector2i.ZERO:
        f = Vector2i(0, 1)
    if f.x != 0 and f.y != 0:
        f.y = 0  # diagonal: vale a horizontal
    var side := Vector2i(-f.y, f.x)
    if lv == 1:
        out.append(cell + f)
        out.append(cell + f * 2)
    else:
        for i in 3:
            for j in [-1, 0, 1]:
                var c: Vector2i = cell + f * i + side * int(j)
                if c != cell:
                    out.append(c)
    return out
