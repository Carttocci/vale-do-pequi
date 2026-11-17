class_name Gifting
extends Node
## Presentes: com um item na mão (comida, colheita, peixe, minério...), de
## frente para um morador, o E vira "Presentear <nome>". Um presente por dia.
## Se o morador tem fala de missão esperando, a conversa ganha (entrega de missão).

const GIFTABLE := [ItemData.Category.CROP, ItemData.Category.FORAGE, ItemData.Category.FISH,
    ItemData.Category.ANIMAL_PRODUCT, ItemData.Category.FOOD, ItemData.Category.MINERAL]
const REACH := 16.0


func _ready() -> void:
    add_to_group("item_target")


func npc_at(pos: Vector2) -> Npc:
    for n in get_tree().get_nodes_in_group("npc"):
        var npc := n as Npc
        if npc.is_visible_in_tree() and npc.interactable.enabled \
                and (npc.global_position + Vector2(0, -8)).distance_to(pos) < REACH:
            return npc
    return null


func get_item_action(item: ItemData, target_pos: Vector2, _actor: Node) -> Dictionary:
    if item == null or not item.category in GIFTABLE:
        return {}
    var npc := npc_at(target_pos)
    if npc == null or not Quests.dialogue_for(String(npc.data.id)).is_empty():
        return {}
    return {"prompt": "Presentear " + npc.data.display_name, "priority": 11, "once": true}


func use_item(item: ItemData, target_pos: Vector2, _actor: Node) -> bool:
    if get_item_action(item, target_pos, null).is_empty():
        return false
    var npc := npc_at(target_pos)
    if not npc.can_receive_gift():
        EventBus.show_message("%s já ganhou presente hoje." % npc.data.display_name, 2.0)
        return false
    GameState.consume_selected(1)
    npc.receive_gift(item)
    return true
