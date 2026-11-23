class_name HouseDoor
extends StaticBody2D
## Porta da casa principal: entra em casa (lá dentro tem a cama, o fogão...).
## A cama chama HouseDoor.sleep_and_save() para passar o dia e salvar.

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
    interactable.prompt = "Entrar em casa"
    interactable.interacted.connect(_on_interacted)


func _on_interacted(_actor: Node) -> void:
    Audio.play(&"porta")
    EventBus.region_change_requested.emit(&"casa", &"entrada")


## Dormir: passa o dia e salva o jogo.
static func sleep_and_save() -> void:
    GameState.sleep()
    var ok := SaveManager.save_game()
    EventBus.show_message("Bom dia! %s — %s.%s" % [Calendar.format_date(GameState.day), Clock.weather_name(),
        " Jogo salvo." if ok else ""], 3.0)
