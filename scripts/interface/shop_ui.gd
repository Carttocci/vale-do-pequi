class_name ShopUI
extends CanvasLayer
## Loja: abas Comprar e Vender. Pausa o mundo.
##
## `shop` (EventBus.shop_requested):
##   {"title": String, "sells": PackedStringArray (ids), "buys": PackedInt32Array
##    (categorias de ItemData), "tab": 0 comprar / 1 vender}
## Toque/clique numa linha compra ou vende 1; o botão "x5"/"Tudo" faz em lote.

enum Tab { BUY, SELL }

var shop: Dictionary = {}
var tab: Tab = Tab.BUY

var _panel: PanelContainer
var _title: Label
var _money: Label
var _buy_tab: Button
var _sell_tab: Button
var _list: VBoxContainer
var _info: Label


func _ready() -> void:
    layer = 4
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build()
    _panel.hide()
    EventBus.shop_requested.connect(open_shop)
    GameState.money_changed.connect(func(_m: int) -> void: _refresh())
    GameState.inventory.changed.connect(_refresh)


func is_open() -> bool:
    return _panel.visible


func open_shop(data: Dictionary) -> void:
    shop = data
    tab = Tab.SELL if int(data.get("tab", 0)) == 1 else Tab.BUY
    get_tree().paused = true
    _panel.show()
    _info.text = ""
    _refresh()


func close() -> void:
    _panel.hide()
    get_tree().paused = false


func set_tab(t: Tab) -> void:
    tab = t
    _info.text = ""
    _refresh()


## Compra `amount` unidades. Retorna quantas comprou.
func buy(item_id: StringName, amount: int = 1) -> int:
    var item := ItemDB.get_item(item_id)
    if item == null or item.buy_price <= 0:
        return 0
    var can_pay := GameState.money / item.buy_price
    var fits := GameState.space_for(item_id)
    var n := mini(amount, mini(can_pay, fits))
    if n <= 0:
        _info.text = "Dinheiro não dá." if can_pay <= 0 else "Mochila cheia."
        return 0
    GameState.spend_money(n * item.buy_price)
    GameState.inventory.add(item_id, n)
    _info.text = "Comprou %d × %s por R$ %d." % [n, item.display_name, n * item.buy_price]
    return n


## Vende `amount` unidades (ou menos, se não tiver). Retorna quantas vendeu.
func sell(item_id: StringName, amount: int = 1) -> int:
    var item := ItemDB.get_item(item_id)
    if item == null or not buys(item):
        return 0
    var n := mini(amount, GameState.get_item_count(item_id))
    if n <= 0:
        return 0
    GameState.inventory.remove(item_id, n)
    GameState.add_money(n * item.sell_price)
    _info.text = "Vendeu %d × %s por R$ %d." % [n, item.display_name, n * item.sell_price]
    return n


## Compra de animal: vai direto para o cercado da fazenda.
func buy_animal(kind: StringName) -> bool:
    var ranch := get_tree().get_first_node_in_group("ranch") as Ranch
    if ranch == null or not Ranch.ANIMALS.has(kind):
        return false
    var info: Dictionary = Ranch.ANIMALS[kind]
    if not ranch.can_buy(kind):
        _info.text = "Não cabe mais nenhum(a) %s no cercado." % info.name.to_lower()
        return false
    if not GameState.spend_money(int(info.price)):
        _info.text = "Dinheiro não dá."
        return false
    ranch.add_animal(kind)
    _info.text = "Comprou: %s! Já está te esperando na fazenda." % info.name.to_lower()
    _refresh()
    return true


func _add_animal_row(kind: StringName) -> void:
    if not Ranch.ANIMALS.has(kind):
        return
    var info: Dictionary = Ranch.ANIMALS[kind]
    var ranch := get_tree().get_first_node_in_group("ranch") as Ranch
    var tex := AtlasTexture.new()
    tex.atlas = load(info.sprite)
    tex.region = Rect2(0, 0, tex.atlas.get_width() / 4.0, tex.atlas.get_height())
    var proxy := ItemData.new()
    proxy.display_name = "%s (%d/%d)" % [info.name, ranch.count(kind) if ranch else 0, ranch.capacity(kind) if ranch else int(info.capacity)]
    proxy.icon = tex
    _add_row(proxy, "R$ %d" % info.price, "", buy_animal.bind(kind), "", Callable())


func buys(item: ItemData) -> bool:
    return item.sell_price > 0 and int(item.category) in Array(shop.get("buys", PackedInt32Array()))


func _unhandled_input(event: InputEvent) -> void:
    if is_open() and (event.is_action_pressed("menu") or event.is_action_pressed("inventory")):
        close()
        get_viewport().set_input_as_handled()


func _refresh() -> void:
    if _panel == null or not _panel.visible:
        return
    _title.text = String(shop.get("title", "Loja"))
    _money.text = "R$ %d" % GameState.money
    _buy_tab.button_pressed = tab == Tab.BUY
    _sell_tab.button_pressed = tab == Tab.SELL
    for c in _list.get_children():
        c.queue_free()
    if tab == Tab.BUY:
        var period := Calendar.period(GameState.day)
        for id in shop.get("sells", PackedStringArray()):
            if String(id).begins_with("animal:"):
                _add_animal_row(StringName(String(id).trim_prefix("animal:")))
                continue
            var item := ItemDB.get_item(StringName(id))
            if item == null:
                continue
            var note := ""
            var crop := ItemDB.get_crop(item.crop_id)
            if crop and not crop.can_grow_in(period):
                note = "  (fora de época)"
            _add_row(item, "R$ %d" % item.buy_price, note, buy.bind(item.id, 1), "x5", buy.bind(item.id, 5))
    else:
        var seen := {}
        for i in GameState.inventory.size():
            var id := GameState.inventory.get_item_id(i)
            if id == &"" or seen.has(id):
                continue
            seen[id] = true
            var item := ItemDB.get_item(id)
            if item and buys(item):
                var count := GameState.get_item_count(id)
                _add_row(item, "R$ %d" % item.sell_price, "  × %d" % count, sell.bind(id, 1), "Tudo", sell.bind(id, 999))
        if seen.is_empty() or _list.get_child_count() == 0:
            var l := _label("Nada que eu compre na sua mochila. Traga colheitas e pequi!", 9)
            _list.add_child(l)


func _add_row(item: ItemData, price: String, note: String, action: Callable, bulk_text: String, bulk: Callable) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    var icon := TextureRect.new()
    icon.texture = item.icon
    icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
    icon.custom_minimum_size = Vector2(18, 18)
    row.add_child(icon)
    var main_btn := Button.new()
    main_btn.text = "%s%s" % [item.display_name, note]
    main_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
    main_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_btn.focus_mode = Control.FOCUS_NONE
    main_btn.add_theme_font_size_override("font_size", 9)
    main_btn.pressed.connect(func() -> void: action.call())
    row.add_child(main_btn)
    row.add_child(_label(price, 9))
    if bulk_text == "":
        _list.add_child(row)
        return
    var bulk_btn := Button.new()
    bulk_btn.text = bulk_text
    bulk_btn.focus_mode = Control.FOCUS_NONE
    bulk_btn.add_theme_font_size_override("font_size", 9)
    bulk_btn.pressed.connect(func() -> void: bulk.call())
    row.add_child(bulk_btn)
    _list.add_child(row)


func _build() -> void:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.15, 0.12, 0.11, 0.96)
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
    _panel.custom_minimum_size = Vector2(300, 0)
    center.add_child(_panel)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 4)
    _panel.add_child(col)
    var header := HBoxContainer.new()
    col.add_child(header)
    _title = _label("Loja", 11)
    _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(_title)
    _money = _label("R$ 0", 10)
    _money.add_theme_color_override("font_color", Color(0.96, 0.77, 0.11))
    header.add_child(_money)
    var close_btn := Button.new()
    close_btn.text = " X "
    close_btn.focus_mode = Control.FOCUS_NONE
    close_btn.add_theme_font_size_override("font_size", 10)
    close_btn.pressed.connect(close)
    header.add_child(close_btn)
    var tabs := HBoxContainer.new()
    col.add_child(tabs)
    _buy_tab = Button.new()
    _buy_tab.text = "Comprar"
    _buy_tab.toggle_mode = true
    _buy_tab.focus_mode = Control.FOCUS_NONE
    _buy_tab.add_theme_font_size_override("font_size", 10)
    _buy_tab.pressed.connect(set_tab.bind(Tab.BUY))
    tabs.add_child(_buy_tab)
    _sell_tab = Button.new()
    _sell_tab.text = "Vender"
    _sell_tab.toggle_mode = true
    _sell_tab.focus_mode = Control.FOCUS_NONE
    _sell_tab.add_theme_font_size_override("font_size", 10)
    _sell_tab.pressed.connect(set_tab.bind(Tab.SELL))
    tabs.add_child(_sell_tab)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(290, 150)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    col.add_child(scroll)
    _list = VBoxContainer.new()
    _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _list.add_theme_constant_override("separation", 3)
    scroll.add_child(_list)
    _info = _label("", 9)
    _info.custom_minimum_size = Vector2(290, 12)
    col.add_child(_info)


func _label(text: String, size: int) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86))
    return l
