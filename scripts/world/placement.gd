class_name Placement
extends Node
## Colocar itens no chão (categoria PLACEABLE): com o item na mão, o E vira
## "Colocar ..." na célula à frente, se estiver livre e a região permitir.
## Objetos colocados ficam em <Região>/Entities/Placed e são salvos aqui
## (cena + posição + dados de cada objeto).

const PLACED := "Entities/Placed"


func _ready() -> void:
    add_to_group("item_target")
    add_to_group("persistent")


func get_item_action(item: ItemData, target_pos: Vector2, _actor: Node) -> Dictionary:
    if item == null or item.category != ItemData.Category.PLACEABLE or item.place_scene == "":
        return {}
    var level := _level()
    if level == null:
        return {}
    if not item.place_regions.is_empty() and not String(level.region_id) in item.place_regions:
        return {}
    var cell_pos := _snap(level, target_pos)
    if not level.is_walkable(cell_pos) or _occupied(level, cell_pos):
        return {}
    return {"prompt": "Colocar " + item.display_name.to_lower(), "priority": 12}


func use_item(item: ItemData, target_pos: Vector2, actor: Node) -> bool:
    if get_item_action(item, target_pos, actor).is_empty():
        if item and item.category == ItemData.Category.PLACEABLE and not item.place_regions.is_empty():
            var level := _level()
            if level and not String(level.region_id) in item.place_regions:
                EventBus.show_message("Isso só pode ser colocado %s." % ("na fazenda" if "farm" in item.place_regions else "na Mata dos Ipês"), 2.0)
        return false
    var level := _level()
    var obj := (load(item.place_scene) as PackedScene).instantiate() as Node2D
    obj.position = _snap(level, target_pos)
    if obj.has_method("setup_from_item"):
        obj.setup_from_item(item)
    _container(level).add_child(obj)
    GameState.consume_selected(1)
    return true


func _snap(level: Level, pos: Vector2) -> Vector2:
    var cell := level.ground.local_to_map(level.ground.to_local(pos))
    return level.ground.to_global(level.ground.map_to_local(cell)) + Vector2(0, 7)


func _occupied(level: Level, pos: Vector2) -> bool:
    for c in _container(level).get_children():
        if (c as Node2D).position.distance_to(pos) < 8.0 and not c.is_queued_for_deletion():
            return true
    return false


func _container(level: Level) -> Node2D:
    var c := level.get_node_or_null(PLACED) as Node2D
    if c == null:
        c = Node2D.new()
        c.name = "Placed"
        c.y_sort_enabled = true
        level.get_entities_root().add_child(c)
    return c


func _level() -> Level:
    var main := get_tree().get_first_node_in_group("save_root")
    return main.level if main and "level" in main else null


func get_save_data() -> Dictionary:
    var out := {}
    var main := get_tree().get_first_node_in_group("save_root")
    for level: Level in main.regions.values():
        var list := []
        for c in _container(level).get_children():
            if c.is_queued_for_deletion():
                continue
            list.append({"scene": c.scene_file_path, "x": c.position.x, "y": c.position.y,
                "data": c.get_save_data() if c.has_method("get_save_data") else {}})
        out[String(level.region_id)] = list
    return out


func load_save_data(d: Dictionary) -> void:
    var main := get_tree().get_first_node_in_group("save_root")
    for level: Level in main.regions.values():
        var cont := _container(level)
        for c in cont.get_children():
            cont.remove_child(c)
            c.queue_free()
        for e in d.get(String(level.region_id), []):
            if not ResourceLoader.exists(String(e.get("scene", ""))):
                continue
            var obj := (load(e.scene) as PackedScene).instantiate() as Node2D
            obj.position = Vector2(float(e.x), float(e.y))
            cont.add_child(obj)
            if obj.has_method("load_save_data"):
                obj.load_save_data(e.get("data", {}))
