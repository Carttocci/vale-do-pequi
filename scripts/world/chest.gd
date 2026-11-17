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
    return {"inventory": inventory.to_data()}


func load_save_data(data: Dictionary) -> void:
    inventory.from_data(data.get("inventory", []))
