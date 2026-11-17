class_name HouseDoor
extends StaticBody2D
## Porta da casa principal: dormir passa o dia e salva o jogo.
## PROVISÓRIO: sem interior ainda (a casa por dentro entra mais adiante).

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
    interactable.prompt = "Dormir (passa o dia e salva)"
    interactable.interacted.connect(_on_interacted)


func _on_interacted(_actor: Node) -> void:
    GameState.sleep()
    var ok := SaveManager.save_game()
    EventBus.show_message("Bom dia! %s — %s.%s" % [Calendar.format_date(GameState.day), Clock.weather_name(),
        " Jogo salvo." if ok else ""], 3.0)
