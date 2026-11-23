"""
Casas e prédios do Vale do Pequi em pixel art 2D chapada, cada um com cara própria:
casa da fazenda (taipa com alpendre), casa azul (colonial caiada), casa amarela,
mercearia, ferreiro, boteco, clínica veterinária e igreja.

Tamanho 96x80 (igreja 96x112). Porta sempre no meio, embaixo (x=48);
a base da parede fica em y=76 (igreja: y=108), como esperam as cenas.
"""
import numpy as np
from PIL import Image, ImageDraw

OL = (43, 29, 24, 255)


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def esc(c, k=0.22):
    return tuple(int(v * (1 - k)) for v in c[:3]) + (255,)


def cla(c, k=0.2):
    return tuple(int(v + (255 - v) * k) for v in c[:3]) + (255,)


# --- letrinhas 3x5 para as placas --------------------------------------------------
FONTE = {
    "A": "010101111101101", "B": "110101110101110", "C": "011100100100011", "D": "110101101101110",
    "E": "111100110100111", "F": "111100110100100", "G": "011100101101011", "H": "101101111101101",
    "I": "111010010010111", "L": "100100100100111", "M": "101111111101101", "N": "110101101101101",
    "O": "010101101101010", "P": "110101110100100", "R": "110101110101101", "S": "011100010001110",
    "T": "111010010010010", "U": "101101101101111", "V": "101101101101010", "Z": "111001010100111",
    " ": "000000000000000", "Á": "010111101111101",
}


def texto(d, x, y, s, cor):
    for ch in s:
        g = FONTE.get(ch, FONTE[" "])
        for i, bit in enumerate(g):
            if bit == "1":
                d.point((x + i % 3, y + i // 3), fill=cor)
        x += 4


def contorno(im):
    a = np.array(im)
    alpha = a[:, :, 3] > 0
    out = a.copy()
    h, w = alpha.shape
    for y in range(h):
        for x in range(w):
            if alpha[y, x]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and alpha[ny, nx] and a[ny, nx, 3] == 255:
                    out[y, x] = OL
                    break
    return Image.fromarray(out, "RGBA")


# --- peças ---------------------------------------------------------------------

def telhado(d, x0, x1, y0, y1, cor, inclinacao=6):
    """Telhado colonial de telha capa-canal visto de frente (trapézio)."""
    claro, escuro, fundo = cla(cor, 0.15), esc(cor, 0.25), esc(cor, 0.45)
    d.polygon([(x0 + inclinacao, y0), (x1 - inclinacao, y0), (x1, y1), (x0, y1)], fill=cor, outline=OL)
    for y in range(y0 + 1, y1):
        t = (y - y0) / max(1, y1 - y0)
        xa = int(x0 + inclinacao * (1 - t)) + 1
        xb = int(x1 - inclinacao * (1 - t)) - 1
        for x in range(xa, xb + 1):
            col = (x - x0) % 5
            linha = (y - y0) % 5
            if col == 0:
                c = fundo
            elif col == 1:
                c = claro
            elif col == 4:
                c = escuro
            else:
                c = cor
            if linha == 4:
                c = escuro if col != 1 else cor
            d.point((x, y), fill=c)
    d.line((x0 + inclinacao, y0, x1 - inclinacao, y0), fill=esc(cor, 0.35))   # cumeeira
    d.line((x0, y1, x1, y1), fill=OL)
    d.line((x0 + 1, y1 - 1, x1 - 1, y1 - 1), fill=fundo)


def parede(d, x0, y0, x1, y1, cor, barrado=None, alt_barrado=7, textura=None, seed=0):
    d.rectangle((x0, y0, x1, y1), fill=cor, outline=OL)
    d.line((x0 + 1, y0 + 1, x1 - 1, y0 + 1), fill=esc(cor, 0.3))   # sombra do beiral
    d.line((x0 + 1, y0 + 2, x1 - 1, y0 + 2), fill=esc(cor, 0.15))
    rng = np.random.default_rng(seed)
    if textura == "taipa":   # reboco caído mostrando adobe
        for (bx, by) in ((x0 + 6, y0 + 8), (x1 - 16, y0 + 20), (x0 + 18, y1 - 14)):
            for r in range(2):
                for k in range(3):
                    xx = bx + k * 4 + (2 if r % 2 else 0)
                    d.rectangle((xx, by + r * 3, xx + 2, by + r * 3 + 1), fill=hexc("a8603a"))
            d.line((bx - 1, by - 1, bx + 12, by - 1), fill=esc(cor, 0.2))
    elif textura == "tijolo":
        for y in range(y0 + 3, y1, 3):
            off = 0 if (y // 3) % 2 else 3
            d.line((x0 + 1, y, x1 - 1, y), fill=esc(cor, 0.25))
            for x in range(x0 + 1 + off, x1, 6):
                d.point((x, y + 1), fill=esc(cor, 0.25))
                d.point((x, y + 2), fill=esc(cor, 0.25))
    else:
        for _ in range((x1 - x0) * (y1 - y0) // 40):
            x, y = int(rng.integers(x0 + 1, x1)), int(rng.integers(y0 + 3, y1))
            d.point((x, y), fill=esc(cor, 0.07))
    if barrado:
        d.rectangle((x0 + 1, y1 - alt_barrado, x1 - 1, y1 - 1), fill=barrado)
        d.line((x0 + 1, y1 - alt_barrado, x1 - 1, y1 - alt_barrado), fill=esc(barrado, 0.25))


def porta(d, cx, y1, larg, alt, cor, moldura=None, dupla=False, aberta=False):
    x0, x1 = cx - larg // 2, cx + larg // 2 - 1
    y0 = y1 - alt
    if moldura:
        d.rectangle((x0 - 2, y0 - 2, x1 + 2, y1), fill=moldura, outline=OL)
    if aberta:
        d.rectangle((x0, y0, x1, y1), fill=hexc("3a2a22"), outline=OL)
        return
    d.rectangle((x0, y0, x1, y1), fill=cor, outline=OL)
    for x in range(x0 + 3, x1, 3):
        d.line((x, y0 + 1, x, y1 - 1), fill=esc(cor, 0.2))
    d.line((x0 + 1, y0 + 1, x1 - 1, y0 + 1), fill=cla(cor, 0.2))
    if dupla:
        d.line((cx - 1, y0, cx - 1, y1), fill=OL)
        d.point((cx - 3, y0 + alt // 2), fill=hexc("e8c15a"))
        d.point((cx + 1, y0 + alt // 2), fill=hexc("e8c15a"))
    else:
        d.point((x1 - 2, y0 + alt // 2), fill=hexc("e8c15a"))
    # soleira
    d.rectangle((x0 - 2, y1, x1 + 2, y1 + 1), fill=hexc("9d958a"), outline=OL)


def janela(d, x, y, w, h, quadro, vidro=hexc("2f3a45"), venezianas=None, flores=None):
    d.rectangle((x - 1, y - 1, x + w, y + h), fill=quadro, outline=OL)
    d.rectangle((x + 1, y + 1, x + w - 2, y + h - 2), fill=vidro)
    d.line((x + w // 2 - 1, y + 1, x + w // 2 - 1, y + h - 2), fill=quadro)
    d.line((x + 1, y + h // 2, x + w - 2, y + h // 2), fill=quadro)
    d.point((x + 2, y + 2), fill=cla(vidro, 0.35))
    d.point((x + w // 2 + 1, y + 2), fill=cla(vidro, 0.35))
    if venezianas:   # folhas abertas dos lados
        for vx in (x - 5, x + w + 1):
            d.rectangle((vx, y - 1, vx + 3, y + h), fill=venezianas, outline=OL)
            for yy in range(y + 1, y + h, 2):
                d.line((vx + 1, yy, vx + 2, yy), fill=esc(venezianas, 0.25))
    # parapeito
    d.rectangle((x - 2, y + h, x + w + 1, y + h + 1), fill=hexc("d8d0c0"), outline=OL)
    if flores:
        for i, fx in enumerate(range(x, x + w, 3)):
            d.point((fx, y + h - 1), fill=hexc("4f8a2e"))
            d.point((fx + 1, y + h - 2), fill=flores[i % len(flores)])


def vaso(d, x, y, flor=hexc("d8452f")):
    d.polygon([(x, y), (x + 5, y), (x + 4, y + 5), (x + 1, y + 5)], fill=hexc("b0552f"), outline=OL)
    d.ellipse((x - 1, y - 6, x + 6, y), fill=hexc("4f8a2e"), outline=OL)
    d.point((x + 1, y - 4), fill=flor)
    d.point((x + 4, y - 3), fill=flor)
    d.point((x + 2, y - 2), fill=cla(flor, 0.3))


def poste_madeira(d, x, y0, y1, cor=hexc("7a5030")):
    d.rectangle((x, y0, x + 2, y1), fill=cor, outline=OL)
    d.line((x + 1, y0 + 1, x + 1, y1 - 1), fill=cla(cor, 0.2))


def placa(d, x0, y0, x1, y1, fundo, cor_texto, txt):
    d.rectangle((x0, y0, x1, y1), fill=fundo, outline=OL)
    d.line((x0 + 1, y1 - 1, x1 - 1, y1 - 1), fill=esc(fundo, 0.25))
    w = len(txt) * 4 - 1
    texto(d, (x0 + x1) // 2 - w // 2 + 1, (y0 + y1) // 2 - 2, txt, cor_texto)


def sombra_base(d, x0, x1, y):
    d.rectangle((x0, y + 1, x1, y + 3), fill=(30, 20, 14, 70))


# --- prédios -------------------------------------------------------------------

def casa_principal():
    im = Image.new("RGBA", (96, 80))
    d = ImageDraw.Draw(im)
    sombra_base(d, 4, 91, 76)
    # chaminé do fogão a lenha
    d.rectangle((70, 2, 77, 18), fill=hexc("a9603b"), outline=OL)
    d.rectangle((69, 1, 78, 3), fill=hexc("7d4529"), outline=OL)
    parede(d, 8, 38, 87, 76, hexc("d9a96a"), barrado=hexc("8c5532"), textura="taipa", seed=1)
    telhado(d, 2, 93, 6, 38, hexc("b5532f"), 10)
    # alpendre (varanda): teto mais baixo e esteios
    d.rectangle((4, 38, 91, 41), fill=hexc("6e4527"), outline=OL)
    for x in (6, 30, 63, 87):
        poste_madeira(d, x, 41, 76)
    porta(d, 48, 76, 14, 22, hexc("8a5a34"), moldura=hexc("5d8a4a"))
    janela(d, 15, 50, 12, 11, hexc("5d8a4a"), venezianas=hexc("5d8a4a"))
    janela(d, 70, 50, 12, 11, hexc("5d8a4a"), venezianas=hexc("5d8a4a"))
    # banco de madeira, rede e moringa no alpendre
    d.rectangle((14, 69, 27, 71), fill=hexc("8a5a34"), outline=OL)
    d.line((15, 72, 15, 75), fill=OL)
    d.line((26, 72, 26, 75), fill=OL)
    d.arc((64, 56, 86, 70), 20, 160, fill=hexc("d84a3a"), width=2)
    d.ellipse((79, 70, 84, 76), fill=hexc("b0552f"), outline=OL)
    vaso(d, 33, 71)
    return contorno(im)


def casa_azul():
    im = Image.new("RGBA", (96, 80))
    d = ImageDraw.Draw(im)
    sombra_base(d, 6, 89, 76)
    parede(d, 8, 34, 87, 76, hexc("f1ece0"), barrado=hexc("3f72ab"), alt_barrado=9, seed=2)
    # cunhais (cantos) azuis, típicos das casas coloniais de Goiás
    d.rectangle((9, 36, 11, 75), fill=hexc("3f72ab"))
    d.rectangle((84, 36, 86, 75), fill=hexc("3f72ab"))
    telhado(d, 4, 91, 8, 34, hexc("a84a2c"), 9)
    d.rectangle((6, 34, 89, 36), fill=hexc("f1ece0"), outline=OL)   # beiral caiado
    porta(d, 48, 76, 14, 24, hexc("3f72ab"), moldura=hexc("d9d2c2"))
    for x in (18, 66):
        janela(d, x, 46, 12, 14, hexc("3f72ab"), vidro=hexc("2b3c52"))
        d.rectangle((x - 2, 44, x + 13, 45), fill=hexc("d9d2c2"), outline=OL)  # verga
    vaso(d, 30, 70, hexc("f2c94c"))
    vaso(d, 61, 70, hexc("e57aa8"))
    return contorno(im)


def casa_amarela():
    im = Image.new("RGBA", (96, 80))
    d = ImageDraw.Draw(im)
    sombra_base(d, 6, 89, 76)
    parede(d, 10, 36, 85, 76, hexc("ecc657"), barrado=hexc("b8503a"), alt_barrado=6, seed=3)
    telhado(d, 5, 90, 4, 36, hexc("c0613a"), 14)
    # janelinha de sótão no telhado
    d.rectangle((42, 12, 53, 22), fill=hexc("ecc657"), outline=OL)
    d.polygon([(40, 13), (47, 7), (55, 13)], fill=hexc("a84a2c"), outline=OL)
    d.rectangle((45, 15, 50, 20), fill=hexc("2f3a45"), outline=OL)
    porta(d, 48, 76, 13, 22, hexc("b8503a"), moldura=hexc("f6efe0"))
    janela(d, 17, 48, 13, 12, hexc("b8503a"), venezianas=hexc("b8503a"), flores=[hexc("e57aa8"), hexc("f4f0e0")])
    janela(d, 66, 48, 13, 12, hexc("b8503a"), venezianas=hexc("b8503a"), flores=[hexc("f2c94c"), hexc("d8452f")])
    # varal com pano de prato e banquinho
    d.line((86, 50, 93, 50), fill=OL)
    d.rectangle((88, 51, 91, 56), fill=hexc("f4f0e0"), outline=OL)
    vaso(d, 30, 70, hexc("e57aa8"))
    vaso(d, 61, 70)
    return contorno(im)


def mercearia():
    im = Image.new("RGBA", (96, 80))
    d = ImageDraw.Draw(im)
    sombra_base(d, 4, 91, 76)
    telhado(d, 6, 89, 14, 30, hexc("a84a2c"), 6)
    parede(d, 6, 30, 89, 76, hexc("8fc3b0"), barrado=hexc("4f7f6e"), alt_barrado=8, seed=4)
    # platibanda (fachada reta) com letreiro
    d.rectangle((4, 8, 91, 30), fill=hexc("8fc3b0"), outline=OL)
    d.line((5, 28, 90, 28), fill=hexc("6fa392"))
    placa(d, 14, 12, 81, 22, hexc("f4ecd5"), hexc("b23a2e"), "MERCEARIA")
    # toldo listrado
    for i, x in enumerate(range(6, 90, 6)):
        d.rectangle((x, 34, x + 5, 40), fill=hexc("d84a3a") if i % 2 == 0 else hexc("f4ecd5"))
    d.rectangle((6, 34, 89, 40), outline=OL)
    for x in range(6, 90, 6):
        d.pieslice((x, 37, x + 5, 43), 0, 180, fill=hexc("d84a3a") if (x // 6) % 2 == 1 else hexc("f4ecd5"), outline=OL)
    porta(d, 48, 76, 20, 24, hexc("6b4a2b"), moldura=hexc("4f7f6e"), dupla=True)
    janela(d, 14, 48, 16, 14, hexc("4f7f6e"), vidro=hexc("3b4a44"))
    janela(d, 66, 48, 16, 14, hexc("4f7f6e"), vidro=hexc("3b4a44"))
    # mercadoria na vitrine e sacos na frente
    for k, c in enumerate((hexc("f2c94c"), hexc("d8452f"), hexc("6fa83f"))):
        d.rectangle((16 + k * 5, 56, 19 + k * 5, 60), fill=c)
        d.rectangle((68 + k * 5, 56, 71 + k * 5, 60), fill=c)
    for x in (8, 76):
        d.rounded_rectangle((x, 66, x + 10, 76), 3, fill=hexc("d9c59a"), outline=OL)
        d.line((x + 2, 68, x + 8, 68), fill=hexc("a8925f"))
        d.ellipse((x + 3, 64, x + 7, 67), fill=hexc("f2c94c"), outline=OL)
    return contorno(im)


def ferreiro():
    im = Image.new("RGBA", (96, 80))
    d = ImageDraw.Draw(im)
    sombra_base(d, 4, 91, 76)
    # chaminé de tijolo com fumaça
    d.rectangle((14, 0, 23, 20), fill=hexc("9a4f33"), outline=OL)
    for y in range(2, 20, 3):
        d.line((15, y, 22, y), fill=hexc("7a3a22"))
    parede(d, 6, 34, 89, 76, hexc("b5603b"), textura="tijolo", seed=5)
    telhado(d, 2, 93, 12, 34, hexc("7f8a8c"), 4)   # telha de zinco cinza
    for x in range(4, 92, 4):
        d.line((x, 14, x, 32), fill=hexc("646e70"))
    # portão largo aberto: forja acesa lá dentro
    d.rectangle((30, 46, 65, 76), fill=hexc("2b1f1a"), outline=OL)
    d.rectangle((34, 62, 46, 74), fill=hexc("6e5a50"), outline=OL)       # forja
    d.rectangle((36, 64, 44, 67), fill=hexc("f08a2a"))
    d.rectangle((38, 65, 42, 66), fill=hexc("ffd56a"))
    d.line((32, 50, 63, 50), fill=hexc("4a372b"))
    for i, x in enumerate(range(50, 64, 4)):   # ferramentas penduradas
        d.line((x, 51, x, 57 + i % 2), fill=hexc("9aa3a6"))
    # folhas do portão abertas
    d.rectangle((24, 46, 29, 76), fill=hexc("7a5030"), outline=OL)
    d.rectangle((66, 46, 71, 76), fill=hexc("7a5030"), outline=OL)
    # bigorna e barril na frente
    d.polygon([(76, 68), (88, 68), (86, 71), (78, 71)], fill=hexc("4a4f52"), outline=OL)
    d.rectangle((80, 71, 84, 76), fill=hexc("3b3f42"), outline=OL)
    d.rounded_rectangle((8, 64, 18, 76), 2, fill=hexc("8a5a34"), outline=OL)
    d.line((8, 67, 18, 67), fill=hexc("4a4f52"))
    d.line((8, 73, 18, 73), fill=hexc("4a4f52"))
    placa(d, 70, 38, 91, 45, hexc("3b2a20"), hexc("f2c94c"), "FERRO")
    return contorno(im)


def bar():
    im = Image.new("RGBA", (96, 80))
    d = ImageDraw.Draw(im)
    sombra_base(d, 4, 91, 76)
    parede(d, 8, 32, 87, 76, hexc("6fb39a"), barrado=hexc("2e6b5a"), alt_barrado=10, seed=6)
    telhado(d, 4, 91, 10, 32, hexc("b5532f"), 8)
    placa(d, 36, 34, 59, 42, hexc("f2c94c"), hexc("2b1d18"), "BAR")
    # porta de aço de enrolar meio aberta
    d.rectangle((34, 46, 61, 76), fill=hexc("2b1f1a"), outline=OL)
    d.rectangle((34, 46, 61, 56), fill=hexc("9aa3a6"), outline=OL)
    for y in range(48, 56, 2):
        d.line((35, y, 60, y), fill=hexc("7d8689"))
    # balcão lá dentro e garrafas
    d.rectangle((36, 66, 59, 70), fill=hexc("8a5a34"), outline=OL)
    for x, c in zip(range(38, 58, 4), (hexc("6fa83f"), hexc("c47a2c"), hexc("f4f0e0"), hexc("6fa83f"), hexc("c47a2c"))):
        d.rectangle((x, 59, x + 1, 64), fill=c)
    janela(d, 13, 46, 12, 12, hexc("2e6b5a"))
    janela(d, 71, 46, 12, 12, hexc("2e6b5a"))
    # mesinha com cadeiras de lata e engradado
    d.rectangle((10, 66, 24, 68), fill=hexc("d84a3a"), outline=OL)
    d.line((17, 69, 17, 76), fill=OL)
    d.rectangle((70, 68, 82, 76), fill=hexc("e2a83a"), outline=OL)
    for x in range(72, 82, 3):
        d.rectangle((x, 66, x + 1, 68), fill=hexc("4f8a2e"))
    return contorno(im)


def clinica():
    im = Image.new("RGBA", (96, 80))
    d = ImageDraw.Draw(im)
    sombra_base(d, 4, 91, 76)
    parede(d, 8, 32, 87, 76, hexc("f4f3ee"), barrado=hexc("4f8a5b"), alt_barrado=8, seed=7)
    telhado(d, 4, 91, 12, 32, hexc("b5532f"), 8)
    placa(d, 18, 34, 77, 42, hexc("4f8a5b"), hexc("f4f3ee"), "VETERINARIA")
    # cruz verde
    d.rectangle((44, 15, 51, 28), fill=hexc("f4f3ee"), outline=OL)
    d.rectangle((40, 19, 55, 24), fill=hexc("f4f3ee"), outline=OL)
    d.rectangle((45, 16, 50, 27), fill=hexc("4f8a5b"))
    d.rectangle((41, 20, 54, 23), fill=hexc("4f8a5b"))
    porta(d, 48, 76, 14, 22, hexc("e8e4d8"), moldura=hexc("4f8a5b"))
    d.rectangle((44, 58, 51, 63), fill=hexc("7fb0c9"), outline=OL)   # visor da porta
    janela(d, 16, 48, 14, 12, hexc("4f8a5b"), vidro=hexc("6c9ab3"))
    janela(d, 66, 48, 14, 12, hexc("4f8a5b"), vidro=hexc("6c9ab3"))
    # pegadinha de bicho no chão e cocho de água
    d.rectangle((70, 70, 84, 75), fill=hexc("8a8f92"), outline=OL)
    d.rectangle((71, 71, 83, 72), fill=hexc("4aa3d6"))
    vaso(d, 26, 70, hexc("f2c94c"))
    return contorno(im)


def igreja():
    im = Image.new("RGBA", (96, 112))
    d = ImageDraw.Draw(im)
    sombra_base(d, 6, 89, 108)
    branco, azul = hexc("f4f1e8"), hexc("3a68a8")
    # nave
    parede(d, 12, 50, 83, 108, branco, barrado=hexc("c9c2b2"), alt_barrado=5, seed=8)
    # frontão curvo (barroco simples) por cima
    d.polygon([(12, 50), (12, 38), (24, 32), (34, 22), (48, 16), (62, 22), (72, 32), (84, 38), (84, 50)],
              fill=branco, outline=OL)
    d.line((14, 48, 82, 48), fill=hexc("d5cebe"))
    d.ellipse((42, 28, 53, 39), fill=azul, outline=OL)   # óculo
    d.ellipse((45, 31, 50, 36), fill=hexc("8fb8e0"))
    # cruz no topo
    d.rectangle((46, 4, 49, 16), fill=hexc("e8c15a"), outline=OL)
    d.rectangle((43, 7, 52, 10), fill=hexc("e8c15a"), outline=OL)
    # torre sineira ao lado (direita)
    d.rectangle((84, 34, 94, 108), fill=branco, outline=OL)
    d.polygon([(83, 34), (89, 24), (95, 34)], fill=hexc("b5532f"), outline=OL)
    d.rectangle((86, 40, 92, 48), fill=hexc("2b2f3a"), outline=OL)
    d.ellipse((87, 42, 91, 46), fill=hexc("e8c15a"), outline=OL)   # sino
    # cunhais e porta azul em arco
    d.rectangle((12, 50, 15, 107), fill=azul)
    d.rectangle((80, 50, 83, 107), fill=azul)
    d.pieslice((38, 74, 57, 92), 180, 360, fill=hexc("d5cebe"), outline=OL)
    d.rectangle((38, 83, 57, 108), fill=hexc("d5cebe"), outline=OL)
    d.pieslice((40, 76, 55, 90), 180, 360, fill=azul, outline=OL)
    d.rectangle((40, 83, 55, 108), fill=azul, outline=OL)
    d.line((47, 78, 47, 108), fill=OL)
    for yy in (88, 98):
        d.rectangle((42, yy, 45, yy + 6), outline=esc(azul, 0.3))
        d.rectangle((50, yy, 53, yy + 6), outline=esc(azul, 0.3))
    for x in (20, 66):
        d.pieslice((x, 60, x + 10, 70), 180, 360, fill=azul, outline=OL)
        d.rectangle((x, 65, x + 10, 78), fill=azul, outline=OL)
        d.rectangle((x + 2, 66, x + 8, 76), fill=hexc("8fb8e0"))
    d.rectangle((34, 108, 61, 109), fill=hexc("9d958a"), outline=OL)
    return contorno(im)


PREDIOS = {
    "casa_principal": casa_principal, "casa_azul": casa_azul, "casa_amarela": casa_amarela,
    "mercearia": mercearia, "ferreiro": ferreiro, "bar": bar, "clinica": clinica, "igreja": igreja,
}


def gerar(root):
    import os
    for nome, fn in PREDIOS.items():
        yield os.path.join(root, "assets", "environments", nome + "_placeholder.png"), fn()
