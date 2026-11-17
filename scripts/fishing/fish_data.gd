class_name FishData
extends Resource
## Onde e quando um peixe aparece, e quão difícil é pegar.
## Arquivos em data/fish/ (gerados por tools/gerar_peixes.py).

@export var item: StringName
## "lagoa" e/ou "rio".
@export var habitats: PackedStringArray = PackedStringArray()
## Janela de horário em minutos do dia (pode passar da meia-noite: 1080..1560).
@export var from_minute: int = 360
@export var to_minute: int = 1560
## Vazio = o ano todo. Senão "chuvoso"/"seco".
@export var periods: PackedStringArray = PackedStringArray()
## Vazio = qualquer clima. Senão chaves do Clock ("chuva", "tempestade"...).
@export var weathers: PackedStringArray = PackedStringArray()
## 1 (fácil) a 5 (lendário).
@export var difficulty: int = 1
## Peso no sorteio entre os peixes possíveis.
@export var weight: float = 1.0


func available(habitat: String, minutes: int, period: StringName, weather_key: String) -> bool:
    if not habitat in habitats:
        return false
    if minutes < from_minute or minutes > to_minute:
        return false
    if not periods.is_empty() and not String(period) in periods:
        return false
    if not weathers.is_empty() and not weather_key in weathers:
        return false
    return true
