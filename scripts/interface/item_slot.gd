class_name ItemSlot
extends Button
## Um quadradinho de item (hotbar, mochila, baú). Mostra ícone e quantidade.
## Só apresentação: quem decide o que acontece no clique é a tela dona dele.

const SIZE := 28

var index: int = -1

var _icon: TextureRect
var _count: Label
var _normal := StyleBoxFlat.new()
var _highlight := StyleBoxFlat.new()


func _init() -> void:
    custom_minimum_size = Vector2(SIZE, SIZE)
    focus_mode = Control.FOCUS_NONE
    _normal.bg_color = Color(0.15, 0.12, 0.11, 0.85)
    _normal.border_color = Color(0.45, 0.36, 0.28, 1)
    _normal.set_border_width_all(1)
    _normal.set_corner_radius_all(2)
    _highlight = _normal.duplicate()
    _highlight.border_color = Color(0.96, 0.77, 0.11, 1)
    _highlight.set_border_width_all(2)
    _icon = TextureRect.new()
    _icon.set_anchors_preset(Control.PRESET_FULL_RECT)
    _icon.offset_left = 6
    _icon.offset_top = 6
    _icon.offset_right = -6
    _icon.offset_bottom = -6
    _icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
    _icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_icon)
    _count = Label.new()
    _count.set_anchors_preset(Control.PRESET_FULL_RECT)
    _count.offset_right = -2
    _count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    _count.add_theme_font_size_override("font_size", 8)
    _count.add_theme_color_override("font_outline_color", Color.BLACK)
    _count.add_theme_constant_override("outline_size", 2)
    _count.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_count)
    set_highlighted(false)


## `slot` = null ou {"id", "count"}. `extra` = texto opcional (ex.: água do regador).
func show_slot(slot: Variant, extra: String = "") -> void:
    var item: ItemData = ItemDB.get_item(slot.id) if slot != null else null
    _icon.texture = item.icon if item else null
    if extra != "":
        _count.text = extra
    elif slot != null and int(slot.count) > 1:
        _count.text = str(slot.count)
    else:
        _count.text = ""
    tooltip_text = item.display_name if item else ""


func set_highlighted(on: bool) -> void:
    var box := _highlight if on else _normal
    for state in ["normal", "hover", "pressed", "focus", "disabled"]:
        add_theme_stylebox_override(state, box)
