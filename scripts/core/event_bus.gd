extends Node
## Barramento global de sinais (autoload "EventBus").
##
## Sistemas falam entre si por aqui em vez de guardar referência um do outro.
## Ex.: o pequizeiro não conhece o HUD; ele só emite message_requested.

## Pede para a interface mostrar uma mensagem curta.
signal message_requested(text: String, duration: float)

## O alvo de interação mais próximo do jogador mudou. Texto vazio = nenhum alvo.
signal interaction_prompt_changed(text: String)

## Um item entrou no estado do jogador. `total` é a quantidade após a soma.
signal item_collected(item_id: StringName, amount: int, total: int)

## Controles de toque ligados (celular) ou desligados (teclado/controle).
signal touch_mode_changed(enabled: bool)

## Jogo pausado/retomado pelo menu.
signal pause_changed(paused: bool)


func show_message(text: String, duration: float = 2.5) -> void:
    message_requested.emit(text, duration)
