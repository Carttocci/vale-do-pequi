"""
Gera os assets PROVISÓRIOS da Fase 1 do Vale do Pequi.

Tudo aqui é placeholder procedural, para destravar o desenvolvimento.
Os arquivos gerados levam o sufixo _placeholder e devem ser substituídos
pela arte final (ver documentation/assets_provisorios.md).

Uso:  python3 tools/gerar_assets_provisorios.py   (na raiz do projeto)
Requer: Pillow
"""
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = 16  # tamanho do tile

# Paleta (GDD §3.1)
C = {
    "outline": (38, 30, 28, 255),
    "grass": (104, 128, 58, 255),       # verde-oliva
    "grass_l": (128, 150, 70, 255),
    "grass_d": (74, 98, 44, 255),       # verde-escuro
    "dry": (196, 160, 72, 255),         # vegetação seca / capim-dourado
    "dry_l": (222, 190, 96, 255),
    "dry_d": (160, 124, 52, 255),
    "earth": (166, 74, 46, 255),        # vermelho-terra
    "earth_l": (188, 96, 60, 255),
    "earth_d": (130, 56, 36, 255),
    "ocre": (184, 120, 56, 255),
    "soil": (110, 58, 38, 255),
    "soil_d": (84, 42, 28, 255),
    "water": (58, 120, 160, 255),
    "water_l": (92, 168, 176, 255),     # verde-água
    "water_d": (40, 88, 126, 255),
    "pequi": (246, 196, 28, 255),
    "pequi_g": (110, 140, 50, 255),
    "wood": (124, 82, 48, 255),
    "wood_d": (88, 56, 34, 255),
    "wood_l": (156, 110, 66, 255),
    "terracota": (178, 84, 52, 255),
    "terracota_d": (138, 60, 40, 255),
    "bege": (226, 206, 168, 255),
    "bege_d": (194, 170, 130, 255),
    "ipe": (250, 206, 40, 255),
    "ipe_d": (214, 160, 24, 255),
    "skin": (198, 140, 100, 255),
    "skin_d": (160, 104, 72, 255),
    "hat": (226, 196, 110, 255),
    "hat_d": (180, 148, 72, 255),
    "shirt": (176, 52, 48, 255),
    "shirt_d": (130, 36, 36, 255),
    "jeans": (62, 88, 140, 255),
    "jeans_d": (44, 62, 104, 255),
    "boot": (92, 60, 40, 255),
    "hair": (56, 38, 30, 255),
    "stone": (140, 136, 128, 255),
    "stone_d": (100, 96, 92, 255),
    "white": (240, 236, 224, 255),
}


def out(path):
    full = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    return full


def speckle(d, x0, y0, w, h, colors, n, rng):
    for _ in range(n):
        d.point((x0 + rng.randrange(w), y0 + rng.randrange(h)), fill=rng.choice(colors))


# ---------------------------------------------------------------- tileset
def make_tileset():
    """Atlas 8x1 de tiles 16x16. A ordem é usada por scripts/world/farm_ground.gd."""
    rng = random.Random(7)
    names = ["grama", "grama_flor", "capim_seco", "terra_vermelha", "terra_arada", "agua", "grama_escura", "agua_borda"]
    img = Image.new("RGBA", (T * len(names), T), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def base(i, col):
        d.rectangle([i * T, 0, i * T + T - 1, T - 1], fill=col)

    # 0 grama
    base(0, C["grass"]); speckle(d, 0, 0, T, T, [C["grass_l"], C["grass_d"]], 26, rng)
    # 1 grama com florzinhas
    base(1, C["grass"]); speckle(d, T, 0, T, T, [C["grass_l"], C["grass_d"]], 22, rng)
    for (x, y, c) in [(3, 4, "ipe"), (11, 9, "white"), (7, 13, "ipe"), (13, 3, "white")]:
        d.point((T + x, y), fill=C[c])
    # 2 capim seco / dourado
    base(2, C["dry"])
    for _ in range(14):
        x = rng.randrange(T); y = rng.randrange(4, T)
        d.line([(2 * T + x, y), (2 * T + x, y - 3)], fill=rng.choice([C["dry_l"], C["dry_d"]]))
    # 3 terra vermelha (estrada)
    base(3, C["earth"]); speckle(d, 3 * T, 0, T, T, [C["earth_l"], C["earth_d"], C["ocre"]], 30, rng)
    # 4 terra arada
    base(4, C["soil"])
    for y in range(1, T, 4):
        d.line([(4 * T, y), (4 * T + T - 1, y)], fill=C["soil_d"])
    # 5 água
    base(5, C["water"])
    for _ in range(4):
        x = rng.randrange(1, T - 5); y = rng.randrange(1, T - 1)
        d.line([(5 * T + x, y), (5 * T + x + 3, y)], fill=C["water_l"])
    speckle(d, 5 * T, 0, T, T, [C["water_d"]], 8, rng)
    # 6 grama escura (mata)
    base(6, C["grass_d"]); speckle(d, 6 * T, 0, T, T, [C["grass"], (60, 80, 36, 255)], 26, rng)
    # 7 água com borda (margem)
    base(7, C["water"])
    d.rectangle([7 * T, 0, 7 * T + T - 1, 2], fill=C["earth_d"])
    d.line([(7 * T, 3), (7 * T + T - 1, 3)], fill=C["water_l"])
    img.save(out("assets/tilesets/farm_tiles_placeholder.png"))


# ---------------------------------------------------------------- personagem
DIRS = [(0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (-1, 1)]  # S, SE, E, NE, N, NW, W, SW


def draw_player(d, ox, oy, dx, dy, frame):
    """Desenha um frame 32x32 do jogador. Origem lógica: pés em (16, 30)."""
    o = C["outline"]
    walking = frame in (1, 3)
    bob = -1 if walking else 0
    cx = ox + 16
    side = dx != 0 and dy == 0
    back = dy < 0

    # sombra
    d.ellipse([cx - 7, oy + 27, cx + 7, oy + 31], fill=(0, 0, 0, 70))

    # pernas
    if side:
        a = 2 if frame == 1 else (-2 if frame == 3 else 0)
        d.rectangle([cx - 2 + a, oy + 22 + bob, cx + 1 + a, oy + 28], fill=C["jeans"], outline=o)
        d.rectangle([cx - 2 - a, oy + 22 + bob, cx + 1 - a, oy + 28], fill=C["jeans_d"], outline=o)
        d.rectangle([cx - 2 + a, oy + 27, cx + 2 + a, oy + 29], fill=C["boot"])
    else:
        l = -1 if frame == 1 else 0
        r = -1 if frame == 3 else 0
        d.rectangle([cx - 5, oy + 22 + bob, cx - 1, oy + 28 + l], fill=C["jeans"], outline=o)
        d.rectangle([cx + 1, oy + 22 + bob, cx + 5, oy + 28 + r], fill=C["jeans"], outline=o)
        d.rectangle([cx - 5, oy + 27 + l, cx - 1, oy + 29 + l], fill=C["boot"])
        d.rectangle([cx + 1, oy + 27 + r, cx + 5, oy + 29 + r], fill=C["boot"])

    # tronco (camisa xadrez simplificada)
    tw = 5 if side else 7
    d.rectangle([cx - tw, oy + 13 + bob, cx + tw, oy + 23 + bob], fill=C["shirt"], outline=o)
    for yy in range(oy + 15 + bob, oy + 23 + bob, 3):
        d.line([(cx - tw + 1, yy), (cx + tw - 1, yy)], fill=C["shirt_d"])
    # braços
    swing = 1 if frame == 1 else (-1 if frame == 3 else 0)
    if side:
        ax = cx - dx * 1
        d.rectangle([ax - 1, oy + 14 + bob + swing, ax + 2, oy + 21 + bob + swing], fill=C["shirt_d"], outline=o)
    else:
        d.rectangle([cx - tw - 2, oy + 14 + bob + swing, cx - tw, oy + 21 + bob + swing], fill=C["shirt_d"], outline=o)
        d.rectangle([cx + tw, oy + 14 + bob - swing, cx + tw + 2, oy + 21 + bob - swing], fill=C["shirt_d"], outline=o)

    # cabeça
    d.rectangle([cx - 5, oy + 6 + bob, cx + 5, oy + 14 + bob], fill=C["hair"] if back else C["skin"], outline=o)
    if not back:
        ex = dx * 2
        if side:
            d.point((cx + dx * 3, oy + 10 + bob), fill=o)
        else:
            d.point((cx - 2 + ex, oy + 10 + bob), fill=o)
            d.point((cx + 2 + ex, oy + 10 + bob), fill=o)
        d.line([(cx - 5, oy + 13 + bob), (cx + 5, oy + 13 + bob)], fill=C["skin_d"])

    # chapéu de palha
    d.ellipse([cx - 9, oy + 4 + bob, cx + 9, oy + 9 + bob], fill=C["hat"], outline=o)
    d.rectangle([cx - 5, oy + 1 + bob, cx + 5, oy + 6 + bob], fill=C["hat"], outline=o)
    d.line([(cx - 4, oy + 5 + bob), (cx + 4, oy + 5 + bob)], fill=C["terracota_d"])  # fita
    d.point((cx - 2, oy + 3 + bob), fill=C["hat_d"])


def make_player():
    """Spritesheet 4 colunas (frames de caminhada) x 8 linhas (direções S,SE,E,NE,N,NW,W,SW)."""
    img = Image.new("RGBA", (32 * 4, 32 * 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for row, (dx, dy) in enumerate(DIRS):
        for f in range(4):
            draw_player(d, f * 32, row * 32, dx, dy, f)
    img.save(out("assets/characters/player_placeholder.png"))


# ---------------------------------------------------------------- objetos
def make_tree(path, crown, crown_d, fruit=None, seed=1):
    rng = random.Random(seed)
    img = Image.new("RGBA", (40, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = C["outline"]
    d.ellipse([10, 42, 30, 47], fill=(0, 0, 0, 70))
    # tronco retorcido (típico do Cerrado)
    d.polygon([(17, 45), (23, 45), (22, 34), (26, 26), (23, 25), (20, 31), (17, 25), (14, 27), (18, 34)], fill=C["wood"], outline=o)
    d.line([(19, 44), (19, 36)], fill=C["wood_d"])
    # copa
    for (x0, y0, x1, y1) in [(2, 8, 22, 28), (16, 4, 38, 26), (8, 0, 30, 18)]:
        d.ellipse([x0, y0, x1, y1], fill=crown, outline=o)
    for (x0, y0, x1, y1) in [(4, 14, 18, 27), (20, 14, 36, 25)]:
        d.ellipse([x0, y0, x1, y1], fill=crown_d)
    speckle(d, 6, 4, 28, 20, [crown_d], 30, rng)
    if fruit:
        for (x, y) in [(9, 18), (27, 16), (17, 10), (31, 21), (13, 23)]:
            d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=fruit, outline=o)
    img.save(out(path))


def make_cupinzeiro():
    img = Image.new("RGBA", (20, 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = C["outline"]
    d.ellipse([2, 21, 18, 25], fill=(0, 0, 0, 70))
    d.polygon([(3, 23), (5, 12), (8, 4), (10, 1), (13, 5), (15, 13), (17, 23)], fill=C["earth"], outline=o)
    d.line([(9, 6), (8, 20)], fill=C["earth_d"])
    d.point((12, 12), fill=C["earth_l"]); d.point((7, 16), fill=C["earth_l"])
    d.ellipse([11, 15, 13, 17], fill=C["earth_d"])
    img.save(out("assets/environments/cupinzeiro_placeholder.png"))


def make_house():
    w, h = 96, 80
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = C["outline"]
    d.rectangle([4, 74, 92, 79], fill=(0, 0, 0, 60))
    # paredes (bege, rodapé terra)
    d.rectangle([8, 34, 88, 76], fill=C["bege"], outline=o)
    d.rectangle([9, 68, 87, 75], fill=C["ocre"])
    # telhado cerâmico
    d.polygon([(0, 38), (12, 6), (84, 6), (96, 38)], fill=C["terracota"], outline=o)
    for y in range(10, 38, 5):
        xl = 12 - (y - 6) * 12 / 32 + 2
        d.line([(xl, y), (w - xl, y)], fill=C["terracota_d"])
    for x in range(16, 84, 6):
        d.line([(x, 8), (x - 2, 36)], fill=C["terracota_d"])
    # porta e janelas (madeira)
    d.rectangle([42, 50, 54, 76], fill=C["wood"], outline=o)
    d.point((51, 63), fill=C["pequi"])
    for x0 in (18, 66):
        d.rectangle([x0, 46, x0 + 12, 58], fill=C["wood_d"], outline=o)
        d.line([(x0 + 6, 46), (x0 + 6, 58)], fill=C["wood_l"])
    # rachaduras (casa abandonada)
    d.line([(28, 40), (31, 45), (29, 50)], fill=C["bege_d"])
    d.line([(74, 62), (78, 66)], fill=C["bege_d"])
    img.save(out("assets/environments/casa_principal_placeholder.png"))


def make_well():
    img = Image.new("RGBA", (28, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = C["outline"]
    d.ellipse([2, 26, 26, 31], fill=(0, 0, 0, 70))
    d.line([(5, 4), (5, 22)], fill=C["wood_d"], width=2)
    d.line([(22, 4), (22, 22)], fill=C["wood_d"], width=2)
    d.polygon([(2, 6), (14, 0), (26, 6)], fill=C["terracota"], outline=o)
    d.line([(6, 9), (21, 9)], fill=C["wood"])
    d.line([(14, 9), (14, 14)], fill=C["stone_d"])
    d.rectangle([3, 17, 24, 28], fill=C["stone"], outline=o)
    d.ellipse([5, 15, 22, 21], fill=C["water_d"], outline=o)
    for x in (8, 14, 20):
        d.line([(x, 22), (x, 28)], fill=C["stone_d"])
    img.save(out("assets/environments/poco_placeholder.png"))


def make_fence():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = C["outline"]
    d.rectangle([0, 5, 15, 7], fill=C["wood_l"], outline=o)
    d.rectangle([0, 10, 15, 12], fill=C["wood_l"], outline=o)
    d.rectangle([6, 2, 9, 15], fill=C["wood"], outline=o)
    img.save(out("assets/environments/cerca_placeholder.png"))
    # trecho vertical: mourão com pontas de travessa
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([6, 0, 9, 15], fill=C["wood"], outline=o)
    d.line([(7, 2), (7, 13)], fill=C["wood_l"])
    img.save(out("assets/environments/cerca_vertical_placeholder.png"))


def make_sign():
    img = Image.new("RGBA", (20, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = C["outline"]
    d.ellipse([5, 18, 15, 21], fill=(0, 0, 0, 70))
    d.rectangle([9, 10, 11, 20], fill=C["wood_d"], outline=o)
    d.rectangle([1, 2, 19, 12], fill=C["wood_l"], outline=o)
    for y in (5, 8):
        d.line([(4, y), (16, y)], fill=C["wood_d"])
    img.save(out("assets/environments/placa_placeholder.png"))


def make_items():
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = C["outline"]
    d.ellipse([2, 3, 13, 14], fill=C["pequi_g"], outline=o)
    d.ellipse([5, 6, 10, 11], fill=C["pequi"])
    d.line([(8, 1), (8, 4)], fill=C["wood_d"])
    img.save(out("assets/items/pequi_placeholder.png"))
    # pequi caído no chão (8x8)
    img = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([0, 1, 7, 7], fill=C["pequi_g"], outline=o)
    d.point((3, 3), fill=C["pequi"]); d.point((4, 4), fill=C["pequi"])
    img.save(out("assets/items/pequi_chao_placeholder.png"))


def make_bush():
    rng = random.Random(3)
    img = Image.new("RGBA", (20, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = C["outline"]
    d.ellipse([2, 11, 18, 15], fill=(0, 0, 0, 60))
    d.ellipse([1, 3, 12, 13], fill=C["grass_d"], outline=o)
    d.ellipse([8, 2, 19, 13], fill=C["grass_d"], outline=o)
    speckle(d, 3, 4, 14, 8, [C["grass"], C["grass_l"]], 14, rng)
    img.save(out("assets/environments/arbusto_placeholder.png"))


def make_touch_ui():
    """Controles de toque: base/alavanca do analógico e botões redondos."""
    o = C["outline"]

    def circle(path, size, fill, ring, glyph=None):
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.ellipse([0, 0, size - 1, size - 1], fill=fill, outline=ring, width=2)
        if glyph:
            glyph(d, size)
        img.save(out(path))

    circle("assets/ui/touch_stick_base_placeholder.png", 64, (38, 30, 28, 90), (226, 206, 168, 150))
    circle("assets/ui/touch_stick_knob_placeholder.png", 28, (226, 206, 168, 200), o)

    def hand(d, s):  # "mão" simplificada = interagir
        c = s // 2
        d.rectangle([c - 6, c - 2, c + 6, c + 9], fill=C["bege"], outline=o)
        for i, h in enumerate([8, 11, 11, 9]):
            x = c - 6 + i * 3
            d.rectangle([x, c - 2 - h + 4, x + 2, c - 1], fill=C["bege"], outline=o)

    def pause(d, s):
        c = s // 2
        d.rectangle([c - 6, c - 7, c - 2, c + 7], fill=C["bege"], outline=o)
        d.rectangle([c + 2, c - 7, c + 6, c + 7], fill=C["bege"], outline=o)

    def full(d, s):
        c, k = s // 2, 7
        for sx, sy in [(-1, -1), (1, -1), (-1, 1), (1, 1)]:
            x, y = c + sx * k, c + sy * k
            d.line([(x, y), (x - sx * 4, y)], fill=C["bege"], width=2)
            d.line([(x, y), (x, y - sy * 4)], fill=C["bege"], width=2)

    circle("assets/ui/touch_btn_interact_placeholder.png", 44, (110, 140, 50, 190), (246, 196, 28, 230), hand)
    circle("assets/ui/touch_btn_interact_pressed_placeholder.png", 44, (246, 196, 28, 230), (110, 140, 50, 230), hand)
    circle("assets/ui/touch_btn_pause_placeholder.png", 26, (38, 30, 28, 150), (226, 206, 168, 180), pause)
    circle("assets/ui/touch_btn_fullscreen_placeholder.png", 26, (38, 30, 28, 150), (226, 206, 168, 180), full)


def make_farming():
    """Fase 2: solo, cursor, ferramentas, sementes, colheitas, estágios das plantas, baú."""
    o = C["outline"]
    rng = random.Random(21)

    # solo capinado: seco e molhado (2 tiles 16x16)
    img = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, (base, line) in enumerate([(C["soil"], C["soil_d"]), ((74, 40, 30, 255), (52, 28, 22, 255))]):
        d.rectangle([i * 16 + 1, 1, i * 16 + 14, 14], fill=base)
        d.rectangle([i * 16 + 1, 1, i * 16 + 14, 14], outline=line)
        for y in (4, 8, 12):
            d.line([(i * 16 + 3, y), (i * 16 + 12, y)], fill=line)
    img.save(out("assets/tilesets/soil_placeholder.png"))

    # cursor do tile-alvo
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for (x0, y0, dx, dy) in [(0, 0, 1, 1), (15, 0, -1, 1), (0, 15, 1, -1), (15, 15, -1, -1)]:
        d.line([(x0, y0), (x0 + dx * 4, y0)], fill=(255, 240, 200, 230))
        d.line([(x0, y0), (x0, y0 + dy * 4)], fill=(255, 240, 200, 230))
    img.save(out("assets/ui/tile_cursor_placeholder.png"))

    def icon(name, draw):
        im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        draw(ImageDraw.Draw(im))
        im.save(out(f"assets/items/{name}_placeholder.png"))

    def enxada(d):
        d.line([(3, 14), (11, 4)], fill=C["wood"], width=2)
        d.polygon([(9, 2), (14, 2), (14, 6), (11, 5)], fill=C["stone"], outline=o)
    def regador(d):
        d.rectangle([3, 6, 11, 13], fill=(70, 130, 150, 255), outline=o)
        d.line([(11, 8), (15, 4)], fill=(70, 130, 150, 255), width=2)
        d.arc([4, 2, 10, 9], 180, 360, fill=o)
    icon("enxada", enxada)
    icon("regador", regador)

    def pouch(color):
        def f(d):
            d.polygon([(4, 5), (12, 5), (14, 14), (2, 14)], fill=C["bege"], outline=o)
            d.rectangle([5, 3, 11, 5], fill=C["bege_d"], outline=o)
            d.ellipse([6, 8, 10, 12], fill=color, outline=o)
        return f
    crops = {
        "milho": (C["ipe"], (110, 150, 50, 255)),
        "feijao": ((120, 60, 40, 255), (90, 140, 60, 255)),
        "abobora": ((214, 120, 40, 255), (80, 130, 50, 255)),
        "mandioca": ((200, 150, 100, 255), (70, 120, 50, 255)),
    }
    for name, (fruit, leaf) in crops.items():
        icon(f"semente_{name}", pouch(fruit))

    # ícones das colheitas
    def milho(d):
        d.polygon([(5, 14), (8, 1), (11, 14)], fill=(110, 150, 50, 255), outline=o)
        d.ellipse([6, 3, 10, 12], fill=C["ipe"], outline=o)
    def feijao(d):
        for (x, y) in [(3, 8), (8, 5), (9, 10)]:
            d.ellipse([x, y, x + 5, y + 4], fill=(120, 60, 40, 255), outline=o)
    def abobora(d):
        d.ellipse([1, 4, 15, 15], fill=(214, 120, 40, 255), outline=o)
        d.line([(8, 5), (8, 14)], fill=(170, 90, 30, 255))
        d.rectangle([7, 1, 9, 4], fill=C["wood"])
    def mandioca(d):
        d.polygon([(2, 12), (12, 3), (14, 5), (5, 14)], fill=(160, 100, 60, 255), outline=o)
        d.line([(5, 11), (11, 5)], fill=C["bege"])
    for name, fn in [("milho", milho), ("feijao", feijao), ("abobora", abobora), ("mandioca", mandioca)]:
        icon(name, fn)

    # estágios (16x32, base em y=31): broto, jovem, crescendo, maduro(+ fruto)
    def stage_img(name, leaf, fruit, n_stages):
        for s in range(n_stages):
            im = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
            d = ImageDraw.Draw(im)
            h = [4, 9, 15, 20][min(s, 3)]
            if name == "milho":
                h = [4, 10, 18, 26][min(s, 3)]
            base = 30
            d.line([(8, base), (8, base - h)], fill=leaf, width=2)
            for k in range(1, s + 2):
                y = base - k * max(2, h // (s + 2))
                d.line([(8, y), (3, y - 3)], fill=leaf, width=1)
                d.line([(8, y), (13, y - 3)], fill=leaf, width=1)
            if s == n_stages - 1:  # maduro
                if name == "milho":
                    d.ellipse([9, base - 18, 13, base - 9], fill=C["ipe"], outline=o)
                elif name == "feijao":
                    for (x, y) in [(2, base - 10), (11, base - 13), (4, base - 16)]:
                        d.rectangle([x, y, x + 3, y + 2], fill=fruit, outline=o)
                elif name == "abobora":
                    d.ellipse([2, base - 8, 14, base + 1], fill=fruit, outline=o)
                elif name == "mandioca":
                    d.ellipse([3, base - 22, 13, base - 12], fill=leaf, outline=o)
                    d.line([(8, base), (5, base + 1)], fill=(160, 100, 60, 255), width=2)
            im.save(out(f"assets/crops/{name}_{s}_placeholder.png"))
    for name, (fruit, leaf) in crops.items():
        stage_img(name, leaf, fruit, 4)

    # baú
    img = Image.new("RGBA", (20, 18), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([2, 14, 18, 17], fill=(0, 0, 0, 70))
    d.rectangle([1, 6, 18, 15], fill=C["wood"], outline=o)
    d.rectangle([1, 2, 18, 7], fill=C["wood_l"], outline=o)
    d.line([(1, 10), (18, 10)], fill=C["wood_d"])
    d.rectangle([8, 6, 11, 10], fill=C["pequi"], outline=o)
    img.save(out("assets/environments/bau_placeholder.png"))

    # botão de toque da mochila
    def touch_btn(path, size, fill, ring, glyph):
        im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.ellipse([0, 0, size - 1, size - 1], fill=fill, outline=ring, width=2)
        glyph(d, size)
        im.save(out(path))
    def bag_glyph(d, s):
        c = s // 2
        d.rectangle([c - 6, c - 3, c + 6, c + 7], fill=C["bege"], outline=o)
        d.arc([c - 4, c - 8, c + 4, c - 1], 180, 360, fill=C["bege"], width=2)
    touch_btn("assets/ui/touch_btn_bag_placeholder.png", 26, (38, 30, 28, 150), (226, 206, 168, 180), bag_glyph)


def make_app_icons():
    """Ícones do app web/PWA (pequi sobre terra vermelha)."""
    for size in (144, 180, 512):
        img = Image.new("RGBA", (16, 16), C["grass"])
        d = ImageDraw.Draw(img)
        d.rectangle([0, 12, 15, 15], fill=C["earth"])
        d.ellipse([3, 2, 12, 11], fill=C["pequi_g"], outline=C["outline"])
        d.ellipse([5, 4, 10, 9], fill=C["pequi"])
        img.resize((size, size), Image.NEAREST).save(out(f"assets/ui/app_icon_{size}.png"))


if __name__ == "__main__":
    make_touch_ui()
    make_farming()
    make_app_icons()
    make_tileset()
    make_player()
    make_tree("assets/environments/pequizeiro_placeholder.png", (92, 130, 52, 255), (68, 100, 40, 255), fruit=C["pequi_g"], seed=11)
    make_tree("assets/environments/ipe_amarelo_placeholder.png", C["ipe"], C["ipe_d"], seed=12)
    make_cupinzeiro()
    make_house()
    make_well()
    make_fence()
    make_sign()
    make_items()
    make_bush()
    print("Assets provisórios gerados.")
