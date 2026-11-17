"""
Gera os mapas fixos da Fase 7 (40x23 cada):
  data/maps/serra.txt   Serra do Cristal (boca da mina a oeste, portal das ruínas a leste)
  data/maps/ruinas.txt  Ruínas do Cerrado (salão dos totens + câmara do fundo)
Legenda em scripts/world/farm_ground.gd (r = rocha sólida, c = caverna, u = ruína).
"""
import os
import random

W, H = 40, 23
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def grid(ch):
    return [[ch for _ in range(W)] for _ in range(H)]


def fill(g, x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < W and 0 <= y < H:
                g[y][x] = ch


def save(g, name):
    path = os.path.join(ROOT, "data", "maps", name)
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join("".join(r) for r in g) + "\n")
    print("Mapa gerado:", path)


# --- Serra do Cristal --------------------------------------------------------
rng = random.Random(7)
g = grid(".")
for _ in range(14):
    cx, cy = rng.randrange(W), rng.randrange(H)
    fill(g, cx - 2, cy - 1, cx + 2, cy + 1, '"')
for _ in range(8):
    cx, cy = rng.randrange(W), rng.randrange(H)
    fill(g, cx - 1, cy, cx + 1, cy, ",")
# paredões: bordas grossas e picos de pedra
fill(g, 0, 0, W - 1, 2, "r")
fill(g, 0, 0, 1, H - 1, "r")
fill(g, W - 2, 0, W - 1, H - 1, "r")
fill(g, 0, H - 1, W - 1, H - 1, "r")
for x0, y0, x1, y1 in [(13, 3, 16, 6), (23, 3, 26, 5), (2, 14, 6, 17), (33, 15, 37, 18), (17, 12, 18, 13)]:
    fill(g, x0, y0, x1, y1, "r")
# trilha: sobe do sul (mata), divide para a mina (oeste) e as ruínas (leste)
fill(g, 19, 9, 20, H - 1, "=")
fill(g, 8, 8, 31, 9, "=")
fill(g, 8, 5, 9, 9, "=")
fill(g, 30, 5, 31, 9, "=")
save(g, "serra.txt")

# --- Ruínas do Cerrado -------------------------------------------------------
g = grid("r")
fill(g, 4, 12, 35, 20, "u")        # salão dos totens
fill(g, 19, 21, 20, H - 1, "u")    # entrada (sul)
fill(g, 8, 3, 31, 9, "u")          # câmara do fundo
fill(g, 19, 10, 20, 11, "u")       # passagem (fechada pelo selo)
for x, y in [(6, 13), (33, 13), (6, 19), (33, 19), (10, 4), (29, 4), (10, 8), (29, 8)]:
    g[y][x] = "r"                   # colunas
save(g, "ruinas.txt")
