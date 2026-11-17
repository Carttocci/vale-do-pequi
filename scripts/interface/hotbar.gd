class_name Hotbar
extends HBoxContainer
## Barra de atalhos: os 9 primeiros slots da mochila.
## Clique/toque seleciona o slot (no celular é o jeito de trocar de ferramenta).

var _slots: Array[ItemSlot] = []


func _ready() -> void:
    add_theme_constant_override("separation", 2)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    for i in GameState.HOTBAR_SIZE:
        var slot := ItemSlot.new()
        slot.index = i
        slot.pressed.connect(GameState.select_slot.bind(i))
        add_child(slot)
        _slots.append(slot)
    GameState.inventory.changed.connect(refresh)
    GameState.selected_slot_changed.connect(func(_i: int) -> void: refresh())
    GameState.water_changed.connect(func(_w: int) -> void: refresh())
    refresh()


func get_slot_button(i: int) -> ItemSlot:
    return _slots[i]


func refresh() -> void:
    for i in _slots.size():
        var data: Variant = GameState.inventory.get_slot(i)
        var extra := ""
        if data != null and data.id == &"regador":
            extra = str(GameState.water)
        _slots[i].show_slot(data, extra)
        _slots[i].set_highlighted(i == GameState.selected_slot)
