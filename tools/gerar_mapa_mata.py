"""
Gera data/maps/mata.txt (Mata dos Ipês + Rio das Araras, 60x34) e a lista de
árvores/arbustos usada pela cena (tools/gerar_cena_mata.py).
Legenda em scripts/world/farm_ground.gd (b = ponte).
"""
import os
import random

W, H = 60, 34
rng = random.Random(11)
g = [["." for _ in range(W)] for _ in range(H)]


def fill(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < W and 0 <= y < H:
                g[y][x] = ch


# mata fechada (grama escura) em manchas
for _ in range(26):
    cx, cy = rng.randrange(W), rng.randrange(2, 21)
    r = rng.randint(2, 4)
    fill(cx - r, cy - r // 2, cx + r, cy + r // 2, "m")
# campo de capim dourado a nordeste
for y in range(3, 20):
    for x in range(34, 58):
        if (x - 34) * 0.4 + rng.uniform(-3, 3) > 1.5:
            g[y][x] = '"'
# borda
for x in range(W):
    g[0][x] = "m"
    g[H - 1][x] = "m"
for y in range(H):
    g[y][W - 1] = "m"
# trilha: chega pelo oeste (da vila), vai até a ponte e segue para o norte (serra)
fill(0, 19, 30, 20, "=")
fill(29, 2, 30, 20, "=")
fill(28, 0, 31, 1, "=")
# Rio das Araras
fill(0, 24, W - 1, 24, "^")
fill(0, 25, W - 1, 28, "~")
# ponte
fill(29, 24, 30, 28, "b")
# sul do rio: trilha da ponte até uma clareira
fill(29, 29, 30, 31, "=")
fill(22, 30, 37, 31, "=")

path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "maps", "mata.txt")
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join("".join(r) for r in g) + "\n")
print("Mapa gerado:", path)
