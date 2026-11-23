"""
Móveis de dentro das casas (pixel art 2D chapada, contorno escuro).
Saem em assets/environments/<nome>_placeholder.png e são postos pelas
cenas de interior (scripts/world/interior_level.gd). A base de cada móvel
fica na última linha da imagem.
"""
import numpy as np
from PIL import Image, ImageDraw

from casas import OL, hexc, esc, cla, contorno, texto

MAD = hexc("8a5a34")      # madeira
MAD_E = hexc("6b4426")
MAD_C = hexc("a8774a")


def nova(w, h):
    im = Image.new("RGBA", (w, h))
    return im, ImageDraw.Draw(im)


def sombra(d, w, h):
    d.rectangle((1, h - 2, w - 2, h - 1), fill=(30, 20, 14, 70))


def cama(w, colcha, detalhe, travesseiro=hexc("f4f0e4"), madeira=MAD, padrao="retalho"):
    h = 30
    im, d = nova(w, h)
    sombra(d, w, h)
    # cabeceira
    d.rectangle((0, 0, w - 1, 7), fill=madeira, outline=OL)
    d.line((1, 1, w - 2, 1), fill=cla(madeira, 0.2))
    for x in range(3, w - 2, 4):
        d.line((x, 2, x, 6), fill=esc(madeira, 0.25))
    # colchão + colcha
    d.rectangle((1, 6, w - 2, h - 4), fill=colcha, outline=OL)
    d.rectangle((3, 7, w - 4, 11), fill=travesseiro, outline=OL)
    d.line((4, 10, w - 5, 10), fill=esc(travesseiro, 0.12))
    if padrao == "retalho":
        for yy in range(13, h - 5, 4):
            for xx in range(2, w - 3, 4):
                if (xx // 4 + yy // 4) % 2 == 0:
                    d.rectangle((xx, yy, xx + 3, yy + 3), fill=detalhe)
    elif padrao == "listra":
        for yy in range(13, h - 5, 3):
            d.line((2, yy, w - 3, yy), fill=detalhe)
    elif padrao == "croche":
        for yy in range(14, h - 5, 3):
            for xx in range(3 + (yy % 2), w - 3, 3):
                d.point((xx, yy), fill=detalhe)
        d.line((2, 13, w - 3, 13), fill=detalhe)
    d.line((2, 12, w - 3, 12), fill=esc(colcha, 0.25))   # dobra da colcha
    # pé da cama
    d.rectangle((0, h - 5, w - 1, h - 3), fill=madeira, outline=OL)
    return contorno(im)


def fogao_lenha():
    im, d = nova(34, 30)
    sombra(d, 34, 30)
    d.rectangle((14, 0, 18, 10), fill=hexc("4a4542"), outline=OL)    # cano da chaminé
    d.rectangle((0, 9, 33, 27), fill=hexc("d9cfc0"), outline=OL)     # alvenaria caiada
    d.rectangle((1, 10, 32, 14), fill=hexc("2e2b29"), outline=OL)    # chapa de ferro
    for x in (6, 16, 26):
        d.ellipse((x - 3, 10, x + 3, 14), outline=hexc("5a5552"))
    # panelas em cima
    d.rectangle((3, 6, 10, 11), fill=hexc("9aa3a6"), outline=OL)
    d.line((2, 7, 11, 7), fill=OL)
    d.ellipse((20, 5, 30, 12), fill=hexc("3a3533"), outline=OL)      # caldeirão
    d.point((24, 4), fill=hexc("e8e8e8"))
    d.point((26, 2), fill=hexc("e8e8e8"))
    # boca do fogo e lenha
    d.rectangle((5, 18, 15, 25), fill=hexc("2b1d18"), outline=OL)
    d.rectangle((7, 21, 13, 24), fill=hexc("f08a2a"))
    d.rectangle((9, 22, 11, 23), fill=hexc("ffd56a"))
    d.rectangle((19, 18, 30, 25), fill=hexc("b8ad9c"), outline=OL)
    for y in (20, 23):
        d.line((20, y, 29, y), fill=MAD)
    d.line((1, 26, 32, 26), fill=hexc("a8603a"))
    return contorno(im)


def fogao_gas():
    im, d = nova(18, 22)
    sombra(d, 18, 22)
    d.rectangle((0, 0, 17, 19), fill=hexc("f2f0ea"), outline=OL)
    d.rectangle((1, 1, 16, 6), fill=hexc("3a3533"), outline=OL)
    for x in (5, 12):
        d.ellipse((x - 2, 2, x + 2, 5), outline=hexc("8a8580"))
    d.rectangle((2, 9, 15, 17), fill=hexc("2b2f33"), outline=OL)
    d.line((3, 8, 14, 8), fill=hexc("9aa3a6"))
    return contorno(im)


def mesa(w=28, toalha=None, coisas=True):
    h = 20
    im, d = nova(w, h)
    sombra(d, w, h)
    d.rectangle((1, 12, 3, h - 2), fill=MAD_E, outline=OL)
    d.rectangle((w - 4, 12, w - 2, h - 2), fill=MAD_E, outline=OL)
    d.rectangle((0, 3, w - 1, 12), fill=MAD, outline=OL)
    d.line((1, 4, w - 2, 4), fill=MAD_C)
    if toalha:
        d.rectangle((2, 3, w - 3, 13), fill=toalha, outline=OL)
        for x in range(3, w - 3, 2):
            for y in range(4, 13, 2):
                if (x // 2 + y // 2) % 2 == 0:
                    d.point((x, y), fill=hexc("f4f0e4"))
    if coisas:
        d.ellipse((5, 2, 11, 7), fill=hexc("f4f0e4"), outline=OL)       # prato
        d.rectangle((w - 11, 0, w - 7, 6), fill=hexc("b0552f"), outline=OL)  # moringa
        d.point((w - 9, 1), fill=hexc("d9814f"))
        d.ellipse((13, 3, 18, 7), fill=hexc("d4b02f"), outline=OL)      # pequi na fruteira
    return contorno(im)


def banco(w=24):
    im, d = nova(w, 9)
    d.rectangle((0, 0, w - 1, 3), fill=MAD, outline=OL)
    d.line((1, 1, w - 2, 1), fill=MAD_C)
    d.rectangle((2, 4, 4, 8), fill=MAD_E, outline=OL)
    d.rectangle((w - 5, 4, w - 3, 8), fill=MAD_E, outline=OL)
    return contorno(im)


def cadeira(cor=MAD):
    im, d = nova(10, 16)
    d.rectangle((1, 0, 8, 7), fill=cor, outline=OL)
    for x in (3, 6):
        d.line((x, 1, x, 6), fill=esc(cor, 0.25))
    d.rectangle((0, 7, 9, 10), fill=cla(cor, 0.1), outline=OL)
    d.rectangle((1, 11, 2, 15), fill=esc(cor, 0.2), outline=OL)
    d.rectangle((7, 11, 8, 15), fill=esc(cor, 0.2), outline=OL)
    return contorno(im)


def guarda_roupa(cor=MAD):
    im, d = nova(22, 34)
    sombra(d, 22, 34)
    d.rectangle((0, 0, 21, 31), fill=cor, outline=OL)
    d.rectangle((0, 0, 21, 3), fill=esc(cor, 0.2), outline=OL)
    d.line((10, 4, 10, 30), fill=OL)
    for x0 in (2, 12):
        d.rectangle((x0, 6, x0 + 6, 27), outline=esc(cor, 0.25))
    d.point((8, 17), fill=hexc("e8c15a"))
    d.point((13, 17), fill=hexc("e8c15a"))
    d.rectangle((1, 29, 20, 31), fill=esc(cor, 0.3))
    return contorno(im)


def comoda(com_santo=True):
    im, d = nova(20, 26)
    sombra(d, 20, 26)
    d.rectangle((0, 8, 19, 23), fill=MAD, outline=OL)
    for y in (12, 17):
        d.line((1, y, 18, y), fill=OL)
        d.point((9, y - 2), fill=hexc("e8c15a"))
    d.point((9, 21), fill=hexc("e8c15a"))
    if com_santo:   # oratório com vela
        d.rectangle((6, 0, 13, 8), fill=hexc("3f72ab"), outline=OL)
        d.rectangle((8, 2, 11, 7), fill=hexc("f4f0e4"))
        d.point((9, 3), fill=hexc("d9a173"))
        d.rectangle((15, 4, 16, 8), fill=hexc("f4f0e4"), outline=OL)
        d.point((15, 2), fill=hexc("ffd56a"))
    else:
        d.rectangle((3, 3, 7, 8), fill=hexc("b0552f"), outline=OL)
        d.ellipse((2, 0, 8, 4), fill=hexc("4f8a2e"), outline=OL)
    return contorno(im)


def filtro_barro():
    im, d = nova(12, 22)
    sombra(d, 12, 22)
    d.rectangle((1, 12, 10, 19), fill=MAD, outline=OL)          # banquinho
    d.ellipse((2, 0, 9, 7), fill=hexc("b8653b"), outline=OL)    # parte de cima
    d.rectangle((1, 5, 10, 12), fill=hexc("b8653b"), outline=OL)
    d.line((2, 6, 9, 6), fill=hexc("d9814f"))
    d.rectangle((5, 9, 7, 10), fill=hexc("9aa3a6"))             # torneirinha
    return contorno(im)


def pia():
    im, d = nova(26, 22)
    sombra(d, 26, 22)
    d.rectangle((0, 7, 25, 19), fill=hexc("eae6dc"), outline=OL)   # gabinete
    d.rectangle((0, 4, 25, 8), fill=hexc("b9b3a6"), outline=OL)    # tampo
    d.rectangle((14, 5, 23, 7), fill=hexc("7aa7c2"))
    d.line((18, 0, 18, 5), fill=hexc("9aa3a6"))
    d.line((18, 0, 21, 0), fill=hexc("9aa3a6"))
    d.ellipse((3, 1, 9, 6), fill=hexc("f4f0e4"), outline=OL)       # pratos
    d.line((12, 9, 12, 18), fill=OL)
    for x0 in (2, 14):   # cortininha de pano
        for x in range(x0, x0 + 10, 2):
            d.line((x, 9, x, 18), fill=hexc("d86b5a"))
    return contorno(im)


def prateleira_panelas():
    im, d = nova(26, 18)
    d.rectangle((0, 10, 25, 12), fill=MAD, outline=OL)
    for x, c in ((2, hexc("9aa3a6")), (9, hexc("b0552f")), (17, hexc("9aa3a6"))):
        d.rectangle((x, 3, x + 6, 9), fill=c, outline=OL)
        d.line((x + 1, 4, x + 5, 4), fill=cla(c, 0.3))
    for x in (4, 12, 20):   # canecas penduradas
        d.rectangle((x, 13, x + 2, 16), fill=hexc("f4f0e4"), outline=OL)
    return contorno(im)


def estante():
    im, d = nova(22, 32)
    sombra(d, 22, 32)
    d.rectangle((0, 0, 21, 29), fill=MAD_E, outline=OL)
    rng = np.random.default_rng(3)
    for y in (2, 11, 20):
        d.line((1, y + 8, 20, y + 8), fill=MAD)
        x = 2
        while x < 19:
            w = int(rng.integers(1, 3))
            c = [hexc("b23a2e"), hexc("3f72ab"), hexc("4f8a2e"), hexc("e8c15a"), hexc("f4f0e4")][int(rng.integers(0, 5))]
            d.rectangle((x, y + 2 + int(rng.integers(0, 2)), x + w, y + 7), fill=c)
            x += w + 1
    return contorno(im)


def rede(cor=hexc("d84a3a")):
    im, d = nova(34, 16)
    d.line((0, 2, 3, 4), fill=OL)
    d.line((33, 2, 30, 4), fill=OL)
    d.chord((3, -6, 30, 13), 0, 180, fill=cor, outline=OL)
    for x in range(6, 29, 4):
        d.line((x, 5, x + 1, 10), fill=hexc("f2c94c"))
    return contorno(im)


def tapete(w=30, h=18, cor=hexc("c0613a"), cor2=hexc("f2c94c")):
    im, d = nova(w, h)
    d.ellipse((0, 0, w - 1, h - 1), fill=cor)
    d.ellipse((3, 2, w - 4, h - 3), outline=cor2)
    d.ellipse((7, 5, w - 8, h - 6), outline=cla(cor, 0.25))
    return im   # sem contorno: fica no chão


def quadro(cor=hexc("4f8a2e")):
    im, d = nova(14, 12)
    d.rectangle((0, 0, 13, 11), fill=hexc("c9a46b"), outline=OL)
    d.rectangle((2, 2, 11, 9), fill=hexc("8fc3e0"))
    d.rectangle((2, 6, 11, 9), fill=cor)
    d.ellipse((8, 3, 10, 5), fill=hexc("f2c94c"))
    return contorno(im)


def relogio():
    im, d = nova(10, 18)
    d.rectangle((1, 0, 8, 17), fill=MAD, outline=OL)
    d.ellipse((2, 1, 7, 6), fill=hexc("f4f0e4"), outline=OL)
    d.line((4, 3, 4, 4), fill=OL)
    d.line((5, 8, 5, 14), fill=hexc("e8c15a"))
    d.ellipse((3, 13, 6, 16), fill=hexc("e8c15a"))
    return contorno(im)


def varas_pesca():
    im, d = nova(18, 26)
    for i, x in enumerate((3, 8, 13)):
        d.line((x, 0, x + 2, 25), fill=hexc("c9a46b"))
        d.point((x + 2, 20 + i), fill=hexc("d84a3a"))
    d.rectangle((0, 18, 17, 20), fill=MAD, outline=OL)
    return contorno(im)


def ferramentas_parede():
    im, d = nova(26, 16)
    d.rectangle((0, 0, 25, 2), fill=MAD, outline=OL)
    for x, comp in ((3, 12), (9, 9), (15, 13), (21, 10)):
        d.line((x, 3, x, 3 + comp), fill=MAD_C)
        d.rectangle((x - 2, 3 + comp - 2, x + 2, 3 + comp), fill=hexc("9aa3a6"), outline=OL)
    return contorno(im)


def bigorna():
    im, d = nova(18, 14)
    sombra(d, 18, 14)
    d.polygon([(0, 2), (17, 2), (14, 6), (4, 6)], fill=hexc("4a4f52"), outline=OL)
    d.line((2, 3, 15, 3), fill=hexc("7d8689"))
    d.rectangle((6, 6, 11, 9), fill=hexc("3b3f42"), outline=OL)
    d.rectangle((3, 9, 14, 11), fill=MAD, outline=OL)
    return contorno(im)


def maca():
    im, d = nova(30, 18)
    sombra(d, 30, 18)
    d.rectangle((2, 9, 3, 15), fill=hexc("9aa3a6"), outline=OL)
    d.rectangle((26, 9, 27, 15), fill=hexc("9aa3a6"), outline=OL)
    d.rectangle((0, 3, 29, 9), fill=hexc("6fb39a"), outline=OL)
    d.rectangle((1, 2, 8, 6), fill=hexc("f4f4f0"), outline=OL)
    d.line((1, 4, 28, 4), fill=hexc("8fc9b3"))
    return contorno(im)


def armario_remedio():
    im, d = nova(18, 26)
    sombra(d, 18, 26)
    d.rectangle((0, 0, 17, 23), fill=hexc("f4f4f0"), outline=OL)
    d.rectangle((2, 2, 15, 11), fill=hexc("bcd8e6"), outline=OL)
    for x, c in ((3, hexc("b23a2e")), (7, hexc("e8c15a")), (11, hexc("4f8a5b"))):
        d.rectangle((x, 6, x + 2, 10), fill=c)
    d.rectangle((6, 15, 11, 20), fill=hexc("4f8a5b"))
    d.rectangle((8, 14, 9, 21), fill=hexc("f4f4f0"))
    d.rectangle((5, 17, 12, 18), fill=hexc("f4f4f0"))
    return contorno(im)


def vaso_planta():
    im, d = nova(12, 18)
    sombra(d, 12, 18)
    d.polygon([(2, 10), (9, 10), (8, 16), (3, 16)], fill=hexc("b0552f"), outline=OL)
    for (x, y) in ((5, 0), (1, 3), (9, 3), (3, 6), (8, 6)):
        d.ellipse((x - 2, y, x + 2, y + 5), fill=hexc("4f8a2e"), outline=OL)
    d.line((5, 4, 5, 10), fill=hexc("3a6b23"))
    return contorno(im)


def sacos():
    im, d = nova(20, 14)
    sombra(d, 20, 14)
    for x, c in ((0, hexc("d9c59a")), (9, hexc("cbb487"))):
        d.rounded_rectangle((x, 2, x + 10, 12), 3, fill=c, outline=OL)
        d.line((x + 2, 4, x + 8, 4), fill=esc(c, 0.2))
    d.ellipse((2, 0, 7, 3), fill=hexc("8a5a34"), outline=OL)    # feijão
    d.ellipse((11, 0, 16, 3), fill=hexc("f2c94c"), outline=OL)  # milho
    return contorno(im)


def barril():
    im, d = nova(14, 18)
    sombra(d, 14, 18)
    d.rounded_rectangle((0, 0, 13, 15), 3, fill=MAD, outline=OL)
    for y in (3, 11):
        d.line((1, y, 12, y), fill=hexc("4a4f52"))
    d.line((4, 1, 4, 14), fill=MAD_C)
    return contorno(im)


def balcao_atendimento():
    im, d = nova(34, 20)
    sombra(d, 34, 20)
    d.rectangle((0, 4, 33, 17), fill=hexc("6fb39a"), outline=OL)
    d.rectangle((0, 2, 33, 5), fill=hexc("e8e4d8"), outline=OL)
    d.rectangle((3, 0, 9, 3), fill=hexc("f4f0e4"), outline=OL)   # caderno
    d.line((4, 1, 8, 1), fill=hexc("3f72ab"))
    d.ellipse((24, 0, 29, 4), fill=hexc("d84a3a"), outline=OL)  # potinho
    return contorno(im)


def capacho():
    im, d = nova(16, 10)
    d.rectangle((0, 0, 15, 9), fill=hexc("a8783e"))
    for y in range(1, 9, 2):
        d.line((1, y, 14, y), fill=hexc("8a5f2e"))
    return im


MOVEIS = {
    "cama_jogador": lambda: cama(20, hexc("c8483b"), hexc("f2c94c")),
    "cama_helena": lambda: cama(30, hexc("3f72ab"), hexc("f4f0e4"), padrao="croche"),
    "cama_alzira": lambda: cama(20, hexc("dd7d9e"), hexc("f4f0e4")),
    "cama_joao": lambda: cama(18, hexc("4f8a6b"), hexc("e07a3a"), padrao="listra"),
    "cama_toninho": lambda: cama(20, hexc("7d4c2b"), hexc("a8774a"), padrao="listra", madeira=MAD_E),
    "cama_mariana": lambda: cama(20, hexc("f4f4f0"), hexc("5a9566"), padrao="croche"),
    "fogao_casa": fogao_lenha,
    "fogao_gas": fogao_gas,
    "mesa_madeira": lambda: mesa(28),
    "mesa_xadrez": lambda: mesa(28, toalha=hexc("c8483b")),
    "mesa_azul": lambda: mesa(24, toalha=hexc("3f72ab")),
    "banco_madeira_casa": banco,
    "cadeira": cadeira,
    "cadeira_azul": lambda: cadeira(hexc("3f72ab")),
    "guarda_roupa": guarda_roupa,
    "guarda_roupa_branco": lambda: guarda_roupa(hexc("e8e4d8")),
    "comoda_santo": comoda,
    "comoda_vaso": lambda: comoda(False),
    "filtro_barro": filtro_barro,
    "pia": pia,
    "prateleira_panelas": prateleira_panelas,
    "estante": estante,
    "tapete_redondo": tapete,
    "tapete_azul": lambda: tapete(30, 18, hexc("3f72ab"), hexc("f4f0e4")),
    "tapete_verde": lambda: tapete(26, 16, hexc("5a9566"), hexc("f2c94c")),
    "quadro_paisagem": quadro,
    "quadro_ipe": lambda: quadro(hexc("e8b628")),
    "relogio_parede": relogio,
    "varas_pesca": varas_pesca,
    "ferramentas_parede": ferramentas_parede,
    "bigorna": bigorna,
    "maca": maca,
    "armario_remedio": armario_remedio,
    "vaso_planta": vaso_planta,
    "sacos": sacos,
    "barril": barril,
    "balcao_clinica": balcao_atendimento,
    "capacho": capacho,
}


def gerar(root):
    import os
    for nome, fn in MOVEIS.items():
        yield os.path.join(root, "assets", "environments", nome + "_placeholder.png"), fn()
