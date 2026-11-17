class_name FarmLevel
extends Level
## Região "Fazenda do Pequi". Toda a lógica comum de região está em Level.
## Aqui ficam o fogão a lenha (receitas) e a bancada (objetos e obras).

const FOGAO_POS := Vector2(404, 128)
const BANCADA_POS := Vector2(536, 152)

var fogao: Prop
var bancada: Prop


func _ready() -> void:
    super._ready()
    fogao = Prop.new().setup("fogao_lenha", Vector2(22, 8), "Cozinhar no fogão a lenha", 14.0)
    fogao.name = "FogaoLenha"
    fogao.position = FOGAO_POS
    fogao.used.connect(func(_a: Node) -> void: EventBus.craft_requested.emit("cozinha"))
    get_entities_root().add_child(fogao)
    bancada = Prop.new().setup("bancada", Vector2(22, 6), "Usar a bancada", 14.0)
    bancada.name = "Bancada"
    bancada.position = BANCADA_POS
    bancada.used.connect(func(_a: Node) -> void: EventBus.craft_requested.emit("bancada"))
    get_entities_root().add_child(bancada)
