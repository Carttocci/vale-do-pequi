# Vale do Pequi

Simulação de vida rural + Action RPG no Cerrado goiano. Roda **no navegador**, no **celular** e no **computador**.
Feito em Godot 4.3 (GDScript), exportado para Web (WebGL 2).

## Jogar
**https://carttocci.github.io/vale-do-pequi/**

| Ação | Computador | Celular | Controle |
|---|---|---|---|
| Andar | WASD / setas | analógico na esquerda (encoste o dedo em qualquer lugar) | analógico / direcional |
| **Fazer a ação** (capinar, regar, plantar, encher regador, colher, abrir, dormir...) | **E** (segure para repetir andando) | botão verde à direita | A |
| Usar só a ferramenta / atacar | clique (segure = golpe carregado) | — | X |
| Esquivar | Espaço | botão azul | B |
| Trocar atalho | 1–9 / rodinha | tocar na barra de baixo | LB / RB |
| Mochila | I | botão da mochila | Y |
| Diário (missões, caderno, habilidades) | J | botão do caderno | — |
| Atacar (só com arma; sem arma na mão, pega a melhor da barra) | F ou K | botão ⚔ | X |
| Comer | Q | botão de comer | — |
| Zoom da câmera | + e − | botões + e − | — |
| Pausa (opções, salvar, voltar ao menu) | Esc | botão ⏸ | Start |
| Tela cheia | F11 | botão ⛶ (Android) | — |

**Tempo:** o dia vai das 06:00 às 02:00 (~14 min reais). Começa em 1º de outubro, no período chuvoso; chuva rega a roça sozinha. Milho e abóbora só no chuvoso; feijão e mandioca o ano todo. Pequi só cai de outubro a janeiro.

**Vila:** siga a estrada de terra para o leste (direita) da fazenda. Converse com os moradores (E). Na mercearia da Helena (seg–sáb, 07:30–18:00) você compra sementes e vende colheitas e pequi.

**Mata e rio:** da vila, siga a estrada para o leste. Pesque com vara e minhoca (João Pedro, na lagoa da vila), observe os bichos (E) para o caderno de campo e arme armadilhas de javali. Galinhas e vacas: Mariana, na clínica.

**Aventura:** a história começa conversando com o Seu Benedito na vila; a missão atual aparece no canto da tela e no diário (J). Pedidos do povo ficam no mural da praça. Com a picareta do Toninho, abra a trilha no norte da mata até a Serra do Cristal, desça a mina (elevador nos andares 5 e 10) e descubra as Ruínas do Cerrado.

**Começo:** o jogo abre na tela de título (Continuar / Novo jogo / Opções). Música e efeitos têm volume próprio nas Opções.

**Vida no vale:** cozinhe no fogão a lenha (ao lado da casa) e coma com a comida na mão (E). Dê presentes aos moradores (item na mão + E): com 2 corações eles ensinam receitas de família. Na bancada você faz decoração e obras da fazenda. Fique de olho nas festas da praça: Festa do Pequi (5/dez), Folia de Reis (6/jan), Cavalhadas (8/mai) e Festa Junina (9/jun).

**Como jogar:** pegue a enxada (atalho 1) e aperte **E** na roça para capinar; com a semente na mão o E planta, com o regador o E rega (e enche no poço). A dica na tela mostra o que o E vai fazer. Durma na porta de casa para passar o dia. Mais sementes no baú do avô, ao lado da casa. O jogo salva ao dormir e pelo menu de pausa.

No celular o jogo é na horizontal. Dica: no Android, "Adicionar à tela inicial" abre o jogo em tela cheia, como um app.

## Publicação
A cada `push` na `main`, o workflow `.github/workflows/publicar-web.yml` roda os testes, exporta a versão Web e publica no GitHub Pages. Se um teste falhar, nada é publicado.
(Configuração necessária, uma vez: Settings → Pages → Source: **GitHub Actions**.)

## Desenvolver
- Abra o Godot 4.3 (ou mais novo) → Importar → `project.godot` → F5.
- Testes: `godot --headless --path . res://tests/test_runner.tscn` (código 0 = tudo passou).
- Testar a versão Web localmente: Projeto → Exportar → "Web" → Exportar Projeto para `build/web/`, depois
  `python3 -m http.server -d build/web 8000` e abra `http://localhost:8000`.
  (Abrir o `index.html` direto do disco não funciona — o navegador bloqueia.)

Documentação em `documentation/`: arquitetura, mecânicas, changelog e assets provisórios.
A arte do chão, dos personagens e das árvores vem do pacote **Ninja Adventure** (pixel-boy e AAA, CC0), repintado por `tools/aplicar_arte_ninja.py`. Os PNGs provisórios restantes são gerados por `tools/gerar_assets_provisorios.py` (Python + Pillow) e os sons e músicas por `tools/gerar_audio.py` (Python + numpy). Itens: `tools/gerar_itens.py`; peixes: `tools/gerar_peixes.py`.
