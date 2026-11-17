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

## Fase 2
| Mecânica | Como funciona | Onde ajustar |
|---|---|---|
| Capinar | Enxada na célula à frente; só grama, flores, capim e terra arada, sem obstáculo | `TILLABLE_GROUND` em scripts/farming/farm_field.gd |
| Regar | 1 água por célula; regador guarda 20; enche no poço (grupo `water_source`) ou na água | `WATER_MAX` em scripts/core/game_state.gd |
| Crescer | Só nos dias regados; `stage_days` define os estágios | data/crops/*.tres |
| Colher | E na planta madura; feijão rebrota | `harvest_min/max`, `regrow_days` |
| Dormir | Porta da casa: +1 dia, salva | scripts/world/house_door.gd |
| Mochila | 27 espaços, pilha 99, ferramentas 1 | `INVENTORY_SIZE`, `max_stack` |
| Baú | 18 espaços; toque transfere a pilha | scripts/world/chest.gd |
| Itens iniciais | enxada, regador, 12 milho, 8 feijão; baú: abóbora, mandioca, milho | `STARTING_ITEMS`, `starting_items` do baú |
