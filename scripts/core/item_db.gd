extends Node
## Catálogo de itens e culturas (autoload "ItemDB").
## Lê todos os .tres de data/items/ e data/crops/ na inicialização.

const ITEMS_DIR := "res://data/items"
const CROPS_DIR := "res://data/crops"
const FISH_DIR := "res://data/fish"

var _items: Dictionary = {}
var _crops: Dictionary = {}
var _fish: Array[FishData] = []


func _ready() -> void:
    for res in _load_dir(ITEMS_DIR):
        var item := res as ItemData
        if item:
            _items[item.id] = item
    for res in _load_dir(CROPS_DIR):
        var crop := res as CropData
        if crop:
            _crops[crop.id] = crop
    for res in _load_dir(FISH_DIR):
        if res is FishData:
            _fish.append(res)


func get_item(id: StringName) -> ItemData:
    return _items.get(id)


func get_crop(id: StringName) -> CropData:
    return _crops.get(id)


func all_fish() -> Array[FishData]:
    return _fish


func has_item(id: StringName) -> bool:
    return _items.has(id)


func item_ids() -> Array:
    return _items.keys()


func crop_ids() -> Array:
    return _crops.keys()


func max_stack(id: StringName) -> int:
    var item := get_item(id)
    return item.max_stack if item else 99


func _load_dir(path: String) -> Array:
    var out: Array = []
    var dir := DirAccess.open(path)
    if dir == null:
        push_error("ItemDB: pasta não encontrada: " + path)
        return out
    for file in dir.get_files():
        # No jogo exportado os .tres viram ".tres.remap" (apontam para o binário).
        file = file.trim_suffix(".remap")
        if file.ends_with(".tres"):
            var res := load(path + "/" + file)
            if res:
                out.append(res)
    return out
