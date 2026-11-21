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


## Cor do chão/mato por mês: verde vivo nas chuvas, amarelando na seca
## (o pior é agosto/setembro, antes das primeiras chuvas).
const SEASON_TINTS := [
    Color(1.0, 1.04, 0.98), Color(1.0, 1.04, 0.98), Color(1.0, 1.03, 0.98), Color(1.02, 1.02, 0.96),  # jan-abr
    Color(1.08, 1.0, 0.86), Color(1.16, 0.98, 0.74), Color(1.24, 0.96, 0.62), Color(1.32, 0.94, 0.54),  # mai-ago
    Color(1.32, 0.93, 0.54), Color(1.04, 1.02, 0.94), Color(1.0, 1.04, 0.98), Color(1.0, 1.04, 0.98),  # set-dez
]
## Ipê floresce no fim da seca (agosto e setembro).
const IPE_MONTHS := [7, 8]


static func season_tint(day: int) -> Color:
    return SEASON_TINTS[month_index(day)]


static func is_ipe_bloom(day: int) -> bool:
    return month_index(day) in IPE_MONTHS


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
