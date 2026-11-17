class_name QuestBoard
extends Node2D
## Mural da praça: mostra os pedidos do povo (missões secundárias) para aceitar.

var prop: Prop


func _ready() -> void:
    prop = Prop.new().setup("mural", Vector2(28, 8), "Ver mural de pedidos", 16.0)
    prop.used.connect(func(_a: Node) -> void: open())
    add_child(prop)


func open() -> void:
    var ids := Quests.board_available()
    if ids.is_empty():
        EventBus.dialogue_requested.emit("Mural da praça",
            PackedStringArray(["Nenhum pedido novo por enquanto. Volte outro dia!"]), PackedStringArray(), Callable())
        return
    ids = ids.slice(0, 3)
    var opts := PackedStringArray()
    var lines := PackedStringArray()
    for id in ids:
        opts.append(Quests.defs[id].title)
        lines.append("%s — %s" % [Quests.defs[id].title, Quests.defs[id].desc])
    opts.append("Fechar")
    lines.append("Qual pedido você aceita?")
    EventBus.dialogue_requested.emit("Mural da praça", lines, opts, func(i: int) -> void:
        if i >= 0 and i < ids.size():
            Quests.start(ids[i]))
