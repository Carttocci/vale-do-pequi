"""
Chão do Cerrado com transições suaves (sistema "dual-grid").

Cada tile visual fica deslocado meio tile e olha os 4 cantos (as 4 células do
mapa ASCII que ele cobre). Para cada terreno existe uma linha no atlas com 16
colunas, uma por combinação de cantos (máscara TL=1, TR=2, BL=4, BR=8), mais
variações do tile cheio (máscara 15). As camadas são empilhadas pela ordem de
TERRENOS, então cada borda é desenhada pelo terreno de cima (grama sobre terra,
terra sobre água...).

Saída: assets/tilesets/chao_cerrado.png  (16 px por tile)
"""
import numpy as np
from PIL import Image

T = 16
COLS = 20           # 16 máscaras + 4 variações do tile cheio
FULL_VARIANTS = 5   # máscara 15 + colunas 16..19

# Ordem de baixo para cima. Tem que bater com scripts/world/ground_visual.gd.
TERRENOS = ["agua", "terra", "caverna", "arado", "grama", "seca", "mata", "pedra", "ruina", "rocha"]
LINHA_EXTRA = len(TERRENOS)  # ponte + enfeites (grade normal, sem dual-grid)


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def ruido_periodico(seed, periodo=4, amp=1.0):
    """Ruído suave que se repete a cada 16 px (casa nas bordas dos tiles)."""
    rng = np.random.default_rng(seed)
    g = rng.uniform(-1, 1, (periodo, periodo))
    out = np.zeros((T, T))
    for y in range(T):
        for x in range(T):
            fx = (x + 0.5) / T * periodo
            fy = (y + 0.5) / T * periodo
            x0, y0 = int(fx) % periodo, int(fy) % periodo
            x1, y1 = (x0 + 1) % periodo, (y0 + 1) % periodo
            tx, ty = fx - int(fx), fy - int(fy)
            tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
            a = g[y0, x0] * (1 - tx) + g[y0, x1] * tx
            b = g[y1, x0] * (1 - tx) + g[y1, x1] * tx
            out[y, x] = (a * (1 - ty) + b * ty) * amp
    return out


def campo(mask, ruido):
    """Valor 0..1 por pixel: interpolação bilinear dos 4 cantos + ruído."""
    tl, tr, bl, br = (mask >> 0) & 1, (mask >> 1) & 1, (mask >> 2) & 1, (mask >> 3) & 1
    ys, xs = np.mgrid[0:T, 0:T]
    u = (xs + 0.5) / T
    v = (ys + 0.5) / T
    f = tl * (1 - u) * (1 - v) + tr * u * (1 - v) + bl * (1 - u) * v + br * u * v
    if mask == 15:
        return np.ones((T, T))
    return f + ruido


# --- texturas internas (16x16, se repetem sem emenda) ---------------------------

def tex_base(seed, cores, pesos, salpico=None):
    rng = np.random.default_rng(seed)
    idx = rng.choice(len(cores), size=(T, T), p=pesos)
    img = np.zeros((T, T, 4), dtype=np.uint8)
    for i, c in enumerate(cores):
        img[idx == i] = c
    if salpico:
        for cor, n in salpico:
            for _ in range(n):
                x, y = rng.integers(0, T, 2)
                img[y, x] = cor
    return img


def tex_grama(seed, base, escuro, claro, extra=None):
    rng = np.random.default_rng(seed)
    img = np.zeros((T, T, 4), dtype=np.uint8)
    img[:] = base
    # manchas suaves (cor intermediária, pouco contraste)
    if extra is not None:
        for _ in range(4):  # manchinhas soltas, sem formar grade
            cx, cy = int(rng.integers(0, T)), int(rng.integers(0, T))
            for _ in range(6):
                dx, dy = int(rng.integers(-2, 3)), int(rng.integers(-1, 2))
                img[(cy + dy) % T, (cx + dx) % T] = extra
    # tufinhos em "v"
    for _ in range(5):
        x, y = int(rng.integers(0, T)), int(rng.integers(0, T))
        img[y % T, x % T] = escuro
        img[(y - 1) % T, (x - 1) % T] = escuro
        img[(y - 1) % T, (x + 1) % T] = escuro
        if rng.random() < 0.5:
            img[(y - 2) % T, (x + 1) % T] = claro
    for _ in range(4):
        x, y = int(rng.integers(0, T)), int(rng.integers(0, T))
        img[y, x] = claro
    return img


def tex_terra(seed):
    c = [hexc("b86a3f"), hexc("a95d35"), hexc("c27a4c"), hexc("9a522e")]
    img = tex_base(seed, c, [0.55, 0.2, 0.15, 0.1])
    rng = np.random.default_rng(seed + 1)
    for _ in range(3):  # pedrinhas
        x, y = int(rng.integers(0, T - 1)), int(rng.integers(0, T - 1))
        img[y, x] = hexc("d7a27a")
        img[y + 1, x] = hexc("8a4728")
    return img


def tex_arado(seed):
    img = np.zeros((T, T, 4), dtype=np.uint8)
    rng = np.random.default_rng(seed)
    for y in range(T):
        r = y % 4
        cor = [hexc("8a4a29"), hexc("7a3f22"), hexc("663319"), hexc("7a3f22")][r]
        img[y, :] = cor
    for _ in range(10):
        x, y = int(rng.integers(0, T)), int(rng.integers(0, T))
        if y % 4 == 0:
            img[y, x] = hexc("9b5833")
    return img


def tex_pedra(seed):
    """Calçamento de pedra irregular (pé-de-moleque)."""
    rng = np.random.default_rng(seed)
    img = np.zeros((T, T, 4), dtype=np.uint8)
    img[:] = hexc("6e655a")  # rejunte
    pedras = [(0, 0, 7, 5), (8, 0, 7, 4), (0, 6, 5, 4), (6, 5, 6, 5), (13, 5, 3, 5),
              (0, 11, 8, 5), (9, 11, 7, 5)]
    tons = [hexc("b2a998"), hexc("a39a8a"), hexc("bfb6a5"), hexc("9c9384")]
    for (x, y, w, h) in pedras:
        cor = tons[int(rng.integers(0, len(tons)))]
        img[y:y + h - 1, x:x + w - 1] = cor
        img[y, x:x + w - 1] = hexc("cec6b6")          # luz em cima
        img[y + h - 2, x + 1:x + w - 1] = hexc("8a8173")  # sombra embaixo
    return img


def tex_ruina(seed):
    img = np.zeros((T, T, 4), dtype=np.uint8)
    img[:] = hexc("8f8a7c")
    img[0, :] = hexc("6a6558")
    img[:, 0] = hexc("6a6558")
    img[8, :] = hexc("6a6558")
    img[0:8, 8] = hexc("6a6558")
    img[8:, 4] = hexc("6a6558")
    img[1, 1:8] = hexc("a7a293")
    img[9, 1:16] = hexc("a7a293")
    rng = np.random.default_rng(seed)
    for _ in range(5):
        x, y = int(rng.integers(1, T)), int(rng.integers(1, T))
        img[y, x] = hexc("7a8a5c")  # musguinho
    return img


def tex_caverna(seed):
    c = [hexc("5b5048"), hexc("514740"), hexc("665a50")]
    return tex_base(seed, c, [0.6, 0.25, 0.15], [(hexc("7a6d61"), 4)])


def tex_rocha(seed):
    c = [hexc("8c7f72"), hexc("968a7c"), hexc("7f7367")]
    img = tex_base(seed, c, [0.5, 0.3, 0.2])
    rng = np.random.default_rng(seed + 3)
    for _ in range(3):  # rachaduras
        x, y = int(rng.integers(2, T - 4)), int(rng.integers(2, T - 2))
        for k in range(3):
            img[y + (k % 2), x + k] = hexc("4f453e")
    return img


def tex_agua(frame):
    img = np.zeros((T, T, 4), dtype=np.uint8)
    img[:] = hexc("3d8cc0")
    n = ruido_periodico(99, 4, 1.0)
    img[n > 0.3] = hexc("3582b6")
    img[n < -0.45] = hexc("4698cb")
    # brilhos que andam devagar
    pts = [(2, 3), (10, 6), (5, 11), (13, 13)]
    for i, (x, y) in enumerate(pts):
        xx = (x + frame * (1 if i % 2 else -1)) % T
        if (frame + i) % 4 != 3:
            img[y, xx] = hexc("8fd0f0")
            img[y, (xx + 1) % T] = hexc("6fb8e2")
    return img


TEXTURAS = {
    "terra": tex_terra,
    "caverna": tex_caverna,
    "arado": tex_arado,
    "grama": lambda s: tex_grama(s, hexc("6fa83f"), hexc("5a9233"), hexc("8cc457"), hexc("69a13b")),
    "seca": lambda s: tex_grama(s, hexc("c4a14a"), hexc("aa8638"), hexc("ddc06a"), hexc("b8933f")),
    "mata": lambda s: tex_grama(s, hexc("4b7d30"), hexc("3c6827"), hexc("5f9238"), hexc("426f2a")),
    "pedra": tex_pedra,
    "ruina": tex_ruina,
    "rocha": tex_rocha,
}

# Como cada terreno desenha a própria borda:
#   amp      = quanto a borda "ondula" (ruído)
#   contorno = faixa logo dentro da borda (cor, largura em valor de campo)
#   sombra   = faixa logo fora da borda, pintada por cima do terreno de baixo
BORDAS = {
    "terra":   {"amp": 0.12, "contorno": (hexc("7a3d20"), 0.10), "sombra": (hexc("cdeefa", 210), 0.035), "seed": 11},
    "caverna": {"amp": 0.12, "contorno": (hexc("3f3731"), 0.06), "sombra": None, "seed": 12},
    "arado":   {"amp": 0.05, "contorno": (hexc("57290f"), 0.06), "sombra": None, "seed": 13},
    "grama":   {"amp": 0.10, "recuo": 0.16, "contorno": (hexc("4e8a2d"), 0.06), "sombra": (hexc("3a2210", 80), 0.06), "seed": 14},
    "seca":    {"amp": 0.12, "contorno": (hexc("ad8a3a"), 0.05), "sombra": None, "seed": 15},
    "mata":    {"amp": 0.12, "contorno": (hexc("365d22"), 0.06), "sombra": (hexc("1f3313", 70), 0.05), "seed": 16},
    "pedra":   {"amp": 0.04, "contorno": (hexc("857c6e"), 0.10), "sombra": (hexc("2a2018", 80), 0.05), "seed": 17},
    "ruina":   {"amp": 0.05, "contorno": (hexc("5e5a4e"), 0.08), "sombra": (hexc("1a1814", 80), 0.05), "seed": 18},
    "rocha":   {"amp": 0.10, "contorno": (hexc("3d342e"), 0.07), "sombra": (hexc("140f0c", 110), 0.06), "seed": 19},
}


def janela():
    ys, xs = np.mgrid[0:T, 0:T]
    return np.sin(np.pi * (xs + 0.5) / T) * np.sin(np.pi * (ys + 0.5) / T)


def tile_terreno(nome, mask, variante):
    info = BORDAS[nome]
    textura = TEXTURAS[nome](1000 + variante * 37 + TERRENOS.index(nome) * 101)
    # Ruído igual em todas as bordas dos tiles (para casar com o vizinho) +
    # um ruído próprio de cada máscara no meio do tile (para não repetir).
    ruido = ruido_periodico(info["seed"], 2, info["amp"] * 0.6)
    ruido += janela() * ruido_periodico(info["seed"] * 31 + mask, 4, info["amp"])
    f = campo(mask, ruido)
    out = np.zeros((T, T, 4), dtype=np.uint8)
    limiar = 0.5 + info.get("recuo", 0.0)
    dentro = f >= limiar
    out[dentro] = textura[dentro]
    if info["contorno"] and mask != 15:
        cor, w = info["contorno"]
        faixa = dentro & (f < limiar + w)
        out[faixa] = cor
    if nome == "rocha" and mask != 15:
        # paredão: face mais escura na parte de baixo da rocha
        ys = np.mgrid[0:T, 0:T][0]
        tl, tr, bl, br = mask & 1, (mask >> 1) & 1, (mask >> 2) & 1, (mask >> 3) & 1
        xs = np.mgrid[0:T, 0:T][1]
        # topo claro perto de qualquer borda
        out[dentro & (f < limiar + 0.16)] = hexc("a39586")
        if (tl or tr) and not (bl and br):
            face = dentro & (f < limiar + 0.40) & (ys >= 1)
            listras = np.where((xs + ys // 3) % 5 == 0, 1, 0).astype(bool)
            out[face] = hexc("5e5148")
            out[face & listras] = hexc("4d423a")
            out[face & (f >= limiar + 0.34)] = hexc("b3a596")  # beirada do topo
        out[dentro & (f < limiar + 0.06)] = hexc("362e29")
    if info["sombra"] and mask != 0:
        cor, w = info["sombra"]
        faixa = (~dentro) & (f >= limiar - w)
        out[faixa] = cor
    return out


def tile_agua(frame):
    return tex_agua(frame)


# --- linha extra: ponte e enfeites (grade normal) --------------------------------

def tile_ponte():
    img = np.zeros((T, T, 4), dtype=np.uint8)
    for x in range(T):
        tabua = x // 4
        cor = [hexc("9a6a3c"), hexc("8a5d33"), hexc("a3734a"), hexc("8f6238")][tabua]
        img[:, x] = cor
        if x % 4 == 3:
            img[:, x] = hexc("5e3d20")
    img[0, :] = hexc("5e3d20")
    img[T - 1, :] = hexc("4a2f18")
    for x in (1, 5, 9, 13):
        img[3, x] = hexc("3b2a1a")
        img[12, x] = hexc("3b2a1a")
    return img


def tile_flores(seed):
    rng = np.random.default_rng(seed)
    img = np.zeros((T, T, 4), dtype=np.uint8)
    cores = [hexc("f4f0e0"), hexc("f2c94c"), hexc("e57aa8"), hexc("b48ce0"), hexc("f08a4b")]
    for _ in range(3):
        x, y = int(rng.integers(2, T - 2)), int(rng.integers(2, T - 2))
        c = cores[int(rng.integers(0, len(cores)))]
        img[y, x] = hexc("f9e58a") if c != hexc("f2c94c") else hexc("d1702c")
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            img[y + dy, x + dx] = c
        img[y + 2, x] = hexc("3f7a2a")
    return img


def tile_tufo(seed):
    rng = np.random.default_rng(seed)
    img = np.zeros((T, T, 4), dtype=np.uint8)
    x, y = int(rng.integers(3, T - 4)), int(rng.integers(4, T - 2))
    for dx, h in ((-2, 2), (-1, 3), (0, 4), (1, 3), (2, 2)):
        for k in range(h):
            img[y - k, x + dx] = hexc("4f8a2e") if k < h - 1 else hexc("86c255")
    img[y + 1, x - 2:x + 3] = hexc("3a2a1a", 60)
    return img


def tile_pedrinha(seed):
    rng = np.random.default_rng(seed)
    img = np.zeros((T, T, 4), dtype=np.uint8)
    for _ in range(2):
        x, y = int(rng.integers(2, T - 4)), int(rng.integers(2, T - 3))
        img[y, x:x + 3] = hexc("cbbfae")
        img[y + 1, x:x + 3] = hexc("9b8f7f")
        img[y + 2, x:x + 3] = hexc("2a2018", 70)
    return img


def tile_capim(seed):
    """Capim seco alto (tufo dourado)."""
    rng = np.random.default_rng(seed)
    img = np.zeros((T, T, 4), dtype=np.uint8)
    x, y = int(rng.integers(4, T - 5)), int(rng.integers(6, T - 2))
    for dx, h in ((-3, 3), (-2, 5), (-1, 4), (0, 6), (1, 4), (2, 5), (3, 3)):
        for k in range(h):
            img[y - k, x + dx] = hexc("a7832f") if k < h - 2 else hexc("e3c873")
    return img


# Colunas da linha extra (ground_visual.gd usa os mesmos números).
EXTRA = {"ponte": 0, "flores": (1, 4), "tufo": (5, 3), "pedrinha": (8, 3), "capim": (11, 3)}


def gerar():
    linhas = len(TERRENOS) + 1
    atlas = np.zeros((linhas * T, COLS * T, 4), dtype=np.uint8)
    # água: 4 quadros de animação na linha 0
    for fr in range(4):
        atlas[0:T, fr * T:(fr + 1) * T] = tile_agua(fr)
    for i, nome in enumerate(TERRENOS[1:], start=1):
        for mask in range(1, 16):
            atlas[i * T:(i + 1) * T, mask * T:(mask + 1) * T] = tile_terreno(nome, mask, 0)
        for v in range(1, FULL_VARIANTS):
            col = 15 + v
            atlas[i * T:(i + 1) * T, col * T:(col + 1) * T] = tile_terreno(nome, 15, v)
    r = LINHA_EXTRA * T
    atlas[r:r + T, 0:T] = tile_ponte()
    for k in range(4):
        c = EXTRA["flores"][0] + k
        atlas[r:r + T, c * T:(c + 1) * T] = tile_flores(500 + k)
    for k in range(3):
        c = EXTRA["tufo"][0] + k
        atlas[r:r + T, c * T:(c + 1) * T] = tile_tufo(600 + k)
        c = EXTRA["pedrinha"][0] + k
        atlas[r:r + T, c * T:(c + 1) * T] = tile_pedrinha(700 + k)
        c = EXTRA["capim"][0] + k
        atlas[r:r + T, c * T:(c + 1) * T] = tile_capim(800 + k)
    return Image.fromarray(atlas, "RGBA")


if __name__ == "__main__":
    import os
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    gerar().save(os.path.join(root, "assets", "tilesets", "chao_cerrado.png"))
    print("ok")
