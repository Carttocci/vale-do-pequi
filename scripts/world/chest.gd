class_name Chest
extends StaticBody2D
## Baú: guarda itens. Abre a tela de transferência pelo EventBus.

const SIZE := 18

## Conteúdo inicial num jogo novo, no formato "id:quantidade".
@export var starting_items: PackedStringArray = PackedStringArray()
@export var title: String = "Baú"

var inventory := Inventory.new(SIZE)

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
    add_to_group("persistent")
    interactable.prompt = "Abrir " + title.to_lower()
    interactable.interacted.connect(func(_a: Node) -> void: EventBus.chest_open_requested.emit(self))
    for entry in starting_items:
        var parts := entry.split(":")
        if parts.size() == 2:
            inventory.add(StringName(parts[0]), int(parts[1]))


func get_save_data() -> Dictionary:
    var d := {"inventory": inventory.to_data()}
    if has_meta("build_id"):
        d["build_id"] = String(get_meta("build_id"))  # baú feito no modo construção
    return d


func load_save_data(data: Dictionary) -> void:
    inventory.from_data(data.get("inventory", []))
    if data.has("build_id"):
        set_meta("build_id", data.build_id)
        add_to_group("construcao")
        add_to_group("construcao_" + String(data.build_id))
