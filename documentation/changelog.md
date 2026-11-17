# Changelog — Vale do Pequi

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
