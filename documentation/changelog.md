# Changelog — Vale do Pequi

## 0.5.0 — Fase 4: Vila (17/11/2026)

### Adicionado
- **Vila de Santa Pequiria** (50×34): praça de pedra com cruzeiro e bancos, igreja, mercearia, ferraria, bar e restaurante, clínica veterinária, casas e lagoa. Ligada à fazenda pela estrada leste.
- Troca de região com escurecida; todas as regiões continuam vivas (plantas crescem com o jogador fora).
- **6 moradores** com rotina pelo relógio (andam pelo mapa desviando de prédios e água, entram em casa à noite, rotina própria de domingo): Helena, Seu Benedito, Toninho, Dona Alzira, Mariana e João Pedro.
- Conversas com apresentação na primeira vez e falas por hora do dia, chuva, período seco e amizade; sotaque do interior e pistas do Silêncio.
- Amizade: +10 na primeira conversa do dia.
- **Dinheiro** (começa com R$ 200) e **Mercearia da Helena**: compra sementes e vende colheitas e pequi. Aberta de segunda a sábado, 07:30–18:00 (só quando ela está no balcão).
- Caixa de conversa (E/toque avança) e tela de loja (comprar 1/×5, vender 1/tudo).
- Save v3 com dinheiro, região atual e amizades; saves da v2 migrados (ganham o dinheiro inicial).
- 60 testes novos (310 no total).

### Corrigido
- Colisões de uma região desligada não interferem na outra (mesmas coordenadas).
- **Versão do navegador perdia dados de listas** (baú do avô vinha vazio e placas/poço sem texto desde a v0.3): arrays exportados com padrão `[]` eram descartados no export. Corrigido e protegido por teste que varre os scripts.

## 0.4.0 — Fase 3: Tempo e clima (17/11/2026)

### Adicionado
- Relógio (autoload `Clock`): dia das 06:00 às 02:00, 10 minutos de jogo a cada 7 s reais (~14 min por dia). Para com o jogo pausado.
- Às 02:00 o jogador apaga, acorda na porta de casa no dia seguinte e o jogo salva.
- Calendário (`Calendar`): meses com nomes reais, 10 dias por mês, dias da semana. O jogo começa em 1º de outubro.
- Períodos do Cerrado: chuvoso (outubro a abril) e seco (maio a setembro).
- Clima sorteado por dia conforme o período: ensolarado, nublado, chuva, tempestade (com relâmpagos), neblina (de manhã) e ventania. Mesmo save = mesmo clima no mesmo dia.
- Chuva rega a roça sozinha.
- Culturas com período: milho e abóbora só no chuvoso; feijão e mandioca o ano todo. Plantas fora de época morrem na virada do período; a dica avisa "(fora de época)".
- Safra do pequi: só cai pequi de outubro a janeiro.
- Luz do dia: amanhecer, entardecer alaranjado, noite azulada, dias de chuva mais escuros.
- HUD com data, hora, clima e período.
- Save v2 com relógio e clima; saves da Fase 2 (v1) são migrados automaticamente.
- 51 testes novos (250 no total).

## 0.3.1 — E contextual (17/11/2026)
- **E faz tudo:** escolhe a ação pelo que está à frente e pelo item na mão, nesta prioridade: colher > encher regador > objeto (porta, baú, poço...) > capinar/regar/plantar. A dica mostra a ação antes ("[E] Regar").
- Segurar E repete ações de ferramenta/colheita enquanto anda (fileiras).
- Celular: um botão só (verde) para tudo; botão laranja removido.
- Tecla C removida; clique e X continuam como "usar só a ferramenta".
- 15 testes novos (199 no total).

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
