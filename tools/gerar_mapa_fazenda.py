"""
Gera data/maps/fazenda_pequi.txt — o chão da Fazenda do Pequi em ASCII.
Cada caractere é um tile 16x16. Legenda em scripts/world/farm_ground.gd.

O arquivo gerado pode (e deve) ser editado à mão; este script só serve
para recriar o layout base. Uso: python3 tools/gerar_mapa_fazenda.py
"""
import os
import random

W, H = 60, 34
rng = random.Random(42)
g = [["." for _ in range(W)] for _ in range(H)]


def fill(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < W and 0 <= y < H:
                g[y][x] = ch


# grama com flores espalhadas
for _ in range(140):
    g[rng.randrange(H)][rng.randrange(W)] = ","

# borda de mata (grama escura) irregular
for x in range(W):
    for y in range(rng.randint(1, 2)):
        g[y][x] = "m"
    for y in range(H - rng.randint(1, 2), H):
        g[y][x] = "m"
for y in range(H):
    for x in range(rng.randint(1, 2)):
        g[y][x] = "m"

# capim seco (cerrado aberto) no sudeste
for y in range(22, H - 1):
    for x in range(30, W):
        # borda irregular, miolo contínuo (manchas de capim-dourado)
        if (x - 30) * 0.3 + (y - 22) * 0.7 + rng.uniform(-3, 3) > 4.5:
            g[y][x] = '"'

# roça de terra arada (cercada no layout de objetos)
fill(6, 9, 17, 16, "#")

# estrada de terra vermelha: porta da casa -> sul -> leste (rumo à vila)
fill(28, 7, 29, 20, "=")
fill(28, 19, W - 1, 20, "=")
# trilho até a roça e o poço
fill(19, 12, 27, 12, "=")
fill(22, 7, 27, 7, "=")

# lagoa no sudoeste
fill(4, 24, 13, 30, "~")
fill(14, 26, 15, 29, "~")
fill(4, 24, 13, 24, "^")

path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "maps", "fazenda_pequi.txt")
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join("".join(r) for r in g) + "\n")
print("Mapa gerado:", path)
