class_name ItemData
extends Resource
## Definição de um tipo de item (não é uma instância no inventário).
## Cada item é um arquivo .tres em data/items/, carregado pelo autoload ItemDB.

## Novas categorias sempre no FIM (os números ficam salvos nos dados das lojas).
enum Category { TOOL, SEED, CROP, FORAGE, MATERIAL, FISH, ANIMAL_PRODUCT, WEAPON, FOOD, PLACEABLE, MINERAL, QUEST }
enum ToolType { NONE, HOE, WATERING_CAN, ROD, PICKAXE }

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
## Para itens colocáveis no chão (armadilha, baú...): cena instanciada.
@export_file("*.tscn") var place_scene: String = ""
## Regiões onde pode ser colocado (vazio = qualquer uma).
@export var place_regions: PackedStringArray = PackedStringArray()

@export_group("Arma")
## Dano por golpe (0 = não é arma).
@export var damage: int = 0
## Segundos entre golpes.
@export var attack_cooldown: float = 0.4
## Alcance do golpe (px) a partir do jogador.
@export var reach: float = 18.0
## Largura do golpe (px).
@export var arc_width: float = 20.0
@export var knockback: float = 120.0
## Segundos de atordoamento causado (martelo).
@export var stun: float = 0.0
## Arma de longe: dispara projétil e gasta `ammo_item`.
@export var ranged: bool = false
@export var ammo_item: StringName = &""

@export_group("Comida")
## Energia recuperada ao comer (0 = não se come).
@export var energy: int = 0
@export var health: int = 0
## Efeito: "pesca", "combate", "coleta", "clima" (bônus até o fim do dia).
@export var buff: StringName = &""


func is_tool() -> bool:
    return category == Category.TOOL


func is_usable_on_ground() -> bool:
    return category == Category.TOOL or category == Category.SEED or category == Category.PLACEABLE


func is_weapon() -> bool:
    return category == Category.WEAPON


func is_edible() -> bool:
    return energy > 0 or health > 0
