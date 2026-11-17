class_name Eating
extends Node
## Comer: com comida pronta na mão, o E vira "Comer ..." (prioridade baixa:
## colher, conversar e presentear ganham).


func _ready() -> void:
    add_to_group("item_target")


func get_item_action(item: ItemData, _target_pos: Vector2, _actor: Node) -> Dictionary:
    if item == null or item.category != ItemData.Category.FOOD:
        return {}
    return {"prompt": "Comer " + item.display_name.to_lower(), "priority": 3, "once": true}


func use_item(item: ItemData, _target_pos: Vector2, _actor: Node) -> bool:
    if item == null or item.category != ItemData.Category.FOOD:
        return false
    if not GameState.consume_selected(1):
        return false
    return GameState.eat(item)
