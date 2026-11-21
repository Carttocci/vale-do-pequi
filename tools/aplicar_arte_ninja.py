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

    def capim():
        # capim dourado do Cerrado: tufos amarelados sobre fundo seco, alguns verdes
        r = random.Random(7)
        base, dk, lt, gr = (186, 164, 86), (148, 124, 58), (224, 202, 120), (128, 150, 70)
        t = Image.new("RGBA", (16, 16), base + (255,))
        d = ImageDraw.Draw(t)
        for _ in range(16):
            x, y = r.randrange(16), r.randrange(2, 16)
            c = gr if r.random() < 0.18 else lt
            d.point((x, y), fill=dk + (255,))
            d.point((x, y - 1), fill=c + (255,))
            if r.random() < 0.5:
                d.point(((x + 1) % 16, y - 2), fill=c + (255,))
        return t

    def ruina():
        # lajes de pedra velha com rejunte, rachadura e musgo
        r = random.Random(5)
        s1, s2, s3, gt, mo = (150, 148, 138), (128, 126, 118), (176, 174, 164), (88, 86, 84), (96, 128, 72)
        t = Image.new("RGBA", (16, 16), s1 + (255,))
        d = ImageDraw.Draw(t)
        for (x0, y0, x1, y1) in [(0, 0, 8, 7), (9, 0, 15, 7), (0, 8, 5, 15), (6, 8, 15, 15)]:
            d.rectangle([x0, y0, x1, y1], fill=r.choice([s1, s2]) + (255,))
            d.line([(x0, y0), (x1, y0)], fill=s3 + (255,))
        d.line([(0, 7), (15, 7)], fill=gt + (255,))
        d.line([(8, 0), (8, 7)], fill=gt + (255,))
        d.line([(5, 8), (5, 15)], fill=gt + (255,))
        d.line([(11, 10), (13, 13)], fill=gt + (255,))
        for (x, y) in [(8, 7), (7, 7), (5, 15), (0, 7)]:
            d.point((x, y), fill=mo + (255,))
        return t

    pieces = [grass, flores(), capim(), dirt, arada(), agua(), dark, margem(),
              cell(inner, 1, 13), ponte(), cave, rocha(), ruina()]
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
    # pedra grande (só a picareta quebra): pedregulho cinza com luz no topo e musgo
    w, h = 22, 20
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([2, h - 5, w - 3, h - 1], fill=(0, 0, 0, 70))
    body = [(2, 15), (1, 9), (4, 4), (9, 1), (15, 2), (20, 7), (21, 13), (18, 17), (6, 17)]
    d.polygon(body, fill=(128, 126, 136, 255), outline=OL)
    d.polygon([(4, 9), (6, 5), (10, 3), (15, 4), (18, 8), (12, 8), (7, 10)], fill=(168, 166, 176, 255))
    d.line([(6, 5), (10, 3)], fill=(208, 206, 214, 255))
    d.line([(11, 9), (13, 14)], fill=(92, 88, 100, 255))
    d.line([(13, 14), (17, 15)], fill=(92, 88, 100, 255))
    for (x, y) in [(3, 14), (4, 15), (5, 15), (18, 14), (19, 12)]:
        d.point((x, y), fill=(110, 150, 60, 255))
    im.save(out("assets/environments/pedra_grande_placeholder.png"))


# --- criação: galinha, pintinho, vaca, bezerro, touro, cachorro, bebedouro, porteira ---

def livestock():
    """Bichos da fazenda no traço do pacote (contorno escuro), 4 quadros andando, virados pra direita."""
    W = (246, 242, 232, 255)
    W2 = (214, 206, 196, 255)
    BLACK = (44, 38, 42, 255)
    PINK = (236, 160, 160, 255)
    ORANGE = (240, 160, 50, 255)
    RED = (214, 60, 52, 255)

    def sheet(w, h, draw):
        im = Image.new("RGBA", (w * 4, h), (0, 0, 0, 0))
        for f in range(4):
            fr = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            draw(ImageDraw.Draw(fr), f)
            im.alpha_composite(fr, (f * w, 0))
        return im

    def galinha(d, f):
        d.ellipse([4, 13, 12, 15], fill=(0, 0, 0, 60))
        a, b = (0, 1) if f % 2 == 0 else (1, 0)
        d.line([(6, 12), (6, 14 - a)], fill=ORANGE)
        d.line([(9, 12), (9, 14 - b)], fill=ORANGE)
        d.polygon([(2, 4), (5, 6), (4, 9)], fill=W, outline=OL)
        d.ellipse([3, 6, 12, 13], fill=W, outline=OL)
        d.arc([5, 8, 10, 12], 200, 340, fill=W2)
        d.ellipse([8, 2, 14, 8], fill=W, outline=OL)
        d.rectangle([10, 1, 11, 2], fill=RED)
        d.polygon([(14, 4), (16, 5), (14, 6)], fill=ORANGE)
        d.point((12, 4), fill=OL)
        d.point((13, 7), fill=RED)

    def pintinho(d, f):
        Y, Y2 = (250, 214, 70, 255), (226, 176, 40, 255)
        d.ellipse([5, 13, 11, 15], fill=(0, 0, 0, 60))
        hop = 1 if f in (1, 3) else 0
        d.ellipse([4, 8 - hop, 11, 14 - hop], fill=Y, outline=OL)
        d.ellipse([8, 5 - hop, 13, 10 - hop], fill=Y, outline=OL)
        d.point((11, 7 - hop), fill=OL)
        d.polygon([(13, 7 - hop), (15, 8 - hop), (13, 9 - hop)], fill=ORANGE)
        d.line([(5, 11 - hop), (8, 12 - hop)], fill=Y2)
        d.point((6, 15), fill=ORANGE)
        d.point((9, 15), fill=ORANGE)

    def bovino(body, spots, size=1.0, horns=False, ring=False, udder=False, muzzle=PINK):
        def draw(d, f):
            s = size
            ox = int(16 - 14 * s)
            oy = int(24 - 22 * s)
            def P(x, y):
                return (ox + int(x * s), oy + int(y * s))
            d.ellipse([P(4, 20)[0], 21, P(26, 20)[0], 23], fill=(0, 0, 0, 60))
            step = [0, 1, 0, -1][f]
            for i, lx in enumerate((7, 11, 19, 23)):
                k = step if i % 2 == 0 else -step
                d.rectangle([P(lx, 16), P(lx + 2, 21 - max(0, k))], fill=body if not spots else W2, outline=OL)
            d.line([P(4, 9), P(2, 15)], fill=OL, width=1)
            d.rounded_rectangle([P(3, 7), P(25, 17)], max(1, int(3 * s)), fill=body, outline=OL)
            if spots:
                for (x0, y0, x1, y1) in [(7, 8, 12, 12), (16, 11, 21, 15), (20, 8, 23, 10)]:
                    d.ellipse([P(x0, y0), P(x1, y1)], fill=spots)
            if udder:
                d.ellipse([P(13, 15), P(18, 18)], fill=PINK, outline=OL)
            d.rounded_rectangle([P(22, 3), P(30, 13)], max(1, int(2 * s)), fill=body, outline=OL)
            d.rounded_rectangle([P(26, 9), P(31, 13)], 1, fill=muzzle, outline=OL)
            d.point(P(27, 6), fill=OL)
            d.polygon([P(21, 4), P(23, 5), P(22, 7)], fill=body, outline=OL)
            if horns:
                d.line([P(24, 3), P(23, 0)], fill=(240, 232, 210, 255), width=max(1, int(2 * s)))
                d.line([P(28, 3), P(30, 0)], fill=(240, 232, 210, 255), width=max(1, int(2 * s)))
            if ring:
                d.arc([P(28, 11), P(31, 14)], 0, 180, fill=(240, 200, 60, 255))
        return draw

    def cachorro(d, f):
        C, C2, C3 = (214, 150, 76, 255), (176, 112, 52, 255), (250, 222, 178, 255)
        d.ellipse([3, 13, 13, 15], fill=(0, 0, 0, 60))
        wag = [0, 1, 0, -1][f]
        d.line([(3, 8), (1, 5 + wag)], fill=C2, width=2)
        a, b = (0, 1) if f % 2 == 0 else (1, 0)
        for x, k in ((4, a), (7, b), (9, a), (11, b)):
            d.line([(x, 11), (x, 14 - k)], fill=C2)
        d.rounded_rectangle([3, 7, 12, 12], 2, fill=C, outline=OL)
        d.line([(5, 11), (10, 11)], fill=C3)
        d.rounded_rectangle([9, 3, 15, 9], 2, fill=C, outline=OL)
        d.rectangle([13, 6, 15, 8], fill=C3)
        d.point((15, 6), fill=OL)
        d.point((12, 5), fill=OL)
        d.polygon([(9, 3), (11, 2), (11, 6)], fill=C2, outline=OL)
        d.point((14, 8), fill=RED if f == 1 else C3)

    sheet(16, 16, galinha).save(out("assets/animals/galinha_placeholder.png"))
    sheet(16, 16, pintinho).save(out("assets/animals/pintinho_placeholder.png"))
    sheet(32, 24, bovino(W, BLACK, udder=True)).save(out("assets/animals/vaca_placeholder.png"))
    sheet(32, 24, bovino(W, (176, 112, 60, 255), size=0.72, muzzle=PINK)).save(out("assets/animals/bezerro_placeholder.png"))
    sheet(32, 24, bovino((84, 58, 48, 255), None, horns=True, ring=True, muzzle=(150, 110, 100, 255))).save(out("assets/animals/touro_placeholder.png"))
    sheet(16, 16, cachorro).save(out("assets/animals/cachorro_placeholder.png"))

    def bebedouro(cheio):
        im = Image.new("RGBA", (18, 12), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.ellipse([1, 9, 16, 11], fill=(0, 0, 0, 60))
        d.polygon([(1, 3), (16, 3), (14, 10), (3, 10)], fill=(140, 92, 58, 255), outline=OL)
        d.line([(2, 4), (15, 4)], fill=(176, 118, 70, 255))
        if cheio:
            d.rectangle([3, 4, 14, 6], fill=(86, 152, 200, 255))
            d.line([(4, 4), (8, 4)], fill=(170, 220, 240, 255))
        else:
            d.rectangle([3, 4, 14, 6], fill=(84, 52, 40, 255))
        return im
    bebedouro(False).save(out("assets/environments/bebedouro_placeholder.png"))
    bebedouro(True).save(out("assets/environments/bebedouro_cheio_placeholder.png"))

    def porteira(aberta, quebrada=False):
        im = Image.new("RGBA", (24, 18), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        wood, light, dark = (150, 96, 58, 255), (182, 124, 74, 255), (100, 62, 42, 255)
        for x in (1, 20):
            d.rectangle([x, 2, x + 2, 17], fill=wood, outline=OL)
        if quebrada:
            d.line([(4, 8), (11, 12)], fill=light, width=2)
            d.line([(13, 14), (19, 9)], fill=light, width=2)
        elif aberta:
            d.rectangle([4, 4, 6, 16], fill=light, outline=OL)
        else:
            for y in (5, 9, 13):
                d.rectangle([3, y, 20, y + 2], fill=light, outline=OL)
            d.line([(4, 14), (19, 5)], fill=dark, width=2)
        return im
    porteira(False).save(out("assets/environments/porteira_fechada_placeholder.png"))
    porteira(True).save(out("assets/environments/porteira_aberta_placeholder.png"))
    porteira(False, True).save(out("assets/environments/porteira_quebrada_placeholder.png"))


def inimigos():
    """Criaturas do Silêncio no traço novo (contorno escuro, 3 tons de lilás, olho que brilha)
    e ícones das armas novas. 4 quadros por folha, viradas pra direita."""
    L, M, D = (186, 172, 220, 255), (128, 112, 170, 255), (78, 64, 112, 255)
    GLOW = (170, 245, 255, 255)
    SH = (0, 0, 0, 60)
    WOOD, WOOD_D = (150, 96, 56, 255), (100, 62, 38, 255)
    MET, MET_L = (196, 202, 214, 255), (240, 244, 250, 255)

    def sheet(w, h, draw, path):
        im = Image.new("RGBA", (w * 4, h), (0, 0, 0, 0))
        for f in range(4):
            fr = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            draw(ImageDraw.Draw(fr), f)
            im.alpha_composite(fr, (f * w, 0))
        im.save(out(path))

    def raiz(d, f):  # 20x24: toco andante com galhos
        st = [0, 1, 0, -1][f]
        d.ellipse([3, 21, 17, 23], fill=SH)
        d.line([(7, 22), (6 + st, 16)], fill=OL, width=3)
        d.line([(7, 21), (6 + st, 17)], fill=WOOD_D)
        d.line([(13, 22), (14 - st, 16)], fill=OL, width=3)
        d.line([(13, 21), (14 - st, 17)], fill=WOOD_D)
        d.polygon([(4, 17), (6, 5), (14, 4), (16, 17)], fill=M, outline=OL)
        d.line([(6, 7), (7, 16)], fill=L)
        d.line([(13, 6), (14, 16)], fill=D)
        d.line([(7, 6), (2, 1 - (f % 2))], fill=OL, width=2)
        d.line([(13, 5), (18, 0 + (f % 2))], fill=OL, width=2)
        d.point((3, 3), fill=D); d.point((17, 2), fill=D)
        d.rectangle([7, 8, 8, 9], fill=GLOW)
        d.rectangle([11, 8, 12, 9], fill=GLOW)
        d.line([(7, 13), (12, 13)], fill=OL)
        d.point((9, 14), fill=OL)

    def lodo(d, f):  # 16x12: gosma que pula
        h = [0, 2, 3, 1][f]
        sq = 1 if h == 0 else 0
        d.ellipse([2, 9, 14, 11], fill=SH)
        d.ellipse([1 - sq, 3 - h + sq, 15 + sq, 11 - h // 2], fill=M, outline=OL)
        d.ellipse([3, 4 - h + sq, 8, 6 - h + sq], fill=L)
        d.line([(3, 9 - h // 2), (12, 9 - h // 2)], fill=D)
        d.point((6, 6 - h + sq), fill=GLOW)
        d.point((10, 6 - h + sq), fill=GLOW)

    def morcego(d, f):  # 16x12
        up = f % 2 == 0
        if up:
            d.polygon([(6, 6), (0, 1), (1, 6), (3, 5), (4, 8)], fill=M, outline=OL)
            d.polygon([(10, 6), (16, 1), (15, 6), (13, 5), (12, 8)], fill=M, outline=OL)
        else:
            d.polygon([(6, 5), (0, 10), (3, 9), (5, 10)], fill=M, outline=OL)
            d.polygon([(10, 5), (16, 10), (13, 9), (11, 10)], fill=M, outline=OL)
        d.ellipse([5, 3, 11, 10], fill=D, outline=OL)
        d.point((6, 2), fill=OL); d.point((10, 2), fill=OL)
        d.point((7, 6), fill=GLOW); d.point((9, 6), fill=GLOW)

    def javali(d, f):  # 24x16
        st = [0, 1, 0, -1][f]
        d.ellipse([3, 13, 21, 15], fill=SH)
        for i, lx in enumerate((6, 9, 15, 18)):
            k = st if i % 2 == 0 else -st
            d.rectangle([lx, 10, lx + 1, 14 - max(0, k)], fill=D, outline=OL)
        d.ellipse([2, 3, 19, 12], fill=M, outline=OL)
        for x in range(5, 15, 3):
            d.line([(x, 3), (x + 1, 1)], fill=OL)
        d.line([(5, 9), (16, 9)], fill=D)
        d.ellipse([15, 5, 23, 11], fill=M, outline=OL)
        d.rectangle([21, 8, 23, 10], fill=L, outline=OL)
        d.line([(20, 10), (22, 12)], fill=MET_L)
        d.point((18, 7), fill=GLOW)
        d.point((16, 4), fill=OL)

    def lobo(d, f):  # 24x18: lobo-guará sombrio, pernas compridas
        st = [0, 2, 0, -2][f]
        d.ellipse([4, 15, 20, 17], fill=SH)
        for i, lx in enumerate((6, 9, 15, 18)):
            k = st if i % 2 == 0 else -st
            d.line([(lx, 10), (lx + k // 2, 16)], fill=OL, width=2)
            d.point((lx + k // 2, 15), fill=D)
        d.polygon([(1, 6), (5, 8), (2, 10)], fill=D, outline=OL)
        d.rounded_rectangle([4, 6, 19, 12], 2, fill=M, outline=OL)
        d.line([(6, 7), (17, 7)], fill=L)
        d.line([(8, 6), (14, 6)], fill=D)
        d.polygon([(16, 7), (18, 2), (21, 3), (23, 7), (20, 10)], fill=M, outline=OL)
        d.polygon([(17, 3), (17, 0), (19, 2)], fill=D, outline=OL)
        d.point((21, 5), fill=GLOW)
        d.point((23, 7), fill=OL)

    def coruja(d, f):  # 16x14: coruja-buraqueira sombria, bate asa
        up = f % 2 == 0
        d.ellipse([4, 3, 12, 13], fill=M, outline=OL)
        d.ellipse([5, 7, 11, 12], fill=L)
        if up:
            d.polygon([(4, 7), (0, 2), (1, 9)], fill=D, outline=OL)
            d.polygon([(12, 7), (16, 2), (15, 9)], fill=D, outline=OL)
        else:
            d.polygon([(4, 8), (0, 13), (3, 11)], fill=D, outline=OL)
            d.polygon([(12, 8), (16, 13), (13, 11)], fill=D, outline=OL)
        d.ellipse([5, 4, 8, 7], fill=GLOW, outline=OL)
        d.ellipse([8, 4, 11, 7], fill=GLOW, outline=OL)
        d.point((6, 5), fill=OL); d.point((9, 5), fill=OL)
        d.point((8, 7), fill=(230, 180, 60, 255))
        d.point((4, 2), fill=OL); d.point((11, 2), fill=OL)

    def sapo(d, f):  # 18x14: cururu do lodo, pula
        h = [0, 2, 3, 1][f]
        d.ellipse([3, 11, 15, 13], fill=SH)
        d.polygon([(2, 12 - h), (5, 8 - h), (6, 12 - h)], fill=D, outline=OL)
        d.ellipse([3, 4 - h, 15, 12 - h], fill=M, outline=OL)
        d.ellipse([5, 8 - h, 13, 12 - h], fill=L)
        for (x, y) in [(6, 6), (9, 5), (11, 7)]:
            d.point((x, y - h), fill=D)
        d.ellipse([11, 2 - h, 15, 6 - h], fill=M, outline=OL)
        d.point((13, 4 - h), fill=GLOW)
        d.line([(12, 8 - h), (16, 8 - h)], fill=OL)
        d.polygon([(13, 12 - h), (16, 11 - h), (17, 13 - h)], fill=D, outline=OL)

    sheet(20, 24, raiz, "assets/enemies/raiz_torta_placeholder.png")
    sheet(16, 12, lodo, "assets/enemies/lodo_cinza_placeholder.png")
    sheet(16, 12, morcego, "assets/enemies/morcego_placeholder.png")
    sheet(24, 16, javali, "assets/enemies/javali_corrompido_placeholder.png")
    sheet(24, 18, lobo, "assets/enemies/lobo_sombra_placeholder.png")
    sheet(16, 14, coruja, "assets/enemies/coruja_sombra_placeholder.png")
    sheet(18, 14, sapo, "assets/enemies/sapo_lodo_placeholder.png")

    def icon(name, draw):
        im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        draw(ImageDraw.Draw(im))
        im.save(out("assets/items/%s_placeholder.png" % name))

    def foice(d):
        d.line([(3, 15), (9, 4)], fill=OL, width=3)
        d.line([(3, 14), (9, 5)], fill=WOOD)
        d.arc([5, 0, 16, 11], 180, 300, fill=OL, width=3)
        d.arc([6, 1, 15, 10], 185, 295, fill=MET)
        d.point((6, 4), fill=MET_L)

    def estilingue(d):
        d.line([(8, 15), (8, 9)], fill=OL, width=3)
        d.line([(8, 14), (8, 9)], fill=WOOD)
        d.line([(8, 9), (4, 3)], fill=OL, width=3)
        d.line([(8, 9), (12, 3)], fill=OL, width=3)
        d.line([(8, 9), (5, 4)], fill=WOOD)
        d.line([(8, 9), (11, 4)], fill=WOOD)
        d.line([(4, 3), (8, 6), (12, 3)], fill=(150, 70, 50, 255))

    def espada_cristal(d):
        d.line([(2, 14), (5, 11)], fill=OL, width=3)
        d.line([(2, 14), (5, 11)], fill=WOOD_D)
        d.line([(3, 9), (7, 13)], fill=OL, width=2)
        d.polygon([(5, 10), (13, 2), (15, 1), (14, 3), (6, 11)], fill=(150, 230, 255, 255), outline=OL)
        d.line([(7, 9), (13, 3)], fill=(235, 252, 255, 255))

    icon("foice", foice)
    icon("estilingue", estilingue)
    icon("espada_cristal", espada_cristal)


def fauna():
    """Bichos do Cerrado e os dois chefes no traço novo. Mesmos tamanhos das provisórias."""
    SH = (0, 0, 0, 60)

    def sheet(w, h, draw, path):
        im = Image.new("RGBA", (w * 4, h), (0, 0, 0, 0))
        for f in range(4):
            fr = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            draw(ImageDraw.Draw(fr), f)
            im.alpha_composite(fr, (f * w, 0))
        im.save(out(path))

    def quad(body, light, dark, belly=None, legs=None, w=24, h=16, head=None):
        """Quadrúpede de perfil: corpo oval, 4 pernas que alternam, cabeça à direita."""
        legs = legs or dark
        def draw(d, f):
            st = [0, 1, 0, -1][f]
            by = h - 7
            d.ellipse([3, h - 3, w - 3, h - 1], fill=SH)
            for i, lx in enumerate((5, 8, w - 9, w - 6)):
                k = st if i % 2 == 0 else -st
                d.rectangle([lx, by + 2, lx + 1, h - 2 - max(0, k)], fill=legs, outline=OL)
            d.ellipse([2, by - 6, w - 6, by + 4], fill=body, outline=OL)
            d.line([(6, by - 5), (w - 10, by - 5)], fill=light)
            if belly:
                d.line([(6, by + 2), (w - 10, by + 2)], fill=belly)
            else:
                d.line([(6, by + 2), (w - 10, by + 2)], fill=dark)
            head(d, by) if head else None
        return draw

    # capivara 24x16: corpo de barril, focinho quadrado
    CB, CL, CD = (158, 104, 64, 255), (190, 136, 90, 255), (114, 74, 46, 255)
    def cap_head(d, by):
        d.rounded_rectangle([15, by - 7, 23, by], 2, fill=CB, outline=OL)
        d.line([(16, by - 6), (21, by - 6)], fill=CL)
        d.point((19, by - 5), fill=OL)
        d.point((17, by - 8), fill=OL)
        d.point((23, by - 3), fill=OL)
    sheet(24, 16, quad(CB, CL, CD, head=cap_head), "assets/animals/capivara_placeholder.png")

    # javali 24x16: escuro, crina, presa branca
    JB, JL, JD = (88, 70, 60, 255), (122, 100, 86, 255), (58, 46, 40, 255)
    def jav_head(d, by):
        d.polygon([(15, by - 6), (22, by - 3), (23, by), (16, by + 1)], fill=JB, outline=OL)
        d.rectangle([21, by - 2, 23, by], fill=(190, 150, 140, 255), outline=OL)
        d.point((18, by - 4), fill=OL)
        d.line([(20, by + 1), (21, by - 1)], fill=(244, 240, 230, 255))
        for x in range(5, 15, 3):
            d.line([(x, by - 6), (x + 1, by - 8)], fill=OL)
    sheet(24, 16, quad(JB, JL, JD, head=jav_head), "assets/animals/javali_placeholder.png")

    # veado-campeiro 24x24: pernas finas compridas, chifrinho
    VB, VL, VD, VW = (196, 130, 66, 255), (226, 166, 96, 255), (150, 94, 44, 255), (246, 232, 206, 255)
    def veado(d, f):
        st = [0, 2, 0, -2][f]
        d.ellipse([4, 21, 20, 23], fill=SH)
        for i, lx in enumerate((6, 9, 15, 18)):
            k = st if i % 2 == 0 else -st
            d.line([(lx, 13), (lx + k // 2, 22)], fill=OL, width=2)
            d.point((lx + k // 2, 21), fill=VD)
        d.ellipse([3, 7, 19, 15], fill=VB, outline=OL)
        d.line([(6, 8), (15, 8)], fill=VL)
        d.line([(6, 14), (14, 14)], fill=VW)
        d.polygon([(16, 9), (18, 3), (21, 3), (23, 7), (20, 9)], fill=VB, outline=OL)
        d.line([(18, 3), (17, 0)], fill=OL)
        d.line([(19, 2), (20, 0)], fill=OL)
        d.point((20, 5), fill=OL)
        d.point((2, 8), fill=VW)
    sheet(24, 24, veado, "assets/animals/veado_placeholder.png")

    # cutia 16x12: pequena, laranja, perninhas
    UB, UL, UD = (204, 128, 56, 255), (232, 164, 86, 255), (150, 88, 36, 255)
    def cutia(d, f):
        hop = 1 if f in (1, 3) else 0
        d.ellipse([3, 9, 13, 11], fill=SH)
        d.line([(5, 9 - hop), (5, 11)], fill=OL)
        d.line([(10, 9 - hop), (10, 11)], fill=OL)
        d.ellipse([2, 3 - hop, 12, 10 - hop], fill=UB, outline=OL)
        d.line([(4, 4 - hop), (9, 4 - hop)], fill=UL)
        d.ellipse([9, 2 - hop, 15, 8 - hop], fill=UB, outline=OL)
        d.point((12, 4 - hop), fill=OL)
        d.point((11, 1 - hop), fill=OL)
        d.point((15, 6 - hop), fill=OL)
        d.line([(3, 9 - hop), (9, 9 - hop)], fill=UD)
    sheet(16, 12, cutia, "assets/animals/cutia_placeholder.png")

    # quati 20x14: rabo listrado em pé, focinho comprido
    QB, QL, QD = (150, 104, 66, 255), (184, 138, 96, 255), (96, 64, 42, 255)
    def quati(d, f):
        st = [0, 1, 0, -1][f]
        d.ellipse([3, 11, 17, 13], fill=SH)
        for i, lx in enumerate((6, 9, 12, 14)):
            k = st if i % 2 == 0 else -st
            d.line([(lx, 9), (lx, 12 - max(0, k))], fill=OL, width=2)
        for i, (x, y) in enumerate([(4, 7), (3, 5), (2, 3), (2, 1)]):
            d.rectangle([x - 1, y - 1, x + 1, y], fill=QL if i % 2 == 0 else QD, outline=OL)
        d.ellipse([4, 4, 15, 11], fill=QB, outline=OL)
        d.line([(7, 5), (12, 5)], fill=QL)
        d.polygon([(13, 5), (16, 4), (20, 8), (15, 9)], fill=QB, outline=OL)
        d.point((16, 6), fill=OL)
        d.line([(15, 7), (17, 7)], fill=(240, 226, 200, 255))
    sheet(20, 14, quati, "assets/animals/quati_placeholder.png")

    # seriema 16x24: ave alta cinza, topete, bico e pernas vermelhas
    SB, SL, SD, SR = (176, 170, 156, 255), (214, 208, 196, 255), (128, 122, 112, 255), (214, 66, 52, 255)
    def seriema(d, f):
        st = [0, 2, 0, -2][f]
        d.ellipse([3, 21, 13, 23], fill=SH)
        d.line([(7, 15), (7 + st // 2, 22)], fill=SR)
        d.line([(9, 15), (9 - st // 2, 22)], fill=SR)
        d.polygon([(1, 10), (4, 9), (3, 13)], fill=SD, outline=OL)
        d.ellipse([3, 8, 12, 16], fill=SB, outline=OL)
        d.line([(5, 9), (10, 9)], fill=SL)
        d.line([(10, 9), (11, 4)], fill=OL, width=3)
        d.line([(10, 9), (11, 4)], fill=SB)
        d.ellipse([9, 1, 14, 6], fill=SB, outline=OL)
        d.line([(10, 1), (9, -1)], fill=OL)
        d.point((12, 3), fill=SR)
        d.line([(14, 4), (16, 5)], fill=SR)
    sheet(16, 24, seriema, "assets/animals/seriema_placeholder.png")

    # ema 24x32: grande, corpo de penas, pescoço longo
    EB, EL, ED = (132, 122, 108, 255), (168, 158, 142, 255), (96, 88, 78, 255)
    def ema(d, f):
        st = [0, 3, 0, -3][f]
        d.ellipse([5, 29, 19, 31], fill=SH)
        for lx, k in ((9, st), (13, -st)):
            d.line([(lx, 19), (lx + k // 2, 30)], fill=OL, width=2)
            d.point((lx + k // 2, 29), fill=(200, 170, 90, 255))
        d.ellipse([2, 10, 20, 21], fill=EB, outline=OL)
        for x in range(4, 18, 3):
            d.line([(x, 12), (x + 1, 19)], fill=ED)
        d.line([(5, 11), (15, 11)], fill=EL)
        d.line([(17, 13), (19, 3)], fill=OL, width=3)
        d.line([(17, 13), (19, 3)], fill=EL)
        d.ellipse([17, 0, 22, 5], fill=EB, outline=OL)
        d.point((20, 2), fill=OL)
        d.line([(22, 3), (23, 3)], fill=(60, 50, 44, 255))
    sheet(24, 32, ema, "assets/animals/ema_placeholder.png")

    # --- chefes ---
    L, M, D = (186, 172, 220, 255), (128, 112, 170, 255), (78, 64, 112, 255)
    CR, CRL = (150, 230, 255, 255), (235, 252, 255, 255)
    GLOW = (170, 245, 255, 255)

    def guardiao(d, f):  # 40x40: golem de pedra com cristais
        b = [0, 1, 0, 1][f]
        d.ellipse([4, 35, 36, 39], fill=SH)
        d.rectangle([9, 28, 15, 37], fill=D, outline=OL)
        d.rectangle([25, 28, 31, 37], fill=D, outline=OL)
        d.polygon([(4, 12 + b), (8, 6 + b), (32, 6 + b), (36, 12 + b), (34, 30 + b), (6, 30 + b)], fill=M, outline=OL)
        d.line([(9, 8 + b), (31, 8 + b)], fill=L)
        d.line([(7, 28 + b), (33, 28 + b)], fill=D)
        d.rectangle([0, 14 + b, 5, 26 + b], fill=M, outline=OL)
        d.rectangle([35, 14 + b, 40, 26 + b], fill=M, outline=OL)
        for (x, y, h) in [(12, 6, 6), (20, 5, 8), (28, 6, 5)]:
            d.polygon([(x - 2, y + b), (x, y - h + b), (x + 2, y + b)], fill=CR, outline=OL)
            d.line([(x, y - h + 2 + b), (x, y - 1 + b)], fill=CRL)
        d.rectangle([13, 14 + b, 16, 16 + b], fill=GLOW)
        d.rectangle([24, 14 + b, 27, 16 + b], fill=GLOW)
        d.line([(15, 22 + b), (25, 22 + b)], fill=OL)
        d.polygon([(18, 24 + b), (20, 21 + b), (22, 24 + b), (20, 27 + b)], fill=CR if f % 2 == 0 else CRL, outline=OL)

    def eco(d, f):  # 32x40: vulto de manto que ondula, sem rosto
        w = [0, 1, 2, 1][f]
        d.ellipse([4, 36, 28, 39], fill=SH)
        d.polygon([(16, 2), (24, 10), (27, 36 - w), (22, 33 + w), (16, 36 - w), (10, 33 + w), (5, 36 - w), (8, 10)],
                  fill=(64, 56, 84, 255), outline=OL)
        d.line([(11, 12), (9, 32)], fill=(96, 86, 122, 255))
        d.line([(21, 12), (23, 32)], fill=(44, 38, 60, 255))
        d.ellipse([10, 7, 22, 18], fill=(30, 26, 40, 255), outline=OL)
        d.point((13, 12), fill=GLOW)
        d.point((19, 12), fill=GLOW)
        for i in range(3):
            y = 20 + i * 4
            d.arc([4 - w, y - 3, 28 + w, y + 3], 200, 340, fill=(170, 160, 210, 140))
    sheet(40, 40, guardiao, "assets/enemies/guardiao_cristal_placeholder.png")
    sheet(32, 40, eco, "assets/enemies/eco_silencio_placeholder.png")


def construcoes():
    """Peças do modo construção: caminhos (16x16), cerca de espinhos e totem de proteção."""
    tiles = Image.open(out("assets/tilesets/farm_tiles_placeholder.png")).convert("RGBA")

    def from_tile(col):
        return tiles.crop((col * 16, 0, col * 16 + 16, 16))

    def borda(t, dark):
        d = ImageDraw.Draw(t)
        for x in range(16):
            for y in (0, 15):
                if (x + y) % 3:
                    d.point((x, y), fill=dark)
        for y in range(16):
            for x in (0, 15):
                if (x + y) % 3:
                    d.point((x, y), fill=dark)
        return t

    borda(from_tile(3), (120, 66, 40, 255)).save(out("assets/environments/caminho_terra_placeholder.png"))
    borda(from_tile(8), (110, 100, 86, 255)).save(out("assets/environments/caminho_pedra_placeholder.png"))
    from_tile(9).save(out("assets/environments/caminho_madeira_placeholder.png"))

    WOOD, WOOD_D = (150, 96, 56, 255), (100, 62, 38, 255)
    SIL, GLOW = (128, 112, 170, 255), (170, 245, 255, 255)
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([1, 4, 3, 15], fill=WOOD, outline=OL)
    d.rectangle([12, 4, 14, 15], fill=WOOD, outline=OL)
    d.line([(3, 8), (12, 8)], fill=OL, width=3)
    d.line([(3, 8), (12, 8)], fill=WOOD_D)
    for x in range(4, 12, 2):
        d.line([(x, 7), (x + 1, 4)], fill=SIL)
        d.point((x + 1, 4), fill=GLOW)
        d.line([(x, 9), (x + 1, 12)], fill=SIL)
    im.save(out("assets/environments/cerca_espinhos_placeholder.png"))

    STONE, STONE_D, STONE_L = (150, 148, 140, 255), (100, 98, 94, 255), (190, 188, 180, 255)
    CR, CRL = (150, 230, 255, 255), (235, 252, 255, 255)
    im = Image.new("RGBA", (16, 28), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([1, 24, 15, 27], fill=(0, 0, 0, 60))
    d.rectangle([2, 18, 13, 25], fill=STONE, outline=OL)
    d.line([(3, 19), (12, 19)], fill=STONE_L)
    d.rectangle([4, 10, 11, 18], fill=STONE_D, outline=OL)
    d.polygon([(8, 0), (12, 6), (8, 11), (4, 6)], fill=CR, outline=OL)
    d.line([(8, 2), (6, 6)], fill=CRL)
    d.point((7, 14), fill=GLOW); d.point((8, 14), fill=GLOW)
    im.save(out("assets/environments/totem_protecao_placeholder.png"))


if __name__ == "__main__":
    fauna()
    inimigos()
    livestock()
    debris()
    tiles()
    player()
    npcs()
    trees()
    construcoes()
    print("Arte Ninja Adventure (etapa 1) aplicada.")
