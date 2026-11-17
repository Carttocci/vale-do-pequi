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

## Autoloads

| Nome | Arquivo | Papel |
|---|---|---|
| `EventBus` | scripts/core/event_bus.gd | Sinais globais: mensagens, dica de interação, item coletado, pausa |
| `GameState` | scripts/core/game_state.gd | Estado da sessão. **Provisório**: só contagem de itens até o inventário da Fase 2 |

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

`tests/test_runner.tscn` — testes de integração (85 verificações): controles, mapeamento de direções, estrutura da cena, movimento, velocidade na diagonal, as 8 direções do sprite, colisão com casa/água/árvore/cerca/bordas, interação com poço, coleta de pequi, pausa e controles de toque (analógico virtual, botão de interagir, botão de pausa, troca toque ↔ teclado). Rodam também no GitHub Actions antes de cada publicação.

```
godot --headless --path . res://tests/test_runner.tscn     # código de saída 0 = ok
```

## Preparação para o futuro (sem implementar agora)

- **Saves (Fase 2):** `GameState.DATA_VERSION` já existe; o save terá `version` e funções de migração por versão.
- **Multiplayer (expansão):** jogador criado por código em `main.gd` (fácil instanciar N jogadores com IDs); estado global concentrado em `GameState`; entrada lida só dentro do `Player`. Nenhuma rede antes de o single-player estar estável (GDD §14.5).
- **Regiões:** cada região expõe `get_entities_root()`, `get_spawn_position()`, `get_world_rect()`. Vila/mata/rio seguem o mesmo contrato.
