"""
Tiles de dentro das casas (colunas 13..27 de farm_tiles_placeholder.png):
teto, paredes (cima/baixo de cada tipo) e pisos. Ordem = FarmGround.LEGEND.
Também desenha os móveis (camas, fogões, mesas...) em assets/environments/.
"""
import os
import numpy as np
from PIL import Image, ImageDraw

T = 16


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def ruido(img, seed, cores, n):
    rng = np.random.default_rng(seed)
    px = img.load()
    for _ in range(n):
        x, y = int(rng.integers(0, img.width)), int(rng.integers(0, img.height))
        px[x, y] = cores[int(rng.integers(0, len(cores)))]


def teto():
    im = Image.new("RGBA", (T, T), hexc("3b2b22"))
    d = ImageDraw.Draw(im)
    for y in (3, 8, 13):
        d.line((0, y, 15, y), fill=hexc("33251d"))
    d.line((0, 15, 15, 15), fill=hexc("5c4434"))
    d.line((0, 14, 15, 14), fill=hexc("4a372b"))
    return im


def parede(base, sombra_topo, rodape, faixa=None, tipo="liso", seed=0):
    """cima=True -> parte de cima da parede; o barrado vai na de baixo."""
    cima = Image.new("RGBA", (T, T), base)
    baixo = Image.new("RGBA", (T, T), base)
    if tipo == "liso":
        for im, s in ((cima, seed), (baixo, seed + 1)):
            ruido(im, s, [tuple(max(0, c - 10) for c in base[:3]) + (255,)], 10)
    elif tipo == "tijolo":
        for im in (cima, baixo):
            d = ImageDraw.Draw(im)
            for row in range(4):
                y = row * 4
                d.line((0, y + 3, 15, y + 3), fill=hexc("7e3a22"))
                off = 0 if row % 2 == 0 else 4
                for x in range(off, 16, 8):
                    d.line((x, y, x, y + 2), fill=hexc("7e3a22"))
                d.line((0, y, 15, y), fill=hexc("c47552"))
            ruido(im, seed, [hexc("a45232"), hexc("c06a45")], 12)
    elif tipo == "tabua":
        for im in (cima, baixo):
            d = ImageDraw.Draw(im)
            for x in range(0, 16, 4):
                d.line((x, 0, x, 15), fill=hexc("6b4527"))
                d.line((x + 1, 0, x + 1, 15), fill=hexc("a8774a"))
            ruido(im, seed, [hexc("7f5534"), hexc("8d6038")], 10)
            for y in (5, 11):
                im.putpixel((2, y), hexc("4a2f1a"))
                im.putpixel((10, y + 2), hexc("4a2f1a"))
    d = ImageDraw.Draw(cima)
    d.rectangle((0, 0, 15, 1), fill=sombra_topo)  # sombra do teto
    db = ImageDraw.Draw(baixo)
    if faixa:
        cor, borda = faixa
        db.rectangle((0, 7, 15, 15), fill=cor)
        db.line((0, 7, 15, 7), fill=borda)
        ruido(baixo, seed + 5, [tuple(max(0, c - 12) for c in cor[:3]) + (255,)], 6)
    db.rectangle((0, 14, 15, 15), fill=rodape)
    db.line((0, 13, 15, 13), fill=tuple(min(255, c + 25) for c in rodape[:3]) + (255,))
    return cima, baixo


def assoalho():
    im = Image.new("RGBA", (T, T), hexc("b07a48"))
    d = ImageDraw.Draw(im)
    tons = [hexc("b07a48"), hexc("a46f40"), hexc("ba8452"), hexc("9c693d")]
    for r in range(4):
        y = r * 4
        d.rectangle((0, y, 15, y + 3), fill=tons[r])
        d.line((0, y + 3, 15, y + 3), fill=hexc("6f4425"))
        x = (r * 6 + 3) % 16
        d.line((x, y, x, y + 2), fill=hexc("6f4425"))
    ruido(im, 3, [hexc("8e5d35")], 8)
    return im


def lajota():
    im = Image.new("RGBA", (T, T), hexc("7a3a25"))
    d = ImageDraw.Draw(im)
    for (x, y, c) in ((0, 0, "b95b3b"), (8, 0, "ac5236"), (0, 8, "a94f34"), (8, 8, "bd6040")):
        d.rectangle((x, y, x + 6, y + 6), fill=hexc(c))
        d.line((x, y, x + 6, y), fill=hexc("cf7854"))
    ruido(im, 5, [hexc("9e4a30")], 6)
    return im


def ladrilho():
    im = Image.new("RGBA", (T, T), hexc("ece0c6"))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 15, 15), outline=hexc("b9a98c"))
    # flor de 4 pétalas no meio e quartos nos cantos (forma desenho contínuo)
    vermelho, verde = hexc("c9735e"), hexc("7fa58a")
    d.polygon([(8, 5), (9, 8), (8, 11), (7, 8)], fill=vermelho)
    d.polygon([(5, 8), (8, 7), (11, 8), (8, 9)], fill=vermelho)
    d.point((8, 8), fill=hexc("e8c15a"))
    for (x, y) in ((1, 1), (14, 1), (1, 14), (14, 14)):
        d.point((x, y), fill=verde)
    return im


def cimento():
    im = Image.new("RGBA", (T, T), hexc("9b3a2b"))
    ruido(im, 9, [hexc("a8463a"), hexc("8e3326")], 20)
    d = ImageDraw.Draw(im)
    d.line((0, 15, 15, 15), fill=hexc("7f2c20"))
    d.line((15, 0, 15, 15), fill=hexc("7f2c20"))
    d.line((3, 4, 6, 4), fill=hexc("c46a5a"))
    return im


def colunas_interior():
    tiles = [teto()]
    tiles += parede(hexc("eee7d6"), hexc("cfc6b2"), hexc("2c4f7c"), (hexc("3f72ab"), hexc("2c5788")), seed=1)
    tiles += parede(hexc("d8b26a"), hexc("b8924f"), hexc("6b3a1f"), (hexc("a75a33"), hexc("85432a")), seed=2)
    tiles += parede(hexc("b5603b"), hexc("8f4a2d"), hexc("4d2b17"), None, "tijolo", seed=3)
    tiles += parede(hexc("94653d"), hexc("6b4527"), hexc("4a2f1a"), None, "tabua", seed=4)
    tiles += parede(hexc("f3f1ea"), hexc("d5d3cb"), hexc("2f5c3b"), (hexc("5a9566"), hexc("3f7550")), seed=6)
    tiles += [assoalho(), lajota(), ladrilho(), cimento(), Image.new("RGBA", (T, T))]
    return tiles


def aplicar(root):
    p = os.path.join(root, "assets", "tilesets", "farm_tiles_placeholder.png")
    base = Image.open(p).convert("RGBA").crop((0, 0, 13 * T, T))
    tiles = colunas_interior()
    out = Image.new("RGBA", ((13 + len(tiles)) * T, T))
    out.paste(base, (0, 0))
    for i, t in enumerate(tiles):
        out.paste(t, ((13 + i) * T, 0))
    out.save(p)
    return out
