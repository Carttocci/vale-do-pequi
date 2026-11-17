class_name InventoryUI
extends CanvasLayer
## Telas de mochila e de baú. Pausam o mundo enquanto estão abertas.
##
## Mochila (I / botão da mochila): toque num item para selecionar, toque em
## outro slot para trocar de lugar. A primeira linha é a barra de atalhos.
## Baú: toque num item para mandá-lo para o outro lado.

enum Mode { CLOSED, INVENTORY, CHEST }

const COLUMNS := 9

var mode: Mode = Mode.CLOSED
var chest: Chest = null

var _picked: int = -1
var _panel: PanelContainer
var _title: Label
var _chest_label: Label
var _chest_grid: GridContainer
var _bag_label: Label
var _bag_grid: GridContainer
var _info: Label
var _chest_slots: Array[ItemSlot] = []
var _bag_slots: Array[ItemSlot] = []


func _ready() -> void:
    layer = 3
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    _panel.hide()
    EventBus.chest_open_requested.connect(func(c: Node) -> void: open_chest(c as Chest))
    GameState.inventory.changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
    if mode == Mode.CLOSED:
        if event.is_action_pressed("inventory") and not get_tree().paused:
            open_inventory()
            get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed("inventory") or event.is_action_pressed("menu"):
        close()
        get_viewport().set_input_as_handled()


func is_open() -> bool:
    return mode != Mode.CLOSED


func open_inventory() -> void:
    mode = Mode.INVENTORY
    chest = null
    _open()


func open_chest(c: Chest) -> void:
    if c == null or get_tree().paused:
        return
    mode = Mode.CHEST
    chest = c
    if not chest.inventory.changed.is_connected(_refresh):
        chest.inventory.changed.connect(_refresh)
    _open()


func close() -> void:
    if chest and chest.inventory.changed.is_connected(_refresh):
        chest.inventory.changed.disconnect(_refresh)
    mode = Mode.CLOSED
    chest = null
    _picked = -1
    _panel.hide()
    get_tree().paused = false
    EventBus.pause_changed.emit(false)


## Clique num slot da mochila.
func press_bag_slot(i: int) -> void:
    if mode == Mode.CHEST:
        GameState.inventory.transfer_slot_to(chest.inventory, i)
        return
    if _picked == -1:
        if GameState.inventory.get_slot(i) != null:
            _picked = i
    else:
        GameState.inventory.swap(_picked, i)
        _picked = -1
    _refresh()


## Clique num slot do baú.
func press_chest_slot(i: int) -> void:
    if chest:
        chest.inventory.transfer_slot_to(GameState.inventory, i)


func _open() -> void:
    _picked = -1
    get_tree().paused = true
    EventBus.pause_changed.emit(true)
    _panel.show()
    _refresh()


func _refresh() -> void:
    if _panel == null or not _panel.visible:
        return
    var in_chest := mode == Mode.CHEST
    _title.text = chest.title if in_chest else "Mochila"
    _chest_label.visible = in_chest
    _chest_grid.visible = in_chest
    _bag_label.visible = in_chest
    for i in _bag_slots.size():
        _bag_slots[i].show_slot(GameState.inventory.get_slot(i))
        _bag_slots[i].set_highlighted(i == _picked)
    if in_chest:
        for i in _chest_slots.size():
            _chest_slots[i].show_slot(chest.inventory.get_slot(i))
            _chest_slots[i].set_highlighted(false)
        _info.text = "Toque num item para passar para o outro lado."
    elif _picked >= 0:
        var item := ItemDB.get_item(GameState.inventory.get_item_id(_picked))
        _info.text = "%s — %s\nToque em outro espaço para mover." % [item.display_name, item.description]
    else:
        _info.text = "Toque num item para ver e mover. A primeira linha é a barra de atalhos."


func _build() -> void:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.15, 0.12, 0.11, 0.95)
    box.border_color = Color(0.72, 0.47, 0.22, 1)
    box.set_border_width_all(1)
    box.set_corner_radius_all(3)
    box.set_content_margin_all(6)

    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(center)
    _panel = PanelContainer.new()
    _panel.add_theme_stylebox_override("panel", box)
    center.add_child(_panel)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 3)
    _panel.add_child(col)

    var header := HBoxContainer.new()
    col.add_child(header)
    _title = _label("Mochila", 11)
    _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(_title)
    var close_btn := Button.new()
    close_btn.text = " X "
    close_btn.focus_mode = Control.FOCUS_NONE
    close_btn.add_theme_font_size_override("font_size", 10)
    close_btn.pressed.connect(close)
    header.add_child(close_btn)

    _chest_label = _label("Baú", 9)
    col.add_child(_chest_label)
    _chest_grid = _grid(Chest.SIZE, _chest_slots, press_chest_slot)
    col.add_child(_chest_grid)
    _bag_label = _label("Mochila", 9)
    col.add_child(_bag_label)
    _bag_grid = _grid(GameState.INVENTORY_SIZE, _bag_slots, press_bag_slot)
    col.add_child(_bag_grid)

    _info = _label("", 8)
    _info.custom_minimum_size = Vector2(COLUMNS * 30, 22)
    _info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    col.add_child(_info)


func _grid(count: int, store: Array[ItemSlot], on_press: Callable) -> GridContainer:
    var grid := GridContainer.new()
    grid.columns = COLUMNS
    grid.add_theme_constant_override("h_separation", 2)
    grid.add_theme_constant_override("v_separation", 2)
    for i in count:
        var slot := ItemSlot.new()
        slot.index = i
        slot.pressed.connect(on_press.bind(i))
        grid.add_child(slot)
        store.append(slot)
    return grid


func _label(text: String, size: int) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86))
    return l
