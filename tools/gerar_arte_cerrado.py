"""
Arte nova do Vale do Pequi (pixel art 2D chapada), toda gerada por código:
  - chão com transições suaves (assets/tilesets/chao_cerrado.png) — tools/arte/chao.py
  - pisos e paredes de dentro das casas (colunas 13+ de farm_tiles_placeholder.png)
  - jogador e moradores, 8 direções x 4 quadros — tools/arte/personagens.py
  - pequizeiro, ipê, árvore do cerrado, arbusto — tools/arte/arvores.py
  - casas e prédios, cada um diferente — tools/arte/casas.py
  - móveis dos interiores — tools/arte/moveis.py

Uso: python3 tools/gerar_arte_cerrado.py   (rodar DEPOIS dos outros geradores)
Arquivos listados em assets/arte_manual.txt não são sobrescritos.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools", "arte"))

import arvores  # noqa: E402
import casas  # noqa: E402
import chao  # noqa: E402
import interior  # noqa: E402
import moveis  # noqa: E402
import personagens  # noqa: E402


def manual():
    f = os.path.join(ROOT, "assets", "arte_manual.txt")
    if not os.path.exists(f):
        return set()
    return {l.strip() for l in open(f, encoding="utf-8") if l.strip() and not l.startswith("#")}


def salvar(caminho, img, pular):
    rel = os.path.relpath(caminho, ROOT).replace("\\", "/")
    if rel in pular:
        print("  (feito à mão, mantido)", rel)
        return
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    img.save(caminho)
    print("  ", rel)


def main():
    pular = manual()
    salvar(os.path.join(ROOT, "assets", "tilesets", "chao_cerrado.png"), chao.gerar(), pular)
    if "assets/tilesets/farm_tiles_placeholder.png" not in pular:
        interior.aplicar(ROOT)
    for mod in (personagens, arvores, casas, moveis):
        for caminho, img in mod.gerar(ROOT):
            salvar(caminho, img, pular)


if __name__ == "__main__":
    main()
