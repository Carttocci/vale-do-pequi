# Arquitetura técnica — Vale do Pequi

Versão do documento: 0.1.0 (Fase 1)
Motor: Godot 4.3+ · GDScript · renderizador Compatibility (OpenGL 3 / WebGL 2).
**Plataforma principal: navegador (GitHub Pages), no celular e no computador.** Build Windows continua disponível como extra.

## Princípios

1. **Um script, uma responsabilidade.** Nada de "GameManager" gigante.
2. **Sistemas conversam por sinais** via o autoload `EventBus`. Um objeto do mundo nunca chama o HUD direto.
3. **Composição em vez de herança.** Interação é um componente (`Interactable`) que se pendura em qualquer objeto.
4. **Dados fora do código.** O mapa está em `data/maps/*.txt`; itens, culturas e peixes virão como `Resource` (`.tres`) em `data/`.
5. **Regiões não possuem o jogador.** `main.gd` cria o jogador e o coloca na região atual. Trocar de região = mover o mesmo nó.
6. **Tudo que é provisório está marcado** (`_placeholder` no nome do asset, `PROVISÓRIO` no comentário do script).

## Árvore de cenas (em execução)

```
Main (main.gd)
├── Farm (farm_level.gd)               ← região atual
│   ├── Ground (TileMapLayer, farm_ground.gd)   lê data/maps/fazenda_pequi.txt
│   ├── PlayerSpawn (Marker2D)
│   ├── Entities (Node2D, y_sort)       ← objetos + jogador, ordenados pela altura
│   │   ├── CasaPrincipal, Poco, PlacaVila, Pequizeiro1..7, Ipe1..5, Cupinzeiro1..4, Arbusto1..7
│   │   ├── Fences (FenceLine x5)
│   │   └── Player  ← adicionado por main.gd
│   └── WorldBounds (criado em código)
├── HUD (CanvasLayer, hud.gd)            dicas, mensagens, contador, pausa, aviso "gire o celular"
└── TouchControls (CanvasLayer 2)        analógico virtual + botões de toque
```

## Autoloads (nesta ordem)

| Nome | Arquivo | Papel |
|---|---|---|
| `EventBus` | scripts/core/event_bus.gd | Sinais globais: mensagens, dica de interação, item coletado, baú aberto, pausa, modo toque |
| `ItemDB` | scripts/core/item_db.gd | Catálogo: lê `data/items/*.tres` (ItemData) e `data/crops/*.tres` (CropData) |
| `Clock` | scripts/core/clock.gd | Hora do dia, clima do dia, sinais `time_changed`, `day_started`, `passed_out` |
| `GameState` | scripts/core/game_state.gd | Estado do jogador: mochila, atalho selecionado, água do regador, dia |
| `Quests` | scripts/quests/quests.gd | Missões (data/quests.json): ativas, concluídas, contadores; falas de missão dos moradores |
| `SaveManager` | scripts/save/save_manager.gd | Salvar/carregar JSON com versão e migração |

## Fazenda (Fase 2)

- **Dados:** `ItemData` (id, nome, ícone, categoria, pilha, ferramenta, cultura da semente) e `CropData` (estágios por dias regados, texturas, colheita, rebrota). Itens novos = só um `.tres` novo, sem código.
- **Inventory** (`scripts/inventory/inventory.gd`): slots `null` ou `{id, count}`; pilhas, transferência, serialização tolerante a itens que deixarem de existir.
- **FarmField** (`scripts/farming/farm_field.gd`): estado por célula `{watered, crop, age}`, TileMapLayer `Soil` para a terra, um `Sprite2D` por planta dentro de `Entities/Crops` (y-sort com o jogador). Cresce no sinal `GameState.day_advanced` (só dormir; carregar save não faz crescer).
- **Botão contextual (E):** a cada quadro o Player calcula a melhor ação possível e mostra a dica: `get_cell_prompt` (grupo `cell_interaction`, prioridade 30), `get_item_action` (grupo `item_target`, prioridade que o alvo informar: 20 para encher regador, 5 para capinar/regar/plantar) e o `Interactable` à frente (10). O E executa a de maior prioridade.
- **Jogador sem acoplamento:** o Player chama `use_item(item, ponto, ator)` em todo nó do grupo `item_target` e `get_cell_prompt`/`interact_cell` nos do grupo `cell_interaction`. O FarmField é um deles; pesca, mineração etc. entram do mesmo jeito.
- **Uso por eventos:** "usar" é ligado por evento (não por polling), para que clicar na interface não use a ferramenta; no celular, o clique emulado do toque é ignorado e o botão "usar" faz o papel.

## Regiões e moradores (Fase 4)

- `Level` (scripts/world/level.gd): base de toda região. `FarmLevel` e a Vila usam. Todas ficam carregadas como filhas de `Main`; `set_active` liga/desliga visual, processamento e física (`TileMapLayer.enabled`). Navegação dos moradores: `AStarGrid2D` montado da própria região (chão sólido + corpos da camada "mundo" que pertencem à região).
- `Main.change_region` (com escurecida) / `change_region_now` (carregar save, apagar às 2h, testes). O jogador é o mesmo nó, movido para `Entities` da região.
- `RegionExit` (Area2D): pede a troca pelo `EventBus.region_change_requested`.
- `NpcData` (data/npcs/*.tres): rotina, falas, loja. `Npc` (scripts/npc/npc.gd): segue a rotina a cada 10 min de jogo, anda pelo caminho A*, entra em casa ("!"), escolhe falas (`pick_lines`, sem efeito colateral e testável), amizade e loja. É `persistent` (amizade, conheceu, último dia de conversa).
- `DialogueUI` e `ShopUI` abrem por sinais do `EventBus` (`dialogue_requested`, `shop_requested`) e pausam o mundo. O morador não conhece as telas.
- `Interactable.target_priority`: desempate quando dois alvos estão perto (morador na frente de uma porta ganha).

## Aventura (Fase 7)

- Regiões novas: `SerraLevel` (serra), `MineLevel` (mina) e `RuinasLevel` (ruínas). Montam os objetos por código (`Prop`: sprite + colisão + E) para manter as cenas pequenas.
- `MineLevel.build_floor(n)` refaz o chão com `FarmGround.load_from_text` (autômato celular + BFS: tudo que não se alcança vira rocha, escada de descer no ponto mais longe). Andares não são salvos: mina e ruínas têm `save_as_region`, então o save leva o jogador para a porta da serra.
- `Rock` (picareta) e `Mining` (provedor `item_target`). Pedras quebradas avisam o `Level.invalidate_nav()`.
- `Boss` herda de `Enemy` e adiciona ataque especial, segunda fase e ajudantes; `Projectile` acerta o jogador.
- `Quests` escuta `EventBus.region_entered`, `enemy_killed`, `GameState.flag_set`, mochila e relógio para concluir etapas sozinhas; `Npc.talk()` pergunta `Quests.dialogue_for(id)` antes da conversa normal. `QuestBoard` (mural) e `JournalUI` (diário) só leem o autoload.

## Tempo e clima (Fase 3)

- `Calendar` (classe só com funções): converte o número do dia em mês, dia do mês, ano, dia da semana, período (chuvoso/seco) e safra do pequi.
- `Clock` (autoload): minutos do dia; pausa junto com o jogo. Ordem ao dormir: `GameState.day_advanced` (plantas regadas crescem) → `Clock.start_day` (06:00, sorteia clima, sinal `day_started`: chuva rega, plantas fora de época morrem) → `GameState.day_changed` (interface).
- `WeatherFX` (scripts/weather/weather_fx.gd): só visual. `CanvasModulate` para a luz do dia (cor calculada por `Clock.daylight_color`, função pura testada) e uma camada com chuva (partículas), relâmpago e neblina.
- Testes rodam com `Clock.running = false` e `Clock.forced_weather` fixo, para serem determinísticos.

## Save

Arquivo `user://vale_do_pequi_save.json` (no navegador: IndexedDB).

```
{ "version": 3, "saved_at": "...",
  "game":   GameState.to_data()  → dia, água, atalho, mochila,
  "clock":  Clock.to_data()      → minutos, clima, semente do clima   (desde a v2),
  "player": {x, y, facing, region},           (region desde a v3; game.money também)
  "nodes":  { "Farm/FarmField": {...}, "Farm/Entities/BauDoAvo": {...}, "Farm/Entities/Pequizeiro1": {...} } }
```

- Nós do grupo `persistent` implementam `get_save_data()` / `load_save_data(data)`; a chave é o caminho a partir do nó do grupo `save_root` (a cena principal).
- `SaveManager.migrate()` leva saves antigos até `GameState.DATA_VERSION`; save de versão mais nova ou corrompido é recusado sem mexer no jogo; campos faltando usam o padrão de jogo novo.
- Salva ao dormir e pelo menu de pausa. Carrega automaticamente ao abrir o jogo.

## Camadas de física

| Camada | Nome | Quem está |
|---|---|---|
| 1 | mundo | casas, árvores, cercas, água, bordas do mapa |
| 2 | jogador | Player (máscara = 1) |
| 3 | interagivel | áreas `Interactable` (detectadas pela `InteractionArea` do jogador) |

## Jogador (`scripts/player/player.gd`)

- `CharacterBody2D` em `motion_mode = floating` (top-down, sem "chão").
- Movimento: `Input.get_vector` (já normalizado → diagonal não é mais rápida), aceleração e atrito configuráveis no Inspector.
- 8 direções: `direction_to_index()` converte o vetor em 0..7 (S, SE, E, NE, N, NW, W, SW), que é a linha do spritesheet.
- Colisão só nos pés (10×6 px) para o personagem poder passar "atrás" de árvores e telhados.
- Interação: uma área circular à frente do jogador; o `Interactable` mais próximo vira o alvo; a tecla E chama `interact()`.
- Estados: `IDLE`, `WALK`. Esquiva/ataque entram na Fase 6 com uma máquina de estados própria em `scripts/player/states/`.

## Objetos interativos

- `Interactable` (Area2D, componente): sinal `interacted(actor)`, texto da dica, `enabled`.
- `Inspectable` (StaticBody2D): mostra falas configuradas no Inspector. Usado em poço, placa, casa, cupinzeiro, ipê.
- `Pequizeiro`: frutos aparecem caídos no chão e são "catados" (o pequi não se colhe no galho). Reaparecem depois de um tempo — **provisório**, vira safra por calendário na Fase 3.
- `FenceLine` (@tool): cerca reta definida por comprimento em tiles, uma colisão por trecho.

## Mapa ASCII

`data/maps/fazenda_pequi.txt`, 1 caractere = 1 tile 16×16. Legenda em `farm_ground.gd`:

```
.  grama          ,  grama com flores    "  capim seco/dourado   m  mata (grama escura)
=  terra vermelha #  terra arada         ~  água (sólida)        ^  água com margem (sólida)
```

Para editar: abra o .txt e troque caracteres. Os objetos (árvores, casa...) ficam em `scenes/farm/farm.tscn` e se movem pelo editor.
Limitação conhecida: sem autotile, as bordas entre tipos de chão são retas. Quando o tileset final tiver transições, a pintura passa a usar Terrains do Godot.

## Configuração gráfica (GDD §14.2)

- Base 640×360, stretch `viewport`, aspect `expand`: telas mais largas que 16:9 (celulares 19,5:9, monitores ultrawide) mostram um pouco mais de mapa em vez de faixas pretas.
- Computador: escala inteira (pixel perfeito). Celular: escala fracionária, para ocupar a tela toda (`main.gd › _configure_scaling`).
- Filtro de textura `Nearest`, snap de transformações e vértices ao pixel.
- Janela inicial 1280×720. F11 alterna tela cheia.

## Web e celular

- Export "Web" **sem threads** (`variant/thread_support=false`): roda no GitHub Pages sem precisar dos cabeçalhos COOP/COEP, e funciona no Safari do iPhone.
- PWA ligado: no Android dá para instalar na tela inicial; abre em tela cheia e na horizontal.
- `TouchControls` aparece quando o aparelho tem tela de toque ou quando alguém toca na tela; some quando teclado/controle é usado.
- O analógico virtual (`VirtualJoystick`) **não move o jogador**: ele aperta as mesmas ações do teclado (`move_left`...) com intensidade proporcional. Os botões são `TouchScreenButton` ligados às ações `interact`, `menu` e `toggle_fullscreen`. Resultado: nenhum sistema do jogo precisa saber se a entrada veio de toque, teclado ou controle.
- Celular em pé: aviso "Gire o celular". iPhone não tem API de tela cheia no navegador; lá o botão de tela cheia fica escondido.
- Publicação automática: `.github/workflows/publicar-web.yml` (testes → export → GitHub Pages).

## Testes

> **Regra de exportação:** propriedade `@export` do tipo `PackedXArray` precisa de padrão do mesmo tipo (`PackedStringArray()`), nunca `[]`. Com `[]` o export para Web/Windows descarta os valores do `.tres` sem erro. Um teste varre os scripts e falha se isso aparecer.

`tests/test_runner.tscn` — testes de integração (184 verificações; os da Fase 2 cobrem catálogo, mochila, atalhos, ciclo completo de plantio, regras do solo, regador, rebrota, baú, mochila, save/load e robustez do save, botões de toque). Usam um arquivo de save separado e nunca tocam no save do jogador. Antes: 85 verificações: controles, mapeamento de direções, estrutura da cena, movimento, velocidade na diagonal, as 8 direções do sprite, colisão com casa/água/árvore/cerca/bordas, interação com poço, coleta de pequi, pausa e controles de toque (analógico virtual, botão de interagir, botão de pausa, troca toque ↔ teclado). Rodam também no GitHub Actions antes de cada publicação.

```
godot --headless --path . res://tests/test_runner.tscn     # código de saída 0 = ok
```

## Preparação para o futuro (sem implementar agora)

- **Saves (Fase 2):** `GameState.DATA_VERSION` já existe; o save terá `version` e funções de migração por versão.
- **Multiplayer (expansão):** jogador criado por código em `main.gd` (fácil instanciar N jogadores com IDs); estado global concentrado em `GameState`; entrada lida só dentro do `Player`. Nenhuma rede antes de o single-player estar estável (GDD §14.5).
- **Regiões:** cada região expõe `get_entities_root()`, `get_spawn_position()`, `get_world_rect()`. Vila/mata/rio seguem o mesmo contrato.
