class_name InteriorLevel
extends Level
## Dentro de uma casa: quarto, cozinha, cama... Cada casa tem o seu jeito.
##
## A planta (paredes e pisos) fica em data/maps/interior_<layout>.txt e os
## móveis em LAYOUTS, logo abaixo. Uma cena só (scenes/interior/interior.tscn)
## serve para todas: a cena principal instancia uma vez por casa, mudando
## `layout`. A porta (embaixo) leva de volta para fora, no marcador `porta`.
##
## Móvel: [textura, posição da base (px), tamanho do corpo sólido, dica do E, ação]
##   ação "dormir"  -> cama do jogador (passa o dia e salva)
##   ação "cozinha" -> fogão a lenha (receitas)
##   outro texto    -> mensagem curta ao apertar E

@export var layout: StringName = &"casa"

const LAYOUTS := {
    &"casa": {
        "name": "Sua casa", "outside": &"farm", "outside_spawn": &"", "save_outside": false,
        "door": Vector2i(4, 11), "bed_spot": Vector2(40, 92),
        "items": [
            ["quadro_ipe", Vector2(72, 40), Vector2.ZERO, "", ""],
            ["relogio_parede", Vector2(114, 46), Vector2.ZERO, "", ""],
            ["cama_jogador", Vector2(36, 78), Vector2(18, 16), "Dormir (passa o dia e salva)", "dormir"],
            ["comoda_santo", Vector2(84, 72), Vector2(18, 8), "Olhar o oratório", "O oratório da vó. A vela ainda acende todo dia."],
            ["guarda_roupa", Vector2(124, 78), Vector2(20, 10), "Abrir o guarda-roupa", "Roupa de roça, chapéu de palha reserva e um terno que nunca saiu do cabide."],
            ["tapete_redondo", Vector2(76, 136), Vector2.ZERO, "", ""],
            ["vaso_planta", Vector2(24, 172), Vector2(8, 4), "", ""],
            ["prateleira_panelas", Vector2(282, 44), Vector2.ZERO, "", ""],
            ["fogao_casa", Vector2(196, 74), Vector2(32, 10), "Cozinhar no fogão a lenha", "cozinha"],
            ["pia", Vector2(246, 70), Vector2(24, 8), "Lavar a louça", "Louça lavada. A água do poço é geladinha."],
            ["filtro_barro", Vector2(290, 72), Vector2(10, 6), "Beber água do filtro", "Água de filtro de barro: a mais gostosa que tem."],
            ["mesa_xadrez", Vector2(236, 142), Vector2(28, 10), "", ""],
            ["cadeira", Vector2(216, 138), Vector2(8, 4), "", ""],
            ["cadeira", Vector2(256, 138), Vector2(8, 4), "", ""],
            ["banco_madeira_casa", Vector2(236, 160), Vector2(22, 4), "", ""],
            ["sacos", Vector2(290, 174), Vector2(18, 6), "Olhar os sacos", "Feijão e milho guardados. Fartura é saco cheio."],
        ],
    },
    &"casa_helena": {
        "name": "Casa da Helena", "outside": &"vila", "outside_spawn": &"porta_casa_azul", "save_outside": true,
        "door": Vector2i(12, 11),
        "items": [
            ["quadro_paisagem", Vector2(72, 40), Vector2.ZERO, "", ""],
            ["cama_helena", Vector2(36, 78), Vector2(28, 16), "Olhar a cama", "Colcha de crochê azul, sem uma dobra fora do lugar."],
            ["comoda_vaso", Vector2(88, 74), Vector2(18, 8), "", ""],
            ["guarda_roupa_branco", Vector2(124, 78), Vector2(20, 10), "", ""],
            ["tapete_azul", Vector2(76, 132), Vector2.ZERO, "", ""],
            ["vaso_planta", Vector2(24, 172), Vector2(8, 4), "", ""],
            ["vaso_planta", Vector2(128, 172), Vector2(8, 4), "", ""],
            ["quadro_ipe", Vector2(232, 40), Vector2.ZERO, "", ""],
            ["fogao_gas", Vector2(176, 70), Vector2(16, 8), "Olhar o fogão", "Um bule de café ainda morno em cima do fogão."],
            ["pia", Vector2(212, 70), Vector2(24, 8), "", ""],
            ["filtro_barro", Vector2(258, 72), Vector2(10, 6), "", ""],
            ["mesa_azul", Vector2(220, 140), Vector2(24, 10), "Olhar a mesa", "Caderninho de contas da mercearia, cheio de anotação."],
            ["cadeira_azul", Vector2(200, 136), Vector2(8, 4), "", ""],
            ["cadeira_azul", Vector2(240, 136), Vector2(8, 4), "", ""],
        ],
    },
    &"casa_alzira": {
        "name": "Casa da Dona Alzira", "outside": &"vila", "outside_spawn": &"porta_casa_amarela", "save_outside": true,
        "door": Vector2i(17, 11),
        "items": [
            ["quadro_paisagem", Vector2(64, 40), Vector2.ZERO, "", ""],
            ["cama_alzira", Vector2(36, 78), Vector2(18, 16), "Olhar a cama", "Cama da Dona Alzira. Tem um terço pendurado na cabeceira."],
            ["comoda_santo", Vector2(88, 72), Vector2(18, 8), "", ""],
            ["tapete_redondo", Vector2(64, 132), Vector2.ZERO, "", ""],
            ["cama_joao", Vector2(148, 78), Vector2(16, 16), "Olhar a cama", "Cama do João Pedro. Cheiro de rio e uma revista de pescaria no travesseiro."],
            ["varas_pesca", Vector2(204, 46), Vector2.ZERO, "", ""],
            ["barril", Vector2(206, 92), Vector2(12, 6), "Olhar o balde", "Isca e linha emaranhada. O João jura que tá organizado."],
            ["prateleira_panelas", Vector2(318, 44), Vector2.ZERO, "", ""],
            ["fogao_casa", Vector2(264, 74), Vector2(32, 10), "Olhar o fogão", "Panela de galinhada borbulhando. Que cheiro!"],
            ["pia", Vector2(318, 72), Vector2(24, 8), "", ""],
            ["mesa_madeira", Vector2(300, 140), Vector2(28, 10), "", ""],
            ["cadeira", Vector2(280, 136), Vector2(8, 4), "", ""],
            ["banco_madeira_casa", Vector2(300, 158), Vector2(22, 4), "", ""],
            ["sacos", Vector2(250, 174), Vector2(18, 6), "", ""],
        ],
    },
    &"casa_toninho": {
        "name": "Ferraria do Toninho", "outside": &"vila", "outside_spawn": &"porta_ferreiro", "save_outside": true,
        "door": Vector2i(5, 11),
        "items": [
            ["ferramentas_parede", Vector2(56, 44), Vector2.ZERO, "", ""],
            ["ferramentas_parede", Vector2(140, 44), Vector2.ZERO, "", ""],
            ["barril", Vector2(24, 80), Vector2(12, 6), "", ""],
            ["bancada", Vector2(100, 76), Vector2(22, 6), "Olhar a bancada", "Lâmina de facão esperando cabo novo."],
            ["bigorna", Vector2(80, 124), Vector2(16, 6), "Olhar a bigorna", "A bigorna ainda tá quente. Não encosta!"],
            ["sacos", Vector2(160, 170), Vector2(18, 6), "Olhar os sacos", "Carvão pra forja. Muito carvão."],
            ["quadro_paisagem", Vector2(256, 40), Vector2.ZERO, "", ""],
            ["cama_toninho", Vector2(212, 78), Vector2(18, 16), "Olhar a cama", "Cama do Toninho. Simples, pesada... e com uma bigorna de enfeite do lado."],
            ["comoda_vaso", Vector2(254, 74), Vector2(18, 8), "", ""],
            ["filtro_barro", Vector2(262, 172), Vector2(10, 6), "", ""],
        ],
    },
    &"casa_mariana": {
        "name": "Clínica da Mariana", "outside": &"vila", "outside_spawn": &"porta_clinica", "save_outside": true,
        "door": Vector2i(5, 11),
        "items": [
            ["quadro_paisagem", Vector2(40, 40), Vector2.ZERO, "", ""],
            ["vaso_planta", Vector2(24, 80), Vector2(8, 4), "", ""],
            ["maca", Vector2(110, 80), Vector2(28, 8), "Olhar a maca", "Maca de atender bezerro. Tem pelo de cachorro grudado."],
            ["armario_remedio", Vector2(156, 74), Vector2(16, 8), "Olhar o armário", "Vermífugo, vacina, pomada de casco. Tudo etiquetado."],
            ["balcao_clinica", Vector2(80, 140), Vector2(32, 8), "Ler o caderno", "Fichas dos bichos do vale. A sua ainda tá em branco."],
            ["cadeira", Vector2(28, 140), Vector2(8, 4), "", ""],
            ["cadeira", Vector2(28, 168), Vector2(8, 4), "", ""],
            ["estante", Vector2(268, 78), Vector2(20, 10), "Olhar a estante", "Livro de zoologia, guia de aves do cerrado e um romance pela metade."],
            ["cama_mariana", Vector2(212, 78), Vector2(18, 16), "Olhar a cama", "Cama da Mariana, colcha branquinha de crochê."],
            ["tapete_verde", Vector2(240, 128), Vector2.ZERO, "", ""],
            ["fogao_gas", Vector2(290, 172), Vector2(16, 8), "", ""],
            ["filtro_barro", Vector2(266, 172), Vector2(10, 6), "", ""],
        ],
    },
}

var bed: Prop
var stove: Prop
## Tapetes e capacho: ficam no chão, sempre embaixo de quem passa.
var _floor_decor: Node2D


func _enter_tree() -> void:
    var info: Dictionary = LAYOUTS[layout]
    region_id = layout
    display_name = info.name
    indoor = true
    if info.save_outside:
        save_as_region = info.outside
        save_as_spawn = info.outside_spawn
    var g := get_node_or_null("Ground") as FarmGround
    if g:
        g.map_path = "res://data/maps/interior_%s.txt" % layout


func _ready() -> void:
    super._ready()
    var info: Dictionary = LAYOUTS[layout]
    _build_backdrop()
    _floor_decor = Node2D.new()
    _floor_decor.name = "Tapetes"
    add_child(_floor_decor)
    move_child(_floor_decor, ground.get_index() + 1)
    var door: Vector2i = info.door
    var door_pos := Vector2(door.x * FarmGround.TILE_SIZE + 8, door.y * FarmGround.TILE_SIZE + 8)
    _marker(&"entrada", door_pos + Vector2(0, -18), 4)
    player_spawn.position = door_pos + Vector2(0, -18)
    if info.has("bed_spot"):
        _marker(&"cama", info.bed_spot, 0)
    # capacho e saída
    var mat := Prop.new().setup("capacho", Vector2.ZERO, "")
    mat.position = door_pos + Vector2(0, -6)
    _floor_decor.add_child(mat)
    var exit := RegionExit.new()
    exit.name = "Saida"
    exit.target_region = info.outside
    exit.target_spawn = info.outside_spawn
    exit.position = door_pos + Vector2(0, 4)
    var shape := CollisionShape2D.new()
    var r := RectangleShape2D.new()
    r.size = Vector2(16, 8)
    shape.shape = r
    exit.add_child(shape)
    add_child(exit)
    for it: Array in info.items:
        _add_item(it)


func _add_item(it: Array) -> void:
    var p := Prop.new().setup(it[0], it[2], it[3], 14.0)
    p.position = it[1]
    if String(it[0]).begins_with("tapete"):
        _floor_decor.add_child(p)
    else:
        get_entities_root().add_child(p)
    var action: String = it[4]
    match action:
        "":
            pass
        "dormir":
            bed = p
            p.used.connect(func(_a: Node) -> void: HouseDoor.sleep_and_save())
        "cozinha":
            stove = p
            p.used.connect(func(_a: Node) -> void: EventBus.craft_requested.emit("cozinha"))
        _:
            p.used.connect(func(_a: Node) -> void: EventBus.show_message(action, 3.0))


func _marker(n: StringName, pos: Vector2, facing: int) -> void:
    var markers := get_node_or_null("Markers")
    if markers == null:
        markers = Node2D.new()
        markers.name = "Markers"
        add_child(markers)
    var m := Marker2D.new()
    m.name = n
    m.position = pos
    m.set_meta("facing", facing)
    markers.add_child(m)


## Fundo escuro em volta da casa (a câmera mostra além das paredes).
func _build_backdrop() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.1, 0.07, 0.06)
    bg.position = Vector2(-1000, -1000)
    bg.size = Vector2(2000 + get_world_rect().size.x, 2000 + get_world_rect().size.y)
    bg.z_index = -20
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    move_child(bg, 0)
