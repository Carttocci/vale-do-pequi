class_name Fishing
extends Node
## Pesca: com a vara na mão, de frente para a água, o E vira "Pescar".
## Sorteia o peixe pelo lugar (lagoa/rio), hora, período e clima, gasta 1 isca
## e abre o minijogo (FishingUI). Fica na cena principal (vale para todas as regiões).

const ISCA := &"isca"

var busy: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    add_to_group("item_target")
    EventBus.fishing_finished.connect(_on_finished)


func get_item_action(item: ItemData, target_pos: Vector2, _actor: Node) -> Dictionary:
    if item and item.tool_type == ItemData.ToolType.ROD and not busy and is_water(target_pos):
        return {"prompt": "Pescar", "priority": 25}
    return {}


func use_item(item: ItemData, target_pos: Vector2, actor: Node) -> bool:
    if item == null or item.tool_type != ItemData.ToolType.ROD or busy or not is_water(target_pos):
        return false
    if GameState.get_item_count(ISCA) <= 0:
        EventBus.show_message("Sem isca! O João Pedro vende minhoca na lagoa da vila.", 2.5)
        return false
    if not GameState.use_energy(2):
        return false
    GameState.inventory.remove(ISCA, 1)
    var fish := roll_fish(current_habitat(), Clock.minutes, Calendar.period(GameState.day), Clock.WEATHER_KEYS[Clock.weather])
    if fish == null:
        EventBus.show_message("Nada belisca aqui agora.", 2.0)
        return false
    busy = true
    if actor is Player:
        (actor as Player).input_enabled = false
    EventBus.fishing_started.emit(fish)
    return true


func is_water(pos: Vector2) -> bool:
    var level := _level()
    if level == null:
        return false
    var cell := level.ground.local_to_map(level.ground.to_local(pos))
    return level.ground.get_cell_atlas_coords(cell).x in [5, 7]


func current_habitat() -> String:
    var level := _level()
    return level.water_habitat if level else "lagoa"


## Sorteio ponderado entre os peixes possíveis agora. A habilidade de pesca
## aumenta um pouco a chance dos difíceis.
func roll_fish(habitat: String, minutes: int, period: StringName, weather_key: String) -> FishData:
    var options: Array[FishData] = []
    var total := 0.0
    var bonus := GameState.skill_level(&"pesca") * 0.08
    for f in ItemDB.all_fish():
        if f.available(habitat, minutes, period, weather_key):
            options.append(f)
            total += f.weight * (1.0 + bonus * (f.difficulty - 1))
    if options.is_empty():
        return null
    var r := _rng.randf() * total
    for f in options:
        r -= f.weight * (1.0 + bonus * (f.difficulty - 1))
        if r <= 0.0:
            return f
    return options[-1]


func _on_finished(success: bool, fish: FishData) -> void:
    busy = false
    var player := get_tree().get_first_node_in_group("player") as Player
    if player:
        player.input_enabled = true
    if not success or fish == null:
        return
    var item := ItemDB.get_item(fish.item)
    if GameState.space_for(fish.item) <= 0:
        EventBus.show_message("Mochila cheia! O peixe voltou pra água.", 2.5)
        return
    GameState.add_item(fish.item, 1)
    var first := GameState.log_fish(fish.item)
    GameState.add_xp(&"pesca", 6 * fish.difficulty)
    EventBus.show_message("Pegou um%s %s!%s" % ["a" if item.display_name.ends_with("a") else "", item.display_name,
        "  Novo no caderno!" if first else ""], 3.0)


func _level() -> Level:
    var main := get_tree().get_first_node_in_group("save_root")
    return main.level if main and "level" in main else null
