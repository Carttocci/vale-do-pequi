class_name Mining
extends Node
## Picareta: com ela na mão, de frente para uma pedra, o E vira "Quebrar ...".

const REACH := 14.0
const ENERGY := 2


func _ready() -> void:
    add_to_group("item_target")


func rock_at(pos: Vector2) -> Rock:
    var best: Rock = null
    var best_d := REACH
    for r in get_tree().get_nodes_in_group("rock"):
        var rock := r as Rock
        if rock.is_broken() or not rock.is_visible_in_tree():
            continue
        var d := (rock.global_position + Vector2(0, -4)).distance_to(pos)
        if d < best_d:
            best_d = d
            best = rock
    return best


func get_item_action(item: ItemData, target_pos: Vector2, _actor: Node) -> Dictionary:
    if item == null or item.tool_type != ItemData.ToolType.PICKAXE:
        return {}
    var rock := rock_at(target_pos)
    return {"prompt": "Quebrar " + rock.display_name(), "priority": 20} if rock else {}


func use_item(item: ItemData, target_pos: Vector2, _actor: Node) -> bool:
    if get_item_action(item, target_pos, null).is_empty():
        return false
    if not GameState.use_energy(ENERGY):
        return false
    rock_at(target_pos).hit(ToolUpgrades.power(&"picareta") + GameState.skill_level(&"mineracao") / 4)
    return true
