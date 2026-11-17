class_name Inventory
extends RefCounted
## Inventário em slots (mochila do jogador, baús...).
##
## Cada slot é `null` (vazio) ou um Dictionary {"id": StringName, "count": int}.
## O tamanho máximo de cada pilha vem do ItemDB (ferramentas = 1).

signal changed

var slots: Array = []


func _init(size: int = 27) -> void:
    slots.resize(size)


func size() -> int:
    return slots.size()


func get_slot(index: int) -> Variant:
    return slots[index]


func get_item_id(index: int) -> StringName:
    var s: Variant = slots[index]
    return s.id if s != null else &""


func count_of(id: StringName) -> int:
    var total := 0
    for s: Variant in slots:
        if s != null and s.id == id:
            total += int(s.count)
    return total


## Adiciona itens. Completa pilhas existentes, depois usa slots vazios.
## Retorna o que sobrou (0 = coube tudo).
func add(id: StringName, count: int = 1) -> int:
    assert(count >= 0)
    var stack_max := ItemDB.max_stack(id)
    var left := count
    for i in slots.size():
        if left <= 0:
            break
        var s: Variant = slots[i]
        if s != null and s.id == id and s.count < stack_max:
            var put := mini(left, stack_max - int(s.count))
            s.count += put
            left -= put
    for i in slots.size():
        if left <= 0:
            break
        if slots[i] == null:
            var put := mini(left, stack_max)
            slots[i] = {"id": id, "count": put}
            left -= put
    if left != count:
        changed.emit()
    return left


## Quanto caberia deste item (sem adicionar).
func space_for(id: StringName) -> int:
    var stack_max := ItemDB.max_stack(id)
    var space := 0
    for s: Variant in slots:
        if s == null:
            space += stack_max
        elif s.id == id:
            space += stack_max - int(s.count)
    return space


## Remove `count` unidades no total. Só remove se houver o suficiente.
func remove(id: StringName, count: int = 1) -> bool:
    if count_of(id) < count:
        return false
    var left := count
    for i in range(slots.size() - 1, -1, -1):
        var s: Variant = slots[i]
        if left > 0 and s != null and s.id == id:
            var take := mini(left, int(s.count))
            s.count -= take
            left -= take
            if s.count <= 0:
                slots[i] = null
    changed.emit()
    return true


## Remove até `count` unidades de um slot específico. Retorna quantas saíram.
func remove_from_slot(index: int, count: int = 1) -> int:
    var s: Variant = slots[index]
    if s == null:
        return 0
    var take := mini(count, int(s.count))
    s.count -= take
    if s.count <= 0:
        slots[index] = null
    changed.emit()
    return take


func swap(a: int, b: int) -> void:
    if a == b:
        return
    var tmp: Variant = slots[a]
    slots[a] = slots[b]
    slots[b] = tmp
    changed.emit()


## Move a pilha do slot `index` para outro inventário. O que não couber fica.
func transfer_slot_to(other: Inventory, index: int) -> int:
    var s: Variant = slots[index]
    if s == null:
        return 0
    var left := other.add(s.id, int(s.count))
    var moved := int(s.count) - left
    if moved > 0:
        remove_from_slot(index, moved)
    return moved


func clear() -> void:
    for i in slots.size():
        slots[i] = null
    changed.emit()


## Formato salvo: lista com {"id": String, "count": int} ou null.
func to_data() -> Array:
    var out: Array = []
    for s: Variant in slots:
        out.append(null if s == null else {"id": String(s.id), "count": int(s.count)})
    return out


## Carrega dados salvos. Itens que não existem mais no jogo são descartados
## (com aviso) em vez de quebrar o save.
func from_data(data: Array) -> void:
    for i in slots.size():
        slots[i] = null
    for i in mini(data.size(), slots.size()):
        var s: Variant = data[i]
        if s is Dictionary and s.has("id") and int(s.get("count", 0)) > 0:
            var id := StringName(s.id)
            if ItemDB.has_item(id):
                slots[i] = {"id": id, "count": mini(int(s.count), ItemDB.max_stack(id))}
            else:
                push_warning("Inventory: item desconhecido no save ignorado: %s" % s.id)
    changed.emit()
