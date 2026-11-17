extends Node
## Estado da sessão (autoload "GameState").
##
## PROVISÓRIO (Fase 1): guarda só contagens simples de itens para validar o
## sistema de interação. Na Fase 2 o inventário real (slots, pilhas, categorias)
## entra em scripts/inventory/ e este dicionário vira um adaptador.

## Versão do formato de dados. Será gravada nos saves a partir da Fase 2
## para permitir migração de saves antigos (GDD §14.4).
const DATA_VERSION := 1

var _items: Dictionary = {}


func add_item(item_id: StringName, amount: int = 1) -> int:
    assert(amount > 0, "add_item: quantidade precisa ser positiva")
    var total: int = int(_items.get(item_id, 0)) + amount
    _items[item_id] = total
    EventBus.item_collected.emit(item_id, amount, total)
    return total


func get_item_count(item_id: StringName) -> int:
    return int(_items.get(item_id, 0))


func reset() -> void:
    _items.clear()
