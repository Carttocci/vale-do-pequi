class_name CropData
extends Resource
## Definição de uma cultura (milho, feijão...). Arquivos em data/crops/.
##
## Crescimento: a planta só avança nos dias em que foi regada.
## `stage_days[i]` = dias regados que ela passa no estágio i.
## Com N valores em stage_days, existem N+1 texturas: a última é a planta madura.

@export var id: StringName
@export var display_name: String = ""
@export var seed_item: StringName
@export var harvest_item: StringName
@export var stage_days: PackedInt32Array = PackedInt32Array([1, 1, 1])
@export var stage_textures: Array[Texture2D] = []
@export var harvest_min: int = 1
@export var harvest_max: int = 1
## 0 = acaba depois da colheita. >0 = volta a produzir após esse número de dias regados.
@export var regrow_days: int = 0
## TODO(Fase 3): estações/períodos permitidos (chuvoso/seco).


func days_to_mature() -> int:
    var total := 0
    for d in stage_days:
        total += d
    return total


## Estágio visual para uma idade (dias regados acumulados).
func stage_for_age(age: int) -> int:
    var acc := 0
    for i in stage_days.size():
        acc += stage_days[i]
        if age < acc:
            return i
    return stage_days.size()


func is_mature(age: int) -> bool:
    return age >= days_to_mature()
