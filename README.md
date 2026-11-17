# Vale do Pequi

Simulação de vida rural + Action RPG no Cerrado goiano. Roda **no navegador**, no **celular** e no **computador**.
Feito em Godot 4.3 (GDScript), exportado para Web (WebGL 2).

## Jogar
**https://carttocci.github.io/vale-do-pequi/**

| Ação | Computador | Celular | Controle |
|---|---|---|---|
| Andar | WASD / setas | analógico na esquerda (encoste o dedo em qualquer lugar) | analógico / direcional |
| Interagir | E | botão verde à direita | A |
| Pausa | Esc | botão ⏸ | Start |
| Tela cheia | F11 | botão ⛶ (Android) | — |

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
Os PNGs provisórios são gerados por `tools/gerar_assets_provisorios.py` (Python + Pillow).
