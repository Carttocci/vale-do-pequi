class_name HeartEvents
extends RefCounted
## Conversas especiais por amizade (data/heart_events.json): aos 2 corações o
## morador ensina uma receita de família; aos 4 conta uma lembrança e dá um
## presente. Cada uma acontece uma vez (marco "coracao_<id>_<corações>").

const DATA_PATH := "res://data/heart_events.json"

static var _events: Array = []


static func all() -> Array:
    if _events.is_empty():
        _events = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)).events
    return _events


static func flag_for(e: Dictionary) -> StringName:
    return StringName("coracao_%s_%d" % [e.npc, int(e.hearts)])


## Próxima conversa especial liberada para este morador (ou {}).
static func pending(npc_id: String, hearts: int) -> Dictionary:
    for e in all():
        if e.npc == npc_id and hearts >= int(e.hearts) and not GameState.has_flag(flag_for(e)):
            return e
    return {}


## Conclui a conversa: marco, presentes, receita (aos 2 corações) e lembrança.
static func complete(e: Dictionary, display_name: String) -> void:
    GameState.set_flag(flag_for(e))
    for item in e.get("items", {}):
        GameState.add_item(StringName(item), int(e.items[item]))
    var recipe := Recipes.taught_by(e.npc) if int(e.hearts) == 2 else &""
    if recipe != &"" and GameState.learn_recipe(recipe):
        var it := ItemDB.get_item(StringName(Recipes.find(recipe).out))
        EventBus.show_message("Receita aprendida: %s!" % (it.display_name if it else String(recipe)), 3.0)
    GameState.add_memory("historia_%s_%d" % [e.npc, int(e.hearts)], "uma história de %s" % display_name)
