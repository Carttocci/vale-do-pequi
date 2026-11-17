class_name ItemData
extends Resource
## Definição de um tipo de item (não é uma instância no inventário).
## Cada item é um arquivo .tres em data/items/, carregado pelo autoload ItemDB.

enum Category { TOOL, SEED, CROP, FORAGE, MATERIAL }
enum ToolType { NONE, HOE, WATERING_CAN }

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var category: Category = Category.MATERIAL
@export var max_stack: int = 99
## Quanto a loja paga por 1 unidade.
@export var sell_price: int = 0
## Quanto custa comprar 1 unidade (0 = não se compra em loja).
@export var buy_price: int = 0
@export var tool_type: ToolType = ToolType.NONE
## Para sementes: id da cultura (CropData) que ela planta.
@export var crop_id: StringName


func is_tool() -> bool:
    return category == Category.TOOL


func is_usable_on_ground() -> bool:
    return category == Category.TOOL or category == Category.SEED
