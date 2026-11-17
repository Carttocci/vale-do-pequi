class_name NpcData
extends Resource
## Ficha de um morador: quem é, rotina, falas e loja (se tiver).
## Um arquivo por morador em data/npcs/.
##
## Rotina: linhas "HH:MM marcador". A partir daquele horário o morador vai
## andando até o marcador (Level/Markers/<marcador>). Com "!" no fim, ao chegar
## ele entra em casa (some). Ex.: "07:30 mercearia_balcao", "20:00 casa_azul!".

@export var id: StringName
@export var display_name: String = ""
@export var profession: String = ""
@export var sprite: Texture2D
@export var schedule: PackedStringArray = PackedStringArray()
## Rotina de domingo (vazia = igual aos outros dias).
@export var schedule_sunday: PackedStringArray = PackedStringArray()

@export_group("Falas")
## Primeira conversa (mostradas em sequência, uma vez só).
@export var intro: PackedStringArray = PackedStringArray()
@export var lines_morning: PackedStringArray = PackedStringArray()
@export var lines_afternoon: PackedStringArray = PackedStringArray()
@export var lines_evening: PackedStringArray = PackedStringArray()
@export var lines_rain: PackedStringArray = PackedStringArray()
@export var lines_dry: PackedStringArray = PackedStringArray()
## Liberadas com amizade >= FRIEND_THRESHOLD.
@export var lines_friend: PackedStringArray = PackedStringArray()
@export var lines_generic: PackedStringArray = PackedStringArray()
## Quando já conversaram hoje.
@export var lines_repeat: PackedStringArray = PackedStringArray()

@export_group("Loja")
## Marcador onde o morador atende. Loja aberta = morador parado ali.
@export var shop_marker: StringName = &""
@export var shop_title: String = ""
## Itens à venda (ids).
@export var shop_sells: PackedStringArray = PackedStringArray()
## Categorias que o morador compra (ItemData.Category).
@export var shop_buys: PackedInt32Array = PackedInt32Array()

const FRIEND_THRESHOLD := 50


func has_shop() -> bool:
    return shop_marker != &""


## Rotina válida para o dia (domingo pode ser diferente).
func schedule_for_day(day: int) -> PackedStringArray:
    if Calendar.weekday(day) == "Dom" and not schedule_sunday.is_empty():
        return schedule_sunday
    return schedule


## Entrada da rotina em vigor no horário: {"marker": StringName, "inside": bool}.
func schedule_entry_at(day: int, minutes: int) -> Dictionary:
    var current := {}
    for line in schedule_for_day(day):
        var parts := line.strip_edges().split(" ", false)
        if parts.size() != 2:
            continue
        var hm := parts[0].split(":")
        var at := int(hm[0]) * 60 + int(hm[1])
        if at <= minutes or current.is_empty():
            var marker := parts[1]
            current = {"marker": StringName(marker.trim_suffix("!")), "inside": marker.ends_with("!"), "time": at}
    return current
