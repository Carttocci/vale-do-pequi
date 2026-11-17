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

## Fase 3
| Mecânica | Como funciona | Onde ajustar |
|---|---|---|
| Velocidade do tempo | 10 min de jogo a cada 7 s reais | `real_seconds_per_step` em scripts/core/clock.gd |
| Duração do dia | 06:00 às 02:00; às 02:00 apaga e acorda em casa | `DAY_START`, `DAY_END` |
| Calendário | 10 dias por mês, começa em 1º de outubro | `DAYS_PER_MONTH`, `START_MONTH` em scripts/core/calendar.gd |
| Períodos | Chuvoso out–abr, seco mai–set | `DRY_MONTHS` |
| Clima | Chances por período | `CHANCES_RAINY`, `CHANCES_DRY` em clock.gd |
| Chuva | Rega toda a terra capinada no começo do dia | FarmField `_on_day_started` |
| Época das culturas | `periods` em cada cultura | data/crops/*.tres |
| Safra do pequi | outubro a janeiro | `PEQUI_MONTHS` |

## Fase 4
| Mecânica | Como funciona | Onde ajustar |
|---|---|---|
| Regiões | Fazenda ↔ Vila pela estrada leste/oeste | `RegionExit` nas cenas; `Markers/` de chegada |
| Rotina dos moradores | "HH:MM marcador" (com "!" entra em casa); domingo separado | data/npcs/*.tres (`schedule`, `schedule_sunday`) |
| Velocidade ao andar | 42 px/s, caminho A* na grade da região | `SPEED` em scripts/npc/npc.gd |
| Amizade | +10 na 1ª conversa do dia; falas de amigo a partir de 50 | `TALK_FRIENDSHIP`, `FRIEND_THRESHOLD` |
| Dinheiro inicial | R$ 200 | `STARTING_MONEY` em game_state.gd |
| Preços | `buy_price` (loja vende) e `sell_price` (loja compra) | data/items/*.tres |
| Mercearia | Vende sementes; compra colheitas (CROP) e coleta (FORAGE) | `shop_*` em data/npcs/helena.tres |

## Fase 7
| Mecânica | Como funciona | Onde ajustar |
|---|---|---|
| Missões | História (encadeada, começa sozinha) e pedidos do mural (a partir de `min_day`). Etapas: talk, deliver, reach, flag, min_flag, kill, observe, collect | data/quests.json |
| Marcos da história | `GameState.flags` (trilha_serra_aberta, mina_fundo, guardiao_derrotado, totens_resolvidos, eco_derrotado, ato1_completo) | scripts/core/game_state.gd |
| Mineração | Picareta: 2 de energia por golpe; força +1 a cada 4 níveis de mineração | `ENERGY` em scripts/mining/mining.gd |
| Pedras | pedra 2 golpes, ferro/quartzo 3, ouro 4, cristal/pedregulho 5–4; itens e XP | `KINDS` em scripts/mining/rock.gd |
| Mina | 10 andares (40×23); semente = andar + dia; 14+2×andar pedras, 2+andar/2 criaturas (vida +12% por andar); elevador no 5 e no 10 | scripts/mining/mine_level.gd |
| Minério por profundidade | 1–3 pedra/ferro · 4–6 + quartzo · 7–9 + ouro e cristal | `_ore_for_depth` |
| Guardião de Cristal | 260 de vida; a cada 3,2 s estilhaços (8, depois 12) + investida; metade da vida chama 2 morcegos | `KINDS` em enemy.gd, scripts/combat/boss.gd |
| Eco do Silêncio | 320 de vida; reaparece ao lado do jogador e solta 3 orbes (8 de dano, −10 de energia) | idem |
| Enigma dos totens | Ordem sol → chuva → lua; errar apaga todos | `ORDER` em scripts/world/ruinas_level.gd |

## Fase 8
| Mecânica | Como funciona | Onde ajustar |
|---|---|---|
| Receitas | Fogão (cozinha), bancada e obras; `known` = sabe desde o começo, `teacher` = morador que ensina aos 2 ♥ | data/recipes.json |
| Comida | energia, vida e efeito por item | `energy`, `health`, `buff` em tools/gerar_itens.py |
| Efeitos | combate ×1,25 dano · folego: energia ÷2 (arredonda pra cima) · rapidez ×1,2 velocidade · pesca: espera ÷2. Acaba ao dormir | game_state.gd (`melee_multiplier`, `use_energy`, `speed_multiplier`), fishing_ui.gd |
| Amizade | 100 pontos = 1 ♥ (máx. 10). Conversa +10/dia; presente adorado +80, gostou +45, neutro +20, detestou −20 (1 por dia) | `HEART_POINTS`, `GIFT_POINTS` em npc.gd; gostos em data/npcs/*.tres |
| Conversas especiais | 2 ♥ ensina receita; 4 ♥ lembrança + presente | data/heart_events.json |
| Festas | Festa do Pequi 5/dez, Folia de Reis 6/jan, Cavalhadas 8/mai, Festa Junina 9/jun; moradores na praça das 9h às 22h | `ALL` em scripts/events/festivals.gd; atrações em vila_level.gd |
| Lembranças do vale | 1ª vez de cada receita, cada festa (por ano), cada conversa especial | `GameState.add_memory` |
| Obras | caixa d'água (regador 40), galinheiro 10, curral 6 | data/recipes.json (`obras`), ranch.gd `capacity` |
