# Mecânicas implementadas

## Fase 1
| Mecânica | Como funciona | Onde ajustar |
|---|---|---|
| Andar | 80 px/s, aceleração 900, atrito 1200 | Inspector do `Player` (scenes/player/player.tscn) |
| Animação | 8 fps, 4 quadros por direção | `walk_fps` no Player |
| Interagir | E (ou A no controle) com o objeto à frente | `interact_reach` no Player |
| Catar pequi | 3 frutos por pé, voltam em 20 s | `fruits_on_ground`, `regrow_seconds` em cada Pequizeiro |
| Pausa | Esc / Start | scripts/interface/hud.gd |
| Tela cheia | F11 | scripts/core/main.gd |
| Analógico virtual (celular) | Toque e arraste no lado esquerdo; raio 24 px | `radius` no nó Joystick (scenes/interface/touch_controls.tscn) |
| Botões de toque | Interagir, pausa, tela cheia, presos à borda direita | scripts/interface/touch_controls.gd › `_layout()` |
