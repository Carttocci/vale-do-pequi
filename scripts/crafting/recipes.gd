class_name Recipes
extends RefCounted
## Receitas do fogão a lenha (cozinha), da bancada e obras da fazenda.
## Dados em data/recipes.json. Só funções estáticas; o que o jogador sabe
## fica em GameState.known_recipes e as obras feitas em flags "obra_<id>".

const DATA_PATH := "res://data/recipes.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
    if _data.is_empty():
        _data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
    return _data


static func station(name: String) -> Array:
    return data().get(name, [])


static func find(id: StringName) -> Dictionary:
    for st in ["cozinha", "bancada", "obras"]:
        for r in station(st):
            if r.id == String(id):
                return r
    return {}


static func starting_known() -> Array[StringName]:
    var out: Array[StringName] = []
    for st in ["cozinha", "bancada"]:
        for r in station(st):
            if r.get("known", false):
                out.append(StringName(r.id))
    return out


## Receita da cozinha que este morador ensina (ou "").
static func taught_by(npc_id: String) -> StringName:
    for r in station("cozinha"):
        if r.get("teacher", "") == npc_id:
            return StringName(r.id)
    return &""


static func is_obra(r: Dictionary) -> bool:
    return r.has("money") or r.has("name")


static func obra_done(r: Dictionary) -> bool:
    return GameState.has_flag(StringName("obra_" + r.id))


static func can_make(r: Dictionary) -> bool:
    if is_obra(r):
        if obra_done(r) or GameState.money < int(r.get("money", 0)):
            return false
    elif not GameState.knows_recipe(StringName(r.id)):
        return false
    for item in r.ing:
        if GameState.get_item_count(StringName(item)) < int(r.ing[item]):
            return false
    if not is_obra(r) and GameState.space_for(StringName(r.out)) < int(r.get("count", 1)):
        return false
    return true


## Faz a receita (gasta ingredientes). Retorna true se fez.
static func make(r: Dictionary) -> bool:
    if not can_make(r):
        return false
    for item in r.ing:
        GameState.inventory.remove(StringName(item), int(r.ing[item]))
    if is_obra(r):
        GameState.spend_money(int(r.money))
        GameState.set_flag(StringName("obra_" + r.id))
        GameState.add_xp(&"artesanato", 40)
        EventBus.show_message("Obra pronta: %s! %s" % [r.name, r.desc], 3.5)
        return true
    var out := StringName(r.out)
    GameState.add_item(out, int(r.get("count", 1)))
    var item := ItemDB.get_item(out)
    if item and item.category == ItemData.Category.FOOD:
        GameState.add_xp(&"artesanato", 8)
        GameState.add_memory("receita_" + r.id, "%s feito no fogão a lenha" % item.display_name)
    else:
        GameState.add_xp(&"artesanato", 5)
    return true


## "Milho 2/3 · Leite 0/1"
static func ingredients_text(r: Dictionary) -> String:
    var parts := PackedStringArray()
    for item in r.ing:
        var it := ItemDB.get_item(StringName(item))
        parts.append("%s %d/%d" % [it.display_name if it else item, mini(GameState.get_item_count(StringName(item)), int(r.ing[item])), int(r.ing[item])])
    if r.has("money"):
        parts.append("R$ %d" % int(r.money))
    return " · ".join(parts)
