# Assets provisórios

Todos gerados por `tools/gerar_assets_provisorios.py` (Python + Pillow). Servem só para destravar o código.
Ao trocar pela arte final, **mantenha nome, tamanho e layout** (ou ajuste o `offset` do Sprite2D na cena).

| Arquivo | Tamanho | Layout / origem |
|---|---|---|
| assets/characters/player_placeholder.png | 128×256 | 4 colunas (quadros de caminhada) × 8 linhas (S, SE, E, NE, N, NW, W, SW), quadros 32×32; pés em y=30 |
| assets/tilesets/farm_tiles_placeholder.png | 128×16 | 8 tiles 16×16 na ordem da legenda de farm_ground.gd |
| assets/environments/casa_principal_placeholder.png | 96×80 | base da parede em y=76 |
| assets/environments/pequizeiro_placeholder.png, ipe_amarelo_placeholder.png | 40×48 | base do tronco em y=45 |
| assets/environments/cupinzeiro_placeholder.png | 20×26 | |
| assets/environments/poco_placeholder.png | 28×32 | |
| assets/environments/placa_placeholder.png | 20×22 | |
| assets/environments/arbusto_placeholder.png | 20×16 | |
| assets/environments/cerca_placeholder.png, cerca_vertical_placeholder.png | 16×16 | |
| assets/items/pequi_placeholder.png | 16×16 | ícone de inventário |
| assets/items/pequi_chao_placeholder.png | 8×8 | fruto caído |
| assets/ui/touch_*_placeholder.png | 64, 28, 44, 26 px | analógico e botões de toque |
| assets/ui/app_icon_*.png | 144, 180, 512 | ícones do app web (PWA) |
| assets/tilesets/soil_placeholder.png | 32×16 | terra capinada seca / molhada |
| assets/crops/<cultura>_<0-3>_placeholder.png | 16×32 | estágios das plantas; base em y=31 |
| assets/items/*_placeholder.png | 16×16 | ícones de ferramentas, sementes e colheitas |
| assets/environments/bau_placeholder.png | 20×18 | baú |
| assets/ui/tile_cursor_placeholder.png | 16×16 | cursor da célula-alvo |
| assets/ui/touch_btn_bag_placeholder.png | 26 | botão de toque da mochila |
| assets/npcs/<morador>_placeholder.png | 128×256 | mesmo layout do jogador (4×8 quadros 32×32) |
| assets/environments/{igreja,mercearia,ferreiro,bar,clinica,casa_azul,casa_amarela}_placeholder.png | 96×80 (igreja 96×112) | prédios da vila; base na mesma posição da casa principal |
| assets/environments/{cruzeiro,banco}_placeholder.png | 24×40 / 24×14 | decoração da praça |
| farm_tiles_placeholder.png coluna 8 | 16×16 | calçamento de pedra (`p` no mapa) |

## Arte nova (tools/gerar_arte_cerrado.py)
Rodar **depois** de `gerar_assets_provisorios.py` e `aplicar_arte_ninja.py` (grava por cima). Respeita `assets/arte_manual.txt`.

| Arquivo | Tamanho | Layout |
|---|---|---|
| assets/tilesets/chao_cerrado.png | 320×176 | linhas = terrenos (água, terra, caverna, arado, grama, seca, mata, pedra, ruína, rocha) + enfeites; colunas 1–15 = máscara dos 4 cantos (TL=1, TR=2, BL=4, BR=8), 15–19 = variações do tile cheio; água: 4 quadros de animação. Usado por `scripts/world/ground_visual.gd` |
| farm_tiles_placeholder.png colunas 13–27 | 16×16 | teto, paredes (cima/baixo: caiada azul, taipa, tijolo, tábua, branca verde) e pisos (assoalho, lajota, ladrilho, cimento queimado) |
| assets/characters/player_placeholder.png, assets/npcs/*.png | 128×256 | 4 quadros × 8 direções reais, pés em y=30 |
| pequizeiro, ipe_amarelo | 48×60 | base do tronco em y=57 (offset -27) |
| móveis (cama_*, fogao_casa, mesa_*, pia, filtro_barro...) | variados | base na última linha |
| data/maps/interior_*.txt | — | planta das casas (letras maiúsculas = parede de cima, minúsculas = parede com barrado, T = teto) |
