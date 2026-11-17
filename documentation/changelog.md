# Changelog — Vale do Pequi

## 0.3.0 — Fase 2: Fazenda (17/11/2026)

### Adicionado
- Catálogo de itens e culturas em dados (`data/items/*.tres`, `data/crops/*.tres`), carregado pelo autoload `ItemDB`.
- Mochila de 27 espaços com pilhas (máx. 99; ferramentas 1) e barra de atalhos (9 primeiros espaços).
- Ferramentas: enxada (capina) e regador (20 de água; enche no poço ou na lagoa).
- Plantio e colheita: milho (4 dias), feijão (3 dias, rebrota em 2), abóbora (6 dias), mandioca (8 dias). Só cresce nos dias em que foi regado.
- Cursor mostrando a célula onde a ferramenta vai agir.
- Dormir na porta da casa: passa o dia e salva (provisório até o relógio da Fase 3).
- Baú do avô com sementes; tela de transferência baú ↔ mochila.
- Tela da mochila (I): ver descrição e reorganizar itens.
- Save em JSON com versão, migração e tolerância a dados faltando/corrompidos. No navegador fica salvo no próprio navegador (IndexedDB).
- Menu de pausa: Salvar jogo e Novo jogo (pede confirmação com segundo toque).
- Celular: botão "usar" (ferramenta/semente), botão da mochila e toque na barra de atalhos.
- Teclado: C ou clique usa o item; 1–9 e rodinha do mouse trocam o atalho. Controle: X usa, LB/RB trocam.
- 99 testes novos (184 no total).

### Alterado
- Pequizeiros soltam pequi a cada novo dia (antes: a cada 20 s).
- Contador de pequi do HUD substituído pelo dia atual + barra de atalhos.
- Pequi agora é um item da mochila.

### Corrigido
- No celular, tocar em qualquer botão não usa mais a ferramenta junto (clique emulado do toque é ignorado para "usar").

## Documentação — GDD 1.1 (17/11/2026)
- GDD atualizado com a direção oficial revisada: definição oficial, pilares, identidade cultural, nova história (O Silêncio), regras de folclore, eventos e festividades. Nenhum sistema da v1.0 foi removido. Ver `documentation/GDD.md` §23.

## 0.2.0 — Navegador e celular (16/11/2026)

### Adicionado
- Export Web (WebGL 2, sem threads) compatível com GitHub Pages; PWA instalável na horizontal.
- Workflow do GitHub Actions: testa, exporta e publica no Pages a cada push na `main`.
- Controles de toque: analógico virtual flutuante, botão de interagir (acende perto de objetos), pausa e tela cheia.
- Troca automática entre modo toque e teclado/controle; a dica de interação muda de texto conforme o modo.
- Aviso "Gire o celular" na vertical.
- 11 testes novos de toque (85 no total).

### Alterado
- Tela com aspect `expand` (sem faixas pretas em telas largas) e escala fracionária no celular.
- Botão "Sair do jogo" escondido no navegador.

## 0.1.0 — Fase 1: Fundação (16/11/2026)

### Adicionado
- Projeto Godot 4.3 configurado: 640×360 pixel-perfect, escala inteira, filtro nearest, renderizador Compatibility.
- Mapa de controles (teclado + controle): WASD/setas, E, Espaço, clique, I, M, J, Esc, 1–9, F11.
- Jogador com movimento em 8 direções, aceleração/atrito, animação de caminhada por direção.
- Câmera top-down que segue o jogador com suavização e limites do mapa.
- Fazenda do Pequi provisória (60×34 tiles): casa, poço, roça cercada, estrada de terra vermelha, pomar com 7 pequizeiros, ipês-amarelos, cupinzeiros, lagoa e capim-dourado.
- Colisões: casa, árvores, cupinzeiros, poço, cercas, água e bordas do mapa.
- Sistema de interação por componente, com dica no HUD.
- Coleta de pequi caído no chão; contador no HUD.
- Menu de pausa (Esc) com Continuar / Sair.
- 74 testes de integração automatizados.
- Ferramentas: gerador de assets provisórios, gerador do mapa base, captura de tela.

### Provisório (substituir depois)
- Toda a arte (`*_placeholder.png`).
- `GameState` com contagem simples de itens (vira inventário na Fase 2).
- Reaparecimento do pequi por segundos (vira safra por calendário na Fase 3).
