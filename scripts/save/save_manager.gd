extends Node
## Salvar e carregar o jogo (autoload "SaveManager").
##
## Formato: JSON em user:// (no navegador o Godot guarda no IndexedDB, então
## o save sobrevive a fechar a aba). Estrutura:
##   {
##     "version": int,          ← GameState.DATA_VERSION de quem salvou
##     "saved_at": "AAAA-MM-DDTHH:MM:SS",
##     "game":   {...},         ← GameState.to_data()
##     "clock":  {...},         ← Clock.to_data() (desde a v2)
##     "player": {"x", "y", "facing"},
##     "nodes":  {"<caminho do nó>": {...}}   ← nós do grupo "persistent"
##   }
## Nós persistentes implementam get_save_data() e load_save_data(data).
##
## Compatibilidade (GDD §14.4): saves antigos passam por migrate() antes de
## serem aplicados. Ao mudar o formato, aumente GameState.DATA_VERSION e
## adicione um passo em _MIGRATIONS.

signal saved
signal loaded

var save_path: String = "user://vale_do_pequi_save.json"

## versão_de_origem -> Callable(data) que devolve os dados na versão seguinte.
var _MIGRATIONS: Dictionary = {
    # v1 (Fase 2) → v2 (Fase 3): entrou o relógio/clima. Saves antigos começam
    # o dia às 06:00, ensolarado, e o pequizeiro respeita a safra.
    1: func(d: Dictionary) -> Dictionary:
        d["clock"] = {"minutes": Clock.DAY_START, "weather": "ensolarado", "seed": randi()}
        return d,
    # v2 (Fase 3) → v3 (Fase 4): dinheiro e região atual. Quem já jogava
    # ganha o dinheiro inicial e continua na fazenda.
    2: func(d: Dictionary) -> Dictionary:
        d["game"] = d.get("game", {})
        d.game["money"] = GameState.STARTING_MONEY
        d["player"] = d.get("player", {})
        d.player["region"] = "farm"
        return d,
}


func has_save() -> bool:
    return FileAccess.file_exists(save_path)


func save_game() -> bool:
    var data := _collect()
    var file := FileAccess.open(save_path, FileAccess.WRITE)
    if file == null:
        push_error("SaveManager: não consegui gravar (%d)" % FileAccess.get_open_error())
        EventBus.show_message("Não consegui salvar o jogo.", 3.0)
        return false
    file.store_string(JSON.stringify(data, "  "))
    file.close()
    saved.emit()
    return true


## Carrega o save. Retorna false (sem alterar nada) se não existir, estiver
## corrompido ou vier de uma versão mais nova do jogo.
func load_game() -> bool:
    var data := read_save_file()
    if data.is_empty():
        return false
    data = migrate(data)
    if data.is_empty():
        return false
    _apply(data)
    loaded.emit()
    return true


func read_save_file() -> Dictionary:
    if not has_save():
        return {}
    var text := FileAccess.get_file_as_string(save_path)
    var json := JSON.new()
    if json.parse(text) != OK or not json.data is Dictionary:
        push_warning("SaveManager: save corrompido, ignorado.")
        return {}
    return json.data


func delete_save() -> void:
    if has_save():
        DirAccess.remove_absolute(save_path)


## Leva os dados de qualquer versão antiga até a atual.
func migrate(data: Dictionary) -> Dictionary:
    var version := int(data.get("version", 0))
    if version > GameState.DATA_VERSION:
        push_warning("SaveManager: save de versão mais nova (%d), ignorado." % version)
        return {}
    if version < 1:
        # Versão 0 = save sem número de versão (não deveria existir, mas
        # tratamos como v1 incompleto: o que faltar usa o padrão).
        version = 1
    while version < GameState.DATA_VERSION:
        if not _MIGRATIONS.has(version):
            push_error("SaveManager: falta migração da versão %d" % version)
            return {}
        data = _MIGRATIONS[version].call(data)
        version += 1
    data["version"] = version
    return data


func _collect() -> Dictionary:
    var nodes := {}
    for node in get_tree().get_nodes_in_group("persistent"):
        if node.has_method("get_save_data"):
            nodes[_key(node)] = node.get_save_data()
    var player_data := {}
    var player := get_tree().get_first_node_in_group("player") as Player
    if player:
        player_data = {"x": player.global_position.x, "y": player.global_position.y, "facing": player.facing_index,
            "region": String(_current_region())}
    return {
        "version": GameState.DATA_VERSION,
        "saved_at": Time.get_datetime_string_from_system(),
        "game": GameState.to_data(),
        "clock": Clock.to_data(),
        "player": player_data,
        "nodes": nodes,
    }


func _apply(data: Dictionary) -> void:
    GameState.from_data(data.get("game", {}))
    Clock.from_data(data.get("clock", {}))
    var nodes: Dictionary = data.get("nodes", {})
    for node in get_tree().get_nodes_in_group("persistent"):
        var key := _key(node)
        if nodes.has(key) and node.has_method("load_save_data"):
            node.load_save_data(nodes[key])
    var p: Dictionary = data.get("player", {})
    var main := get_tree().get_first_node_in_group("save_root")
    if main and main.has_method("change_region_now"):
        main.change_region_now(StringName(p.get("region", "farm")), &"")
    var player := get_tree().get_first_node_in_group("player") as Player
    if player and p.has("x"):
        player.global_position = Vector2(float(p.x), float(p.y))
        player.velocity = Vector2.ZERO
        player.face(int(p.get("facing", 0)))
        player.camera.reset_smoothing()


## Chave estável: caminho do nó a partir da cena principal (grupo "save_root"),
## ex.: "Farm/Entities/Bau". Funciona igual no jogo e nos testes.
func _key(node: Node) -> String:
    var main := get_tree().get_first_node_in_group("save_root")
    if main == null:
        main = get_tree().current_scene
    if main and main.is_ancestor_of(node):
        return String(main.get_path_to(node))
    return String(node.name)


func _current_region() -> StringName:
    var main := get_tree().get_first_node_in_group("save_root")
    if main and "level" in main and main.level:
        return main.level.region_id
    return &"farm"
