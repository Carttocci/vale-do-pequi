"""
Árvores do Cerrado: pequizeiro, ipê-amarelo, árvore torta do cerrado e arbusto.
Copa = várias bolhas somadas, com luz vindo de cima/esquerda e textura de folha.
Tronco torto, com casca grossa (cortiça), como as árvores do cerrado.
"""
import math
import numpy as np
from PIL import Image

CONTORNO = (34, 30, 22, 255)


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def contorno(arr, cor=CONTORNO):
    h, w = arr.shape[:2]
    a = arr[:, :, 3] > 0
    out = arr.copy()
    for y in range(h):
        for x in range(w):
            if a[y, x]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and a[ny, nx] and arr[ny, nx, 3] == 255:
                    out[y, x] = cor
                    break
    return out


def sombra_chao(arr, cx, cy, rx, ry, alpha=70):
    h, w = arr.shape[:2]
    for y in range(h):
        for x in range(w):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1 and arr[y, x, 3] == 0:
                arr[y, x] = (30, 22, 14, alpha)


def tronco(arr, pontos, larg, cores, seed=0):
    """Tronco/galhos: segmentos grossos com casca listrada."""
    rng = np.random.default_rng(seed)
    h, w = arr.shape[:2]
    base, escuro, claro = cores
    for (x0, y0), (x1, y1), r in pontos:
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(n + 1):
            t = i / n
            cx, cy = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            rr = r * (1 - 0.25 * t)
            for y in range(int(cy - rr - 1), int(cy + rr + 2)):
                for x in range(int(cx - rr - 1), int(cx + rr + 2)):
                    if 0 <= x < w and 0 <= y < h and (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= rr * rr:
                        lado = (x + 0.5 - cx) / max(rr, 0.5)
                        c = claro if lado < -0.35 else (escuro if lado > 0.35 else base)
                        if (y + int(x * 0.5)) % 3 == 0 and lado > -0.6:
                            c = escuro  # sulcos da cortiça
                        arr[y, x] = c


def copa(arr, bolhas, cores, seed=0, frutos=None, flores=None):
    """bolhas: [(cx, cy, r)]. cores: (luz, base, meio, sombra, fundo)."""
    rng = np.random.default_rng(seed)
    h, w = arr.shape[:2]
    luz, base, meio, sombra, fundo = cores
    L = np.array([-0.55, -0.75])
    L /= np.linalg.norm(L)
    gcx = np.mean([b[0] for b in bolhas])
    gcy = np.mean([b[1] for b in bolhas])
    for y in range(h):
        for x in range(w):
            melhor = None
            for (cx, cy, r) in bolhas:
                d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                # bordinha recortada de folhas
                rr = r + 0.8 * math.sin((x * 1.7 + y * 2.3) + cx) * (1 if (x + y) % 2 else 0.5)
                if d <= rr:
                    k = d / r
                    if melhor is None or k < melhor[0]:
                        melhor = (k, cx, cy, r)
            if melhor is None:
                continue
            k, cx, cy, r = melhor
            nx, ny = (x + 0.5 - cx) / r, (y + 0.5 - cy) / r
            # luz da bolha + luz geral da copa (parte de baixo mais escura)
            sl = nx * L[0] + ny * L[1]
            gy = (y + 0.5 - gcy) / 14.0
            v = sl * 0.8 - gy * 0.5 + rng.uniform(-0.18, 0.18)
            if v > 0.55:
                c = luz
            elif v > 0.1:
                c = base
            elif v > -0.35:
                c = meio
            elif v > -0.75:
                c = sombra
            else:
                c = fundo
            arr[y, x] = c
    # tufinhos de folha (marquinhas de luz)
    ys, xs = np.nonzero(arr[:, :, 3] == 255)
    for _ in range(len(xs) // 14):
        i = int(rng.integers(0, len(xs)))
        x, y = xs[i], ys[i]
        if tuple(arr[y, x]) in (base, luz) and y + 1 < h:
            arr[y, x] = luz
            if arr[y + 1, x, 3]:
                arr[y + 1, x] = meio
    if flores:
        for _ in range(flores[1]):
            i = int(rng.integers(0, len(xs)))
            x, y = xs[i], ys[i]
            if y + 1 < h and x + 1 < w:
                arr[y, x] = flores[0][0]
                if arr[y, x + 1, 3]:
                    arr[y, x + 1] = flores[0][1]
    if frutos:
        cor, cor2, n = frutos
        for _ in range(n):
            for _t in range(30):
                i = int(rng.integers(0, len(xs)))
                x, y = xs[i], ys[i]
                if 1 < x < w - 3 and 1 < y < h - 3 and np.all(arr[y:y + 3, x:x + 3, 3] == 255):
                    arr[y:y + 3, x + 1] = cor
                    arr[y + 1, x:x + 3] = cor
                    arr[y + 1, x + 1] = cor2
                    arr[y, x + 1] = cor2
                    arr[y + 2, x + 1] = (60, 70, 30, 255)
                    break


CASCA = (hexc("7a5638"), hexc("553a25"), hexc("9a7350"))
CASCA_CINZA = (hexc("857a6c"), hexc("5e554a"), hexc("a59a8a"))


def pequizeiro():
    w, h = 48, 60
    a = np.zeros((h, w, 4), dtype=np.uint8)
    sombra_chao(a, 24, 57, 15, 3.2)
    tronco(a, [((24, 58), (23, 42), 3.4), ((23, 44), (16, 32), 2.2), ((23, 42), (31, 30), 2.2),
               ((23, 40), (24, 28), 1.8)], 3, CASCA, 1)
    folhas = np.zeros_like(a)
    copa(folhas, [(24, 20, 13), (13, 25, 9), (35, 25, 9), (18, 13, 8), (31, 13, 8), (24, 29, 8)],
         (hexc("9cc25a"), hexc("6e9a3d"), hexc("557f30"), hexc("3f6526"), hexc("2f4c1e")), 3,
         frutos=(hexc("a9c246"), hexc("e3d867"), 7))
    m = folhas[:, :, 3] > 0
    a[m] = folhas[m]
    return Image.fromarray(contorno(a), "RGBA")


def ipe():
    w, h = 48, 60
    a = np.zeros((h, w, 4), dtype=np.uint8)
    sombra_chao(a, 24, 57, 14, 3.0)
    # florzinhas caídas no chão
    rng = np.random.default_rng(4)
    for _ in range(9):
        x, y = int(rng.integers(10, 38)), int(rng.integers(55, 59))
        a[y, x] = hexc("f5d33a")
    tronco(a, [((24, 58), (22, 40), 3.0), ((22, 42), (14, 30), 1.9), ((22, 40), (32, 28), 2.0),
               ((23, 38), (26, 24), 1.5)], 3, CASCA_CINZA, 2)
    folhas = np.zeros_like(a)
    copa(folhas, [(24, 18, 12), (12, 24, 8), (36, 23, 8), (17, 11, 7), (32, 11, 7), (25, 27, 7), (8, 18, 5), (40, 16, 5)],
         (hexc("fff08a"), hexc("f6d23a"), hexc("e8b628"), hexc("c98a1e"), hexc("9a6418")), 5,
         flores=((hexc("fffbd0"), hexc("f08a2a")), 16))
    m = folhas[:, :, 3] > 0
    a[m] = folhas[m]
    return Image.fromarray(contorno(a), "RGBA")


def arvore_cerrado():
    w, h = 40, 48
    a = np.zeros((h, w, 4), dtype=np.uint8)
    sombra_chao(a, 20, 45, 11, 2.6)
    tronco(a, [((20, 46), (18, 34), 2.8), ((18, 36), (11, 24), 1.8), ((18, 35), (27, 26), 1.9),
               ((26, 27), (30, 19), 1.3), ((12, 25), (9, 17), 1.2)], 3, CASCA, 3)
    folhas = np.zeros_like(a)
    copa(folhas, [(10, 15, 7), (29, 16, 8), (20, 11, 7), (19, 21, 5)],
         (hexc("b6c66a"), hexc("8a9f46"), hexc("6e8538"), hexc("55692b"), hexc("3f4f20")), 7)
    m = folhas[:, :, 3] > 0
    a[m] = folhas[m]
    return Image.fromarray(contorno(a), "RGBA")


def arbusto():
    w, h = 20, 16
    a = np.zeros((h, w, 4), dtype=np.uint8)
    sombra_chao(a, 10, 14, 8, 2)
    folhas = np.zeros_like(a)
    copa(folhas, [(10, 8, 6), (5, 10, 4), (15, 10, 4)],
         (hexc("98c25a"), hexc("6e9a3d"), hexc("557f30"), hexc("3f6526"), hexc("2f4c1e")), 9,
         flores=((hexc("d8452f"), hexc("a32f20")), 3))
    m = folhas[:, :, 3] > 0
    a[m] = folhas[m]
    return Image.fromarray(contorno(a), "RGBA")


def gerar(root):
    import os
    env = os.path.join(root, "assets", "environments")
    yield os.path.join(env, "pequizeiro_placeholder.png"), pequizeiro()
    yield os.path.join(env, "ipe_amarelo_placeholder.png"), ipe()
    yield os.path.join(env, "arvore_cerrado_placeholder.png"), arvore_cerrado()
    yield os.path.join(env, "arbusto_placeholder.png"), arbusto()
