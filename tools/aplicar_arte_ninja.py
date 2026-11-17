"""
Etapa 1 da arte nova: chão, jogador, moradores, Mãe-do-Ouro e árvores no traço
do pacote Ninja Adventure (CC0, pixel-boy/AAA), repintados com cara de
fazendinha do Cerrado. Grava por cima das imagens provisórias em assets/.

Uso: python3 tools/aplicar_arte_ninja.py   (rodar DEPOIS de gerar_assets_provisorios.py)
"""
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "third_party", "ninja_adventure")
OL = (20, 27, 27, 255)  # contorno do pacote


def src(name):
    return Image.open(os.path.join(SRC, name)).convert("RGBA")


def out(path):
    p = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


def cell(img, cx, cy, w=1, h=1):
    return img.crop((cx * 16, cy * 16, (cx + w) * 16, (cy + h) * 16))


def recolor(img, mapping):
    im = img.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            p = px[x, y]
            if p[3] and p[:3] in mapping:
                px[x, y] = tuple(mapping[p[:3]]) + (p[3],)
    return im


# --- chão ----------------------------------------------------------------------

def tiles():
    floor = src("tileset_floor.png")
    inner = src("tileset_interior_floor.png")
    anim = src("tileset_animated.png")
    def speckle(t, seed, colors, n=10):
        r = random.Random(seed)
        d = ImageDraw.Draw(t)
        for _ in range(n):
            x, y = r.randrange(16), r.randrange(16)
            d.point((x, y), fill=r.choice(colors) + (255,))
            if r.random() < 0.4 and y > 0:
                d.point((x, y - 1), fill=colors[0] + (255,))
        return t

    base_green = cell(floor, 11, 12)
    g = base_green.getpixel((8, 8))[:3]
    grass = speckle(base_green.copy(), 1, [tuple(int(v * 0.82) for v in g), tuple(min(255, int(v * 1.12)) for v in g)], 12)
    dark = Image.eval(base_green, lambda v: int(v * 0.78))
    dark.putalpha(255)
    dark = speckle(dark, 2, [tuple(int(v * 0.6) for v in g), tuple(int(v * 0.9) for v in g)], 14)
    dirt = cell(floor, 1, 8)
    dirt_px = dirt.load()
    # paleta da terra (do mais escuro ao mais claro)
    browns = sorted({dirt_px[x, y][:3] for x in range(16) for y in range(16)}, key=sum)

    def flores():
        t = grass.copy()  # grama lisa + florzinhas (o tufo do pacote repetia demais)
        d = ImageDraw.Draw(t)
        for (x, y, c) in [(3, 4, (250, 246, 230)), (11, 10, (255, 214, 60)), (12, 3, (250, 246, 230)), (5, 12, (236, 120, 150))]:
            d.point((x, y), fill=c + (255,))
            d.point((x, y + 1), fill=(86, 134, 76, 255))
        return t

    def arada():
        t = Image.new("RGBA", (16, 16), browns[len(browns) // 2] + (255,))
        d = ImageDraw.Draw(t)
        for y in (1, 6, 11):
            d.line([(0, y), (15, y)], fill=browns[0] + (255,))
            d.line([(0, y + 1), (15, y + 1)], fill=browns[1] + (255,))
            d.line([(0, y + 3), (15, y + 3)], fill=browns[-1] + (255,))
        return t

    W1, W2, W3, W4 = (62, 116, 168), (86, 152, 200), (128, 192, 226), (214, 240, 248)

    def agua(seed=1):
        r = random.Random(seed)
        t = Image.new("RGBA", (16, 16), W2 + (255,))
        d = ImageDraw.Draw(t)
        for y in (2, 9, 14):
            x = r.randrange(0, 10)
            d.line([(x, y), (x + 4, y)], fill=W3 + (255,))
            d.point((x + 1, y - 1), fill=W4 + (255,))
        d.point((r.randrange(16), r.randrange(16)), fill=W1 + (255,))
        return t

    def margem():
        t = agua(3)
        t.alpha_composite(grass.crop((0, 0, 16, 4)), (0, 0))
        d = ImageDraw.Draw(t)
        d.line([(0, 4), (15, 4)], fill=(70, 110, 60, 255))
        d.line([(0, 5), (15, 5)], fill=W1 + (255,))
        return t

    def ponte():
        planks = [(150, 96, 58), (176, 118, 70), (122, 76, 48)]
        t = Image.new("RGBA", (16, 16), planks[0] + (255,))
        d = ImageDraw.Draw(t)
        for x in (0, 5, 10, 15):
            d.line([(x, 0), (x, 15)], fill=planks[2] + (255,))
        for x in (1, 6, 11):
            d.line([(x, 0), (x, 15)], fill=planks[1] + (255,))
        d.rectangle([0, 0, 15, 1], fill=(84, 52, 40, 255))
        d.rectangle([0, 14, 15, 15], fill=(84, 52, 40, 255))
        for x in (3, 8, 13):
            d.point((x, 7), fill=OL)
        return t

    cave = recolor(cell(inner, 12, 13), {})
    def rocha():
        t = cell(inner, 12, 13)
        t = Image.eval(t, lambda v: int(v * 0.62))
        t.putalpha(255)
        d = ImageDraw.Draw(t)
        for x0 in (0, 8):
            d.ellipse([x0, -3, x0 + 8, 5], fill=(92, 84, 96, 255), outline=OL)
            d.point((x0 + 3, 0), fill=(150, 142, 150, 255))
        return t

    pieces = [grass, flores(), cell(floor, 2, 5), dirt, arada(), agua(), dark, margem(),
              cell(inner, 1, 13), ponte(), cave, rocha(), cell(inner, 12, 8)]
    sheet = Image.new("RGBA", (16 * len(pieces), 16))
    for i, p in enumerate(pieces):
        sheet.alpha_composite(p.convert("RGBA"), (i * 16, 0))
    sheet.save(out("assets/tilesets/farm_tiles_placeholder.png"))


# --- personagens -----------------------------------------------------------------

# direções do jogo (linhas): S, SE, E, NE, N, NW, W, SW → colunas do pacote: baixo 0, cima 1, esq. 2, dir. 3
DIR_COL = [0, 3, 3, 3, 1, 2, 2, 2]


def to_sheet(src_img, path):
    sheet = Image.new("RGBA", (128, 256), (0, 0, 0, 0))
    for row, col in enumerate(DIR_COL):
        for f in range(4):
            fr = src_img.crop((col * 16, f * 16, col * 16 + 16, f * 16 + 16))
            sheet.alpha_composite(fr, (f * 32 + 8, row * 32 + 15))
    sheet.save(out(path))


HAT = (241, 196, 113)


def with_straw_hat(body, hatted):
    """Põe o chapéu de palha do samurai verde em cima do personagem humano, quadro a quadro."""
    im = body.copy()
    hp, bp, ip = hatted.load(), body.load(), im.load()
    for fy in range(0, body.height, 16):
        for fx in range(0, body.width, 16):
            ys = [y for y in range(fy, fy + 16) for x in range(fx, fx + 16) if hp[x, y][:3] == HAT and hp[x, y][3]]
            if not ys:
                continue
            bottom = max(ys)
            for y in range(fy, bottom + 1):
                for x in range(fx, fx + 16):
                    ip[x, y] = (0, 0, 0, 0)
            for y in range(fy, bottom + 2):
                for x in range(fx, fx + 16):
                    p = hp[x, y]
                    near = any(hp[x + dx, y + dy][:3] == HAT for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                               if fx <= x + dx < fx + 16 and fy <= y + dy < fy + 16)
                    if p[3] and (p[:3] == HAT or (p[:3] == OL[:3] and near)):
                        ip[x, y] = p
            # fita vermelha na base da copa do chapéu
            row = [x for x in range(fx, fx + 16) if ip[x, bottom - 2][:3] == HAT]
            for x in row[2:-2]:
                ip[x, bottom - 2] = (196, 70, 62, 255)
    return im


def player():
    body = recolor(src("samurai_blue.png"), {
        (59, 54, 67): (96, 60, 36), (78, 72, 74): (70, 44, 28),        # cabelo castanho
        (239, 145, 79): (238, 176, 128), (209, 75, 52): (204, 128, 92),  # pele
        (84, 135, 137): (196, 70, 62), (121, 184, 206): (226, 104, 90),  # camisa vermelha
        (74, 82, 112): (68, 98, 156),                                    # calça
    })
    to_sheet(with_straw_hat(body, src("samurai_green.png")), "assets/characters/player_placeholder.png")


NPC_COLORS = {
    #           cabelo,                       pele,                       roupa (escura, clara)
    "helena": [(120, 70, 40), (90, 52, 32), (239, 170, 120), (205, 120, 85), (90, 140, 74), (150, 200, 110)],
    "benedito": [(226, 226, 220), (180, 180, 172), (200, 130, 90), (160, 96, 66), (150, 116, 72), (214, 182, 130)],
    "toninho": [(40, 34, 36), (64, 56, 58), (150, 92, 60), (116, 66, 44), (96, 64, 44), (150, 102, 62)],
    "alzira": [(170, 170, 176), (128, 128, 136), (226, 150, 110), (190, 110, 80), (180, 86, 120), (236, 156, 182)],
    "mariana": [(150, 64, 40), (112, 46, 34), (244, 186, 146), (210, 130, 100), (190, 196, 206), (246, 248, 250)],
    "joao_pedro": [(86, 54, 32), (62, 40, 26), (214, 140, 92), (176, 100, 64), (52, 84, 150), (104, 150, 210)],
}


def npcs():
    base = src("samurai_blue.png")
    for name, (h1, h2, s1, s2, c1, c2) in NPC_COLORS.items():
        im = recolor(base, {
            (59, 54, 67): h1, (78, 72, 74): h2,       # cabelo
            (239, 145, 79): s1, (209, 75, 52): s2,    # pele
            (84, 135, 137): c1, (121, 184, 206): c2,  # roupa
        })
        to_sheet(im, f"assets/npcs/{name}_placeholder.png")
    # Mãe-do-Ouro: a mesma moça, toda em ouro, com brilho que pulsa (4 quadros 24x24)
    gold = recolor(base, {
        (59, 54, 67): (250, 214, 90), (78, 72, 74): (214, 160, 40), (239, 145, 79): (255, 236, 180),
        (209, 75, 52): (232, 180, 90), (84, 135, 137): (240, 190, 60), (121, 184, 206): (255, 238, 150),
        (20, 27, 27): (120, 70, 20),
    })
    sheet = Image.new("RGBA", (96, 24), (0, 0, 0, 0))
    for f in range(4):
        fr = gold.crop((0, f * 16, 16, f * 16 + 16))
        glow = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
        d = ImageDraw.Draw(glow)
        a = 50 + f * 25 if f < 3 else 75
        d.ellipse([1, 2, 22, 23], fill=(255, 220, 110, a))
        glow.alpha_composite(fr, (4, 6))
        for (x, y) in [(3, 5 + f), (20, 8 - f), (12, 1 + f % 2)]:
            ImageDraw.Draw(glow).point((x, y), fill=(255, 255, 220, 255))
        sheet.alpha_composite(glow, (f * 24, 0))
    sheet.save(out("assets/npcs/mae_do_ouro_placeholder.png"))


# --- árvores e arbusto -------------------------------------------------------------

def trees():
    vil = src("tileset_village_abandoned.png")
    tree = vil.crop((64, 96, 96, 128))  # árvore redonda pequena
    tree = tree.crop(tree.getbbox())
    # tronco laranja (outono do pacote) → marrom de pau do Cerrado
    oranges = sorted({tree.getpixel((x, y))[:3] for x in range(tree.width) for y in range(tree.height)
                      if tree.getpixel((x, y))[3] and tree.getpixel((x, y))[0] > tree.getpixel((x, y))[1] + 40}, key=sum)
    browns = [(84, 52, 40), (112, 72, 48), (140, 92, 58), (166, 114, 72)]
    tree = recolor(tree, {c: browns[min(3, i * 4 // max(1, len(oranges)))] for i, c in enumerate(oranges)})

    def place(t, path, extra=None):
        canvas = Image.new("RGBA", (40, 48), (0, 0, 0, 0))
        d = ImageDraw.Draw(canvas)
        d.ellipse([8, 42, 32, 47], fill=(0, 0, 0, 60))
        canvas.alpha_composite(t, ((40 - t.width) // 2, 46 - t.height))
        if extra:
            extra(ImageDraw.Draw(canvas), (40 - t.width) // 2, 46 - t.height)
        canvas.save(out(path))

    leaf = {c for c in [(tree.getpixel((x, y))[:3]) for x in range(tree.width) for y in range(tree.height)
                        if tree.getpixel((x, y))[3]]}
    greens = sorted([c for c in leaf if c[1] > c[0] and c[1] > c[2]], key=sum)

    def pequis(d, ox, oy):
        for (x, y) in [(7, 8), (20, 6), (25, 14), (12, 15), (17, 11)]:
            d.ellipse([ox + x, oy + y, ox + x + 3, oy + y + 3], fill=(150, 176, 60, 255), outline=OL)
            d.point((ox + x + 1, oy + y + 1), fill=(240, 210, 70, 255))
    place(tree, "assets/environments/pequizeiro_placeholder.png", pequis)
    yellows = [(214, 150, 30), (240, 186, 40), (255, 214, 70), (255, 236, 130)]
    ipe_map = {g: yellows[min(len(yellows) - 1, i * len(yellows) // max(1, len(greens)))] for i, g in enumerate(greens)}

    def flores(d, ox, oy):
        r = random.Random(4)
        for _ in range(14):
            x, y = r.randrange(4, tree.width - 4), r.randrange(3, tree.height - 12)
            if tree.getpixel((x, y))[3]:
                d.point((ox + x, oy + y), fill=(255, 250, 220, 255))
    place(recolor(tree, ipe_map), "assets/environments/ipe_amarelo_placeholder.png", flores)
    bush = vil.crop((64, 80, 80, 96))
    canvas = Image.new("RGBA", (20, 16), (0, 0, 0, 0))
    canvas.alpha_composite(bush.crop(bush.getbbox()), (2, 16 - bush.crop(bush.getbbox()).height))
    canvas.save(out("assets/environments/arbusto_placeholder.png"))


def debris():
    """Fazenda bagunçada: mato, galho, pedrinha, árvore do cerrado e toco (+ ícone do galho)."""
    vil = src("tileset_village_abandoned.png")
    browns = [(84, 52, 40), (112, 72, 48), (140, 92, 58), (166, 114, 72)]

    def to_brown(im):
        cols = sorted({im.getpixel((x, y))[:3] for x in range(im.width) for y in range(im.height)
                       if im.getpixel((x, y))[3] and im.getpixel((x, y))[0] > im.getpixel((x, y))[1] + 30}, key=sum)
        return recolor(im, {c: browns[min(3, i * 4 // max(1, len(cols)))] for i, c in enumerate(cols)})

    def fit(im, w, h):
        im = im.crop(im.getbbox())
        c = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        c.alpha_composite(im, ((w - im.width) // 2, h - im.height))
        return c

    mato = fit(vil.crop((80, 80, 96, 96)), 16, 16)
    mato.save(out("assets/environments/mato_placeholder.png"))
    galho = fit(to_brown(vil.crop((80, 128, 96, 144))), 16, 16)
    galho.save(out("assets/environments/galho_placeholder.png"))
    galho.save(out("assets/items/galho_placeholder.png"))
    pedrinha = fit(vil.crop((160, 64, 176, 80)), 16, 16)
    pedrinha.save(out("assets/environments/pedrinha_placeholder.png"))
    toco = fit(to_brown(vil.crop((96, 128, 112, 144))), 16, 16)
    toco.save(out("assets/environments/toco_placeholder.png"))
    tree = vil.crop((64, 96, 96, 128))
    tree = to_brown(tree.crop(tree.getbbox()))
    # árvore do cerrado: copa um pouco mais escura e torta que a do pequizeiro
    greens = sorted({tree.getpixel((x, y))[:3] for x in range(tree.width) for y in range(tree.height)
                     if tree.getpixel((x, y))[3] and tree.getpixel((x, y))[1] > tree.getpixel((x, y))[0] + 10}, key=sum)
    tree = recolor(tree, {g: tuple(int(v * 0.8) for v in g) for g in greens})
    canvas = Image.new("RGBA", (40, 48), (0, 0, 0, 0))
    ImageDraw.Draw(canvas).ellipse([8, 42, 32, 47], fill=(0, 0, 0, 60))
    canvas.alpha_composite(tree, ((40 - tree.width) // 2, 46 - tree.height))
    canvas.save(out("assets/environments/arvore_cerrado_placeholder.png"))


if __name__ == "__main__":
    debris()
    tiles()
    player()
    npcs()
    trees()
    print("Arte Ninja Adventure (etapa 1) aplicada.")
