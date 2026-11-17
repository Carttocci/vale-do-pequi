class_name Festivals
extends RefCounted
## Festas tradicionais do calendário (GDD §12). Todo ano, na praça da vila:
## o povo todo vai pra praça das 9h às 22h e cada festa tem a sua atração.

## id -> {name, month (0 = jan), day, desc}
const ALL := {
    &"festa_pequi": {"name": "Festa do Pequi", "month": 11, "day": 5,
        "desc": "Concurso do pequi e barraca de arroz com pequi na praça."},
    &"folia_reis": {"name": "Folia de Reis", "month": 0, "day": 6,
        "desc": "Os foliões passam com a bandeira cantando e abençoando as casas."},
    &"cavalhadas": {"name": "Cavalhadas", "month": 4, "day": 8,
        "desc": "Mouros e cristãos se enfrentam a cavalo; os mascarados fazem a festa."},
    &"festa_junina": {"name": "Festa Junina", "month": 5, "day": 9,
        "desc": "Fogueira, quadrilha, pescaria e comida de milho."},
}


## Festa de hoje (ou &"" se não tiver).
static func today(day: int) -> StringName:
    var m := Calendar.month_index(day)
    var d := Calendar.day_of_month(day)
    for id: StringName in ALL:
        if int(ALL[id].month) == m and int(ALL[id].day) == d:
            return id
    return &""


## Dia do jogo da próxima festa a partir de `day` (inclusive) e qual é.
static func next(day: int) -> Dictionary:
    for d in range(day, day + Calendar.DAYS_PER_MONTH * 12 + 1):
        var f := today(d)
        if f != &"":
            return {"id": f, "day": d}
    return {}


static func name_of(id: StringName) -> String:
    return ALL[id].name if ALL.has(id) else ""
