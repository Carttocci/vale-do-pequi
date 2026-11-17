class_name Calendar
extends RefCounted
## Calendário do Vale do Pequi (só funções; o estado é o dia em GameState).
##
## Ano de 12 meses com os nomes reais, cada mês com DAYS_PER_MONTH dias.
## O jogo começa em 1º de outubro: começo das chuvas e da safra do pequi.
## Clima do Cerrado (GDD §11):
##   período chuvoso = outubro a abril · período seco = maio a setembro.

const DAYS_PER_MONTH := 10
const START_MONTH := 9  # 0 = janeiro → 9 = outubro
const MONTHS := ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]
const MONTHS_FULL := ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho",
    "agosto", "setembro", "outubro", "novembro", "dezembro"]
const WEEKDAYS := ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
const DRY_MONTHS := [4, 5, 6, 7, 8]  # maio a setembro
## Safra do pequi: outubro a janeiro.
const PEQUI_MONTHS := [9, 10, 11, 0]

const PERIOD_RAINY := &"chuvoso"
const PERIOD_DRY := &"seco"


static func month_index(day: int) -> int:
    return (START_MONTH + (day - 1) / DAYS_PER_MONTH) % 12


static func day_of_month(day: int) -> int:
    return (day - 1) % DAYS_PER_MONTH + 1


static func year(day: int) -> int:
    return 1 + (START_MONTH + (day - 1) / DAYS_PER_MONTH) / 12


static func weekday(day: int) -> String:
    return WEEKDAYS[(day - 1) % 7]


static func period(day: int) -> StringName:
    return PERIOD_DRY if month_index(day) in DRY_MONTHS else PERIOD_RAINY


static func period_name(day: int) -> String:
    return "Período chuvoso" if period(day) == PERIOD_RAINY else "Período seco"


static func is_pequi_season(day: int) -> bool:
    return month_index(day) in PEQUI_MONTHS


## "Seg, 1 Out"
static func format_date(day: int) -> String:
    return "%s, %d %s" % [weekday(day), day_of_month(day), MONTHS[month_index(day)]]


## "segunda... 1º de outubro, ano 1" (para mensagens)
static func format_date_long(day: int) -> String:
    var dom := day_of_month(day)
    return "%s de %s, ano %d" % ["1º" if dom == 1 else str(dom), MONTHS_FULL[month_index(day)], year(day)]


## 390 → "06:30"; passa da meia-noite: 1500 → "01:00"
static func format_time(minutes: int) -> String:
    return "%02d:%02d" % [(minutes / 60) % 24, minutes % 60]
