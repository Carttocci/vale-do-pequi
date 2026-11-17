"""
Gera data/maps/vila.txt — o chão da Vila de Santa Pequiria (50x34 tiles).
Legenda em scripts/world/farm_ground.gd (p = calçamento de pedra).
Uso: python3 tools/gerar_mapa_vila.py
"""
import os
import random

W, H = 50, 34
rng = random.Random(7)
g = [["." for _ in range(W)] for _ in range(H)]


def fill(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < W and 0 <= y < H:
                g[y][x] = ch


for _ in range(110):
    g[rng.randrange(H)][rng.randrange(W)] = ","
# borda de mata
for x in range(W):
    for y in range(rng.randint(1, 2)):
        g[y][x] = "m"
    for y in range(H - rng.randint(1, 2), H):
        g[y][x] = "m"
for y in range(H):
    for x in range(W - rng.randint(1, 2), W):
        g[y][x] = "m"

# estrada principal oeste-leste (chega da fazenda)
fill(0, 19, W - 1, 20, "=")
# praça de pedra
fill(18, 13, 33, 22, "p")
# ruas
fill(8, 12, 17, 12, "=")      # praça -> clínica
fill(34, 10, 44, 10, "=")     # praça -> casa azul
fill(34, 10, 34, 13, "=")
fill(25, 23, 26, 28, "=")     # praça -> sul
fill(8, 28, 40, 29, "=")      # rua de baixo (bar, casa amarela)
# lagoa a sudoeste
fill(2, 22, 8, 26, "~")
fill(2, 22, 8, 22, "^")

path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "maps", "vila.txt")
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join("".join(r) for r in g) + "\n")
print("Mapa gerado:", path)
