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


def _manual():
    """Arquivos desenhados à mão (Aseprite): listados em assets/arte_manual.txt, nunca sobrescritos."""
    f = os.path.join(ROOT, "assets", "arte_manual.txt")
    if not os.path.exists(f):
        return set()
    return {l.strip() for l in open(f, encoding="utf-8") if l.strip() and not l.startswith("#")}


def out(path):
    if path.replace("\\", "/") in _manual():
        import tempfile
        return os.path.join(tempfile.gettempdir(), "arte_manual_ignorada_" + os.path.basename(path))
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
    names = ["grama", "grama_flor", "capim_seco", "terra_vermelha", "terra_arada", "agua", "grama_escura", "agua_borda", "pedra", "ponte", "caverna", "rocha", "ruina"]
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
    # 8 calçamento de pedra (praça da vila)
    base(8, (170, 160, 146, 255))
    for (x0, y0, x1, y1) in [(0, 0, 7, 5), (8, 0, 15, 5), (0, 6, 4, 10), (5, 6, 11, 10), (12, 6, 15, 10), (0, 11, 7, 15), (8, 11, 15, 15)]:
        d.rectangle([8 * T + x0, y0, 8 * T + x1, y1], outline=(130, 122, 110, 255))
    speckle(d, 8 * T, 0, T, T, [(186, 176, 160, 255)], 10, rng)
    # 9 ponte de madeira (atravessa o rio)
    base(9, C["water"])
    d.rectangle([9 * T, 0, 9 * T + T - 1, T - 1], fill=C["wood_l"])
    for y in range(0, T, 4):
        d.line([(9 * T, y), (9 * T + T - 1, y)], fill=C["wood_d"])
    # 10 chão de caverna, 11 parede de rocha (sólida), 12 piso de ruína
    base(10, (74, 66, 62, 255)); speckle(d, 10 * T, 0, T, T, [(90, 82, 76, 255), (60, 54, 50, 255)], 24, rng)
    base(11, (52, 46, 48, 255))
    for (x0, y0, x1, y1) in [(0, 0, 9, 6), (10, 0, 15, 6), (0, 7, 5, 15), (6, 7, 15, 15)]:
        d.rectangle([11 * T + x0, y0, 11 * T + x1, y1], fill=(66, 60, 62, 255), outline=(36, 32, 34, 255))
    base(12, (150, 140, 120, 255))
    d.rectangle([12 * T, 0, 12 * T + T - 1, T - 1], outline=(110, 100, 86, 255))
    d.line([(12 * T + 3, 8), (12 * T + 12, 8)], fill=(120, 110, 150, 255))
    d.point((12 * T + 8, 4), fill=(120, 110, 150, 255))
    img.save(out("assets/tilesets/farm_tiles_placeholder.png"))


# ---------------------------------------------------------------- personagem
DIRS = [(0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (-1, 1)]  # S, SE, E, NE, N, NW, W, SW


PLAYER_LOOK = {"shirt": C["shirt"], "shirt_d": C["shirt_d"], "pants": C["jeans"], "pants_d": C["jeans_d"],
               "skin": C["skin"], "skin_d": C["skin_d"], "hair": C["hair"], "head": "palha", "apron": None,
               "plaid": True}


def draw_player(d, ox, oy, dx, dy, frame, look=None):
    """Desenha um frame 32x32 de uma pessoa (jogador ou morador).
    Origem lógica: pés em (16, 30). `look` muda cores, cabelo/chapéu e avental."""
    L = dict(PLAYER_LOOK)
    L.update(look or {})
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
        d.rectangle([cx - 2 + a, oy + 22 + bob, cx + 1 + a, oy + 28], fill=L["pants"], outline=o)
        d.rectangle([cx - 2 - a, oy + 22 + bob, cx + 1 - a, oy + 28], fill=L["pants_d"], outline=o)
        d.rectangle([cx - 2 + a, oy + 27, cx + 2 + a, oy + 29], fill=C["boot"])
    else:
        l = -1 if frame == 1 else 0
        r = -1 if frame == 3 else 0
        d.rectangle([cx - 5, oy + 22 + bob, cx - 1, oy + 28 + l], fill=L["pants"], outline=o)
        d.rectangle([cx + 1, oy + 22 + bob, cx + 5, oy + 28 + r], fill=L["pants"], outline=o)
        d.rectangle([cx - 5, oy + 27 + l, cx - 1, oy + 29 + l], fill=C["boot"])
        d.rectangle([cx + 1, oy + 27 + r, cx + 5, oy + 29 + r], fill=C["boot"])

    # tronco (camisa xadrez simplificada)
    tw = 5 if side else 7
    d.rectangle([cx - tw, oy + 13 + bob, cx + tw, oy + 23 + bob], fill=L["shirt"], outline=o)
    if L["plaid"]:
        for yy in range(oy + 15 + bob, oy + 23 + bob, 3):
            d.line([(cx - tw + 1, yy), (cx + tw - 1, yy)], fill=L["shirt_d"])
    if L["apron"] and not back:
        d.rectangle([cx - tw + 2, oy + 16 + bob, cx + tw - 2, oy + 24 + bob], fill=L["apron"], outline=o)
    # braços
    swing = 1 if frame == 1 else (-1 if frame == 3 else 0)
    if side:
        ax = cx - dx * 1
        d.rectangle([ax - 1, oy + 14 + bob + swing, ax + 2, oy + 21 + bob + swing], fill=L["shirt_d"], outline=o)
    else:
        d.rectangle([cx - tw - 2, oy + 14 + bob + swing, cx - tw, oy + 21 + bob + swing], fill=L["shirt_d"], outline=o)
        d.rectangle([cx + tw, oy + 14 + bob - swing, cx + tw + 2, oy + 21 + bob - swing], fill=L["shirt_d"], outline=o)

    # cabeça
    d.rectangle([cx - 5, oy + 6 + bob, cx + 5, oy + 14 + bob], fill=L["hair"] if back else L["skin"], outline=o)
    if not back:
        ex = dx * 2
        if side:
            d.point((cx + dx * 3, oy + 10 + bob), fill=o)
        else:
            d.point((cx - 2 + ex, oy + 10 + bob), fill=o)
            d.point((cx + 2 + ex, oy + 10 + bob), fill=o)
        d.line([(cx - 5, oy + 13 + bob), (cx + 5, oy + 13 + bob)], fill=L["skin_d"])

    # cabeça: chapéu de palha, boné, coque, rabo de cavalo ou cabelo curto
    head = L["head"]
    if head == "palha":
        d.ellipse([cx - 9, oy + 4 + bob, cx + 9, oy + 9 + bob], fill=C["hat"], outline=o)
        d.rectangle([cx - 5, oy + 1 + bob, cx + 5, oy + 6 + bob], fill=C["hat"], outline=o)
        d.line([(cx - 4, oy + 5 + bob), (cx + 4, oy + 5 + bob)], fill=C["terracota_d"])  # fita
        d.point((cx - 2, oy + 3 + bob), fill=C["hat_d"])
    elif head == "bone":
        d.rectangle([cx - 5, oy + 3 + bob, cx + 5, oy + 7 + bob], fill=L.get("cap", (60, 90, 150, 255)), outline=o)
        if not back:
            bx = cx + dx * 4
            d.rectangle([bx - 4, oy + 7 + bob, bx + 4, oy + 8 + bob], fill=L.get("cap", (60, 90, 150, 255)), outline=o)
    else:
        d.rectangle([cx - 6, oy + 4 + bob, cx + 6, oy + 8 + bob], fill=L["hair"], outline=o)
        if head == "coque":
            d.ellipse([cx - 3, oy + 0 + bob, cx + 3, oy + 5 + bob], fill=L["hair"], outline=o)
        elif head == "rabo":
            tx = cx - dx * 6 if dx else cx
            d.rectangle([tx - 2, oy + 7 + bob, tx + 2, oy + 15 + bob], fill=L["hair"], outline=o)
        elif head == "longo":
            d.rectangle([cx - 7, oy + 6 + bob, cx - 5, oy + 15 + bob], fill=L["hair"])
            d.rectangle([cx + 5, oy + 6 + bob, cx + 7, oy + 15 + bob], fill=L["hair"])


def make_player(path="assets/characters/player_placeholder.png", look=None):
    """Spritesheet 4 colunas (frames de caminhada) x 8 linhas (direções S,SE,E,NE,N,NW,W,SW)."""
    img = Image.new("RGBA", (32 * 4, 32 * 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for row, (dx, dy) in enumerate(DIRS):
        for f in range(4):
            draw_player(d, f * 32, row * 32, dx, dy, f, look)
    img.save(out(path))


NPC_LOOKS = {
    # Helena, comerciante: cabelo preso, blusa verde-água, avental de mercearia
    "helena": {"shirt": (60, 150, 140, 255), "shirt_d": (40, 110, 104, 255), "pants": (90, 60, 50, 255),
               "pants_d": (70, 46, 38, 255), "skin": (170, 112, 80, 255), "skin_d": (140, 88, 62, 255),
               "hair": (40, 26, 20, 255), "head": "coque", "apron": (226, 206, 168, 255), "plaid": False},
    # Seu Benedito, agricultor: chapéu de palha, camisa azul xadrez, calça cáqui
    "benedito": {"shirt": (70, 100, 160, 255), "shirt_d": (50, 74, 120, 255), "pants": (150, 130, 90, 255),
                 "pants_d": (120, 104, 70, 255), "skin": (150, 98, 70, 255), "skin_d": (120, 78, 54, 255),
                 "hair": (200, 200, 200, 255), "head": "palha"},
    # Toninho, ferreiro: cabelo curto, camiseta cinza, avental de couro
    "toninho": {"shirt": (120, 120, 120, 255), "shirt_d": (90, 90, 90, 255), "pants": (60, 60, 70, 255),
                "pants_d": (44, 44, 52, 255), "skin": (120, 78, 54, 255), "skin_d": (96, 60, 42, 255),
                "hair": (30, 24, 20, 255), "head": "curto", "apron": (110, 70, 40, 255), "plaid": False},
    # Dona Alzira, cozinheira: coque grisalho, vestido vermelho, avental branco
    "alzira": {"shirt": (170, 50, 60, 255), "shirt_d": (130, 36, 44, 255), "pants": (170, 50, 60, 255),
               "pants_d": (130, 36, 44, 255), "skin": (210, 160, 120, 255), "skin_d": (180, 130, 96, 255),
               "hair": (180, 180, 186, 255), "head": "coque", "apron": (240, 236, 224, 255), "plaid": False},
    # Mariana, veterinária: rabo de cavalo, jaleco branco, calça jeans
    "mariana": {"shirt": (236, 236, 236, 255), "shirt_d": (200, 200, 205, 255), "skin": (200, 150, 110, 255),
                "skin_d": (170, 120, 86, 255), "hair": (110, 60, 30, 255), "head": "rabo", "plaid": False},
    # João Pedro, pescador: boné, camiseta amarela, bermuda
    "joao_pedro": {"shirt": (220, 180, 50, 255), "shirt_d": (180, 140, 30, 255), "pants": (80, 110, 80, 255),
                   "pants_d": (60, 84, 60, 255), "skin": (140, 90, 60, 255), "skin_d": (110, 70, 46, 255),
                   "hair": (30, 24, 20, 255), "head": "bone", "cap": (200, 60, 50, 255), "plaid": False},
}


def make_npcs():
    for name, look in NPC_LOOKS.items():
        make_player(f"assets/npcs/{name}_placeholder.png", look)


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


def make_building(path, wall, wall_d, roof, roof_d, extras=None, door=None):
    """Prédio genérico da vila (96x80, mesma base/colisão da casa principal)."""
    w, h = 96, 80
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    o = C["outline"]
    d.rectangle([4, 74, 92, 79], fill=(0, 0, 0, 60))
    d.rectangle([8, 34, 88, 76], fill=wall, outline=o)
    d.rectangle([9, 68, 87, 75], fill=wall_d)
    d.polygon([(0, 38), (12, 6), (84, 6), (96, 38)], fill=roof, outline=o)
    for y in range(10, 38, 5):
        xl = 12 - (y - 6) * 12 / 32 + 2
        d.line([(xl, y), (w - xl, y)], fill=roof_d)
    d.rectangle([42, 50, 54, 76], fill=door or C["wood"], outline=o)
    for x0 in (18, 66):
        d.rectangle([x0, 46, x0 + 12, 58], fill=C["wood_d"], outline=o)
        d.line([(x0 + 6, 46), (x0 + 6, 58)], fill=C["wood_l"])
    if extras:
        extras(d)
    img.save(out(path))


def make_village():
    o = C["outline"]

    def toldo(d):  # mercearia: toldo listrado + placa
        for i, x in enumerate(range(10, 86, 8)):
            d.rectangle([x, 38, x + 7, 44], fill=(200, 60, 50, 255) if i % 2 == 0 else (240, 236, 224, 255), outline=o)
        d.rectangle([30, 26, 66, 34], fill=C["wood_l"], outline=o)
        d.rectangle([33, 29, 63, 31], fill=C["wood_d"])

    def ferraria(d):  # chaminé com fumaça + bigorna na placa
        d.rectangle([70, 0, 78, 14], fill=C["stone_d"], outline=o)
        d.ellipse([68, -6, 80, 4], fill=(150, 150, 150, 150))
        d.rectangle([28, 24, 50, 33], fill=C["wood_l"], outline=o)
        d.polygon([(33, 27), (45, 27), (43, 30), (35, 30)], fill=C["stone_d"])

    def bar(d):  # placa com caneca
        d.rectangle([30, 24, 66, 34], fill=C["wood_l"], outline=o)
        d.rectangle([44, 26, 50, 32], fill=C["ipe"], outline=o)
        d.rectangle([60, 60, 70, 70], fill=(120, 80, 40, 255), outline=o)  # barril

    def clinica(d):  # cruz verde
        d.rectangle([44, 24, 52, 34], fill=(70, 160, 90, 255))
        d.rectangle([40, 27, 56, 31], fill=(70, 160, 90, 255))

    make_building("assets/environments/mercearia_placeholder.png", (238, 220, 170, 255), (200, 170, 110, 255),
                  (60, 120, 100, 255), (40, 90, 76, 255), toldo)
    make_building("assets/environments/ferreiro_placeholder.png", (150, 130, 115, 255), (110, 95, 85, 255),
                  (90, 70, 60, 255), (66, 50, 42, 255), ferraria)
    make_building("assets/environments/bar_placeholder.png", (230, 190, 120, 255), (190, 150, 90, 255),
                  C["terracota"], C["terracota_d"], bar)
    make_building("assets/environments/clinica_placeholder.png", (220, 236, 230, 255), (180, 200, 196, 255),
                  (80, 120, 160, 255), (60, 92, 124, 255), clinica)
    make_building("assets/environments/casa_azul_placeholder.png", (150, 190, 220, 255), (110, 150, 180, 255),
                  C["terracota"], C["terracota_d"])
    make_building("assets/environments/casa_amarela_placeholder.png", (240, 210, 110, 255), (200, 170, 80, 255),
                  C["terracota"], C["terracota_d"])

    # igreja (96x112): fachada branca com torre e cruz
    w, h = 96, 112
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 106, 92, 111], fill=(0, 0, 0, 60))
    d.polygon([(4, 60), (20, 40), (76, 40), (92, 60)], fill=C["terracota"], outline=o)
    d.rectangle([8, 58, 88, 108], fill=(244, 240, 228, 255), outline=o)
    d.rectangle([9, 100, 87, 107], fill=(130, 160, 200, 255))  # barrado azul
    d.rectangle([36, 14, 60, 60], fill=(244, 240, 228, 255), outline=o)  # torre
    d.polygon([(34, 16), (48, 2), (62, 16)], fill=C["terracota"], outline=o)
    d.rectangle([47, -1, 49, 8], fill=C["ipe"])
    d.rectangle([44, 2, 52, 4], fill=C["ipe"])
    d.ellipse([42, 22, 54, 34], fill=(130, 160, 200, 255), outline=o)  # janela redonda
    d.rectangle([40, 78, 56, 108], fill=(110, 140, 190, 255), outline=o)  # porta azul
    d.polygon([(40, 78), (48, 70), (56, 78)], fill=(110, 140, 190, 255), outline=o)
    for x0 in (16, 70):
        d.rectangle([x0, 74, x0 + 10, 90], fill=(130, 160, 200, 255), outline=o)
    img.save(out("assets/environments/igreja_placeholder.png"))

    # cruzeiro da praça (24x40)
    img = Image.new("RGBA", (24, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([2, 33, 22, 39], fill=(0, 0, 0, 60))
    d.rectangle([4, 30, 20, 36], fill=C["stone"], outline=o)
    d.rectangle([10, 4, 14, 31], fill=C["wood"], outline=o)
    d.rectangle([5, 10, 19, 14], fill=C["wood"], outline=o)
    img.save(out("assets/environments/cruzeiro_placeholder.png"))

    # banco de praça (24x14)
    img = Image.new("RGBA", (24, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([1, 2, 22, 5], fill=C["wood_l"], outline=o)
    d.rectangle([1, 6, 22, 9], fill=C["wood"], outline=o)
    d.rectangle([3, 9, 5, 13], fill=C["stone_d"])
    d.rectangle([18, 9, 20, 13], fill=C["stone_d"])
    img.save(out("assets/environments/banco_placeholder.png"))


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
    def journal_glyph(d, s):
        c = s // 2
        d.rectangle([c - 6, c - 7, c + 6, c + 7], fill=(150, 70, 50), outline=o)
        d.rectangle([c - 4, c - 5, c + 5, c + 5], fill=C["bege"])
        for y in (c - 3, c, c + 3):
            d.line([(c - 2, y), (c + 3, y)], fill=(120, 100, 80))
    touch_btn("assets/ui/touch_btn_journal_placeholder.png", 26, (38, 30, 28, 150), (226, 206, 168, 180), journal_glyph)
    def attack_glyph(d, s):
        c = s // 2
        d.line([(c - 8, c + 8), (c + 7, c - 7)], fill=(220, 224, 232), width=3)
        d.line([(c + 4, c - 7), (c + 7, c - 7), (c + 7, c - 4)], fill=(250, 250, 255), width=1)
        d.line([(c - 9, c + 3), (c - 3, c + 9)], fill=(120, 80, 50), width=3)
        d.line([(c - 10, c + 10), (c - 7, c + 7)], fill=(120, 80, 50), width=3)
    touch_btn("assets/ui/touch_btn_attack_placeholder.png", 38, (120, 40, 36, 160), (240, 200, 180, 200), attack_glyph)
    def eat_glyph(d, s):
        c = s // 2
        d.ellipse([c - 7, c - 2, c + 7, c + 7], fill=(250, 244, 228), outline=o)
        d.ellipse([c - 5, c - 6, c + 5, c + 3], fill=(236, 200, 70), outline=o)
        d.point((c - 2, c - 3), fill=(255, 240, 160))
    touch_btn("assets/ui/touch_btn_eat_placeholder.png", 28, (38, 30, 28, 150), (226, 206, 168, 180), eat_glyph)
    def zoom_glyph(plus):
        def g(d, s):
            c = s // 2
            d.line([(c - 5, c), (c + 5, c)], fill=(240, 230, 210), width=2)
            if plus:
                d.line([(c, c - 5), (c, c + 5)], fill=(240, 230, 210), width=2)
        return g
    touch_btn("assets/ui/touch_btn_zoom_in_placeholder.png", 26, (38, 30, 28, 150), (226, 206, 168, 180), zoom_glyph(True))
    touch_btn("assets/ui/touch_btn_zoom_out_placeholder.png", 26, (38, 30, 28, 150), (226, 206, 168, 180), zoom_glyph(False))
    def map_glyph(d, s):
        c = s // 2
        pts = [(c - 8, c - 5), (c - 3, c - 7), (c + 3, c - 5), (c + 8, c - 7), (c + 8, c + 5), (c + 3, c + 7), (c - 3, c + 5), (c - 8, c + 7)]
        d.polygon(pts, fill=(222, 204, 160), outline=o)
        d.line([(c - 3, c - 7), (c - 3, c + 5)], fill=(170, 150, 110))
        d.line([(c + 3, c - 5), (c + 3, c + 7)], fill=(170, 150, 110))
        d.line([(c - 6, c + 2), (c - 1, c - 1), (c + 5, c + 1)], fill=(190, 70, 50))
        d.point((c + 5, c + 1), fill=(220, 40, 30))
    touch_btn("assets/ui/touch_btn_map_placeholder.png", 26, (38, 30, 28, 150), (226, 206, 168, 180), map_glyph)
    def build_glyph(d, s):
        c = s // 2
        d.line([(c - 6, c + 7), (c + 2, c - 1)], fill=(150, 96, 56), width=3)
        d.polygon([(c - 1, c - 7), (c + 6, c - 1), (c + 8, c - 3), (c + 1, c - 9)], fill=(196, 202, 214), outline=o)
    touch_btn("assets/ui/touch_btn_build_placeholder.png", 26, (38, 30, 28, 150), (226, 206, 168, 180), build_glyph)


def make_weather():
    """Fase 3: gota de chuva (partícula)."""
    img = Image.new("RGBA", (2, 7), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.line([(1, 0), (0, 6)], fill=(200, 220, 255, 200))
    img.save(out("assets/effects/gota_chuva_placeholder.png"))


def sheet(path, w, h, frames, draw):
    """Folha de animação: `frames` quadros lado a lado, virados para a direita."""
    img = Image.new("RGBA", (w * frames, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for f in range(frames):
        draw(d, f * w, f)
    img.save(out(path))


def make_fauna():
    """Fase 5: bichos do Cerrado, criação, itens de pesca/caça/criação."""
    o = C["outline"]

    def quad(body, belly, head_dx, w, h, leg_len, tail=None, extra=None):
        def draw(d, ox, f):
            by = h - leg_len - 2
            d.ellipse([ox + 1, h - 3, ox + w - 2, h - 1], fill=(0, 0, 0, 60))
            step = (f % 2) * 2 - 1
            for lx in (ox + 3, ox + w - 6):
                d.line([(lx + step, by + 2), (lx + step, h - 2)], fill=o, width=2)
            d.ellipse([ox + 1, by - (h - leg_len) // 2 + 1, ox + w - 4, by + 3], fill=body, outline=o)
            d.ellipse([ox + 4, by - 1, ox + w - 8, by + 2], fill=belly)
            hx = ox + w - 6 + head_dx
            d.ellipse([hx - 3, by - (h - leg_len) // 2 - 2, hx + 4, by - 1], fill=body, outline=o)
            d.point((hx + 2, by - (h - leg_len) // 2 + 1), fill=o)
            if tail:
                tail(d, ox, by)
            if extra:
                extra(d, ox, by)
        return draw

    sheet("assets/animals/capivara_placeholder.png", 24, 16, 4, quad((140, 100, 70, 255), (170, 130, 95, 255), 1, 24, 16, 3))
    sheet("assets/animals/cutia_placeholder.png", 16, 12, 4, quad((170, 110, 50, 255), (200, 150, 90, 255), 1, 16, 12, 3))
    sheet("assets/animals/quati_placeholder.png", 20, 14, 4, quad((150, 100, 60, 255), (190, 150, 110, 255), 2, 20, 14, 3,
          tail=lambda d, ox, by: [d.line([(ox + 1, by - 2), (ox - 1 + 0, by - 7)], fill=(90, 60, 40, 255), width=2)]))
    sheet("assets/animals/veado_placeholder.png", 24, 24, 4, quad((190, 130, 70, 255), (230, 200, 160, 255), 1, 24, 24, 8,
          extra=lambda d, ox, by: d.line([(ox + 20, by - 10), (ox + 22, by - 15)], fill=(90, 60, 40, 255))))
    sheet("assets/animals/javali_placeholder.png", 24, 16, 4, quad((70, 55, 45, 255), (100, 80, 64, 255), 2, 24, 16, 3,
          extra=lambda d, ox, by: d.point((ox + 22, by - 2), fill=C["white"])))
    sheet("assets/animals/vaca_placeholder.png", 32, 24, 4, quad((240, 236, 224, 255), (210, 200, 190, 255), 1, 32, 24, 6,
          extra=lambda d, ox, by: [d.ellipse([ox + 8, by - 8, ox + 15, by - 3], fill=(40, 30, 28, 255)),
                                   d.ellipse([ox + 18, by - 6, ox + 23, by - 1], fill=(40, 30, 28, 255))]))

    def bird(body, w, h, neck, leg):
        def draw(d, ox, f):
            d.ellipse([ox + 3, h - 3, ox + w - 3, h - 1], fill=(0, 0, 0, 60))
            step = (f % 2) * 2 - 1
            bx = ox + w // 2
            d.line([(bx - 1 + step, h - leg - 2), (bx - 1 + step, h - 2)], fill=(200, 150, 60, 255))
            d.line([(bx + 2 - step, h - leg - 2), (bx + 2 - step, h - 2)], fill=(200, 150, 60, 255))
            d.ellipse([ox + 2, h - leg - 9, ox + w - 4, h - leg - 1], fill=body, outline=o)
            d.line([(bx + 3, h - leg - 7), (bx + 4, h - leg - 7 - neck)], fill=body, width=2)
            d.ellipse([bx + 2, h - leg - 10 - neck, bx + 7, h - leg - 6 - neck], fill=body, outline=o)
            d.point((bx + 6, h - leg - 8 - neck), fill=(200, 60, 40, 255))
        return draw
    sheet("assets/animals/seriema_placeholder.png", 16, 24, 4, bird((180, 170, 150, 255), 16, 24, 5, 8))
    sheet("assets/animals/ema_placeholder.png", 24, 32, 4, bird((130, 120, 110, 255), 24, 32, 8, 12))
    sheet("assets/animals/galinha_placeholder.png", 16, 16, 4, bird((240, 236, 224, 255), 16, 16, 1, 4))

    def icon(name, draw):
        im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        draw(ImageDraw.Draw(im))
        im.save(out(f"assets/items/{name}_placeholder.png"))

    def fish(color, belly, size=1.0, fin=None):
        def f(d):
            w = int(12 * size)
            d.ellipse([8 - w // 2, 5, 8 + w // 2, 11], fill=color, outline=o)
            d.polygon([(8 - w // 2, 8), (8 - w // 2 - 3, 5), (8 - w // 2 - 3, 11)], fill=color, outline=o)
            d.line([(8 - w // 2 + 2, 9), (8 + w // 2 - 2, 9)], fill=belly)
            d.point((8 + w // 2 - 2, 7), fill=o)
            if fin:
                fin(d)
        return f
    icon("lambari", fish((180, 190, 200, 255), (230, 220, 160, 255), 0.7))
    icon("traira", fish((90, 90, 60, 255), (140, 130, 80, 255), 1.0))
    icon("piau", fish((160, 150, 120, 255), (200, 190, 140, 255), 0.9, lambda d: d.line([(6, 6), (10, 6)], fill=(60, 60, 60, 255))))
    icon("tucunare", fish((140, 170, 60, 255), (240, 200, 60, 255), 1.0, lambda d: d.ellipse([3, 6, 5, 8], fill=(40, 40, 40, 255))))
    icon("pacu", fish((120, 120, 130, 255), (220, 120, 60, 255), 1.0))
    icon("pintado", fish((150, 150, 160, 255), (220, 220, 220, 255), 1.2, lambda d: [d.point((5, 7), fill=o), d.point((8, 6), fill=o), d.point((10, 8), fill=o)]))
    icon("dourado", fish((240, 170, 40, 255), (250, 220, 120, 255), 1.1))
    icon("dourado_rei", fish((255, 210, 60, 255), (255, 250, 200, 255), 1.3, lambda d: d.polygon([(7, 2), (9, 2), (10, 5), (6, 5)], fill=C["pequi"], outline=o)))

    def vara(d):
        d.line([(2, 14), (13, 2)], fill=(170, 160, 90, 255), width=2)
        d.line([(13, 2), (14, 9)], fill=(220, 220, 220, 255))
    def isca(d):
        d.arc([3, 5, 13, 13], 200, 340, fill=(200, 110, 110, 255), width=2)
    def ovo(d):
        d.ellipse([4, 3, 12, 14], fill=(240, 226, 200, 255), outline=o)
    def leite(d):
        d.rectangle([4, 4, 12, 14], fill=C["white"], outline=o)
        d.rectangle([6, 1, 10, 4], fill=(120, 160, 200, 255), outline=o)
    def racao(d):
        d.polygon([(3, 5), (13, 5), (14, 14), (2, 14)], fill=(190, 160, 100, 255), outline=o)
        for (x, y) in [(6, 9), (9, 11), (10, 8)]:
            d.point((x, y), fill=C["ipe"])
    def carne(d):
        d.ellipse([2, 4, 13, 13], fill=(170, 60, 60, 255), outline=o)
        d.ellipse([9, 5, 13, 9], fill=C["white"])
    def couro(d):
        d.polygon([(2, 4), (14, 3), (12, 14), (3, 12)], fill=(150, 100, 60, 255), outline=o)
    def armadilha(d):
        d.rectangle([2, 5, 14, 14], fill=C["wood"], outline=o)
        for x in range(4, 14, 3):
            d.line([(x, 5), (x, 14)], fill=C["wood_d"])
    for n, fn in [("vara_bambu", vara), ("isca", isca), ("ovo", ovo), ("leite", leite), ("racao", racao),
                  ("carne_javali", carne), ("couro", couro), ("armadilha", armadilha)]:
        icon(n, fn)

    # mundo: galinheiro, comedouro, pegadas, armadilha armada, produto no chão
    img = Image.new("RGBA", (48, 44), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([2, 40, 46, 43], fill=(0, 0, 0, 60))
    d.rectangle([4, 18, 44, 41], fill=C["wood_l"], outline=o)
    for x in range(8, 44, 5):
        d.line([(x, 18), (x, 41)], fill=C["wood"])
    d.polygon([(0, 20), (8, 4), (40, 4), (48, 20)], fill=C["terracota"], outline=o)
    d.rectangle([20, 30, 28, 41], fill=C["wood_d"], outline=o)
    img.save(out("assets/environments/galinheiro_placeholder.png"))
    img = Image.new("RGBA", (20, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([1, 3, 18, 10], fill=C["wood"], outline=o)
    d.rectangle([3, 4, 16, 6], fill=(60, 40, 30, 255))
    img.save(out("assets/environments/comedouro_placeholder.png"))
    img = Image.new("RGBA", (20, 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([1, 3, 18, 10], fill=C["wood"], outline=o)
    d.rectangle([3, 4, 16, 6], fill=C["ipe_d"])
    img.save(out("assets/environments/comedouro_cheio_placeholder.png"))
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for (x, y) in [(3, 11), (6, 8), (9, 6), (12, 3)]:
        d.ellipse([x, y, x + 2, y + 3], fill=(90, 60, 40, 200))
    img.save(out("assets/environments/pegadas_placeholder.png"))
    img = Image.new("RGBA", (18, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rectangle([1, 2, 16, 12], fill=C["wood"], outline=o)
    for x in range(3, 16, 3):
        d.line([(x, 2), (x, 12)], fill=C["wood_d"])
    img.save(out("assets/environments/armadilha_armada_placeholder.png"))


def make_combat():
    """Fase 6: inimigos (criaturas corrompidas pelo Silêncio), armas, golpe."""
    o = C["outline"]
    sil = (120, 110, 150, 255)       # tom do Silêncio
    sil_d = (80, 72, 104, 255)
    glow = (190, 170, 255, 255)

    def raiz(d, ox, f):  # 20x24: tronco retorcido que anda
        step = (f % 2) * 2 - 1
        d.ellipse([ox + 3, 21, ox + 17, 23], fill=(0, 0, 0, 60))
        d.line([(ox + 6, 22), (ox + 5 + step, 15)], fill=C["wood_d"], width=2)
        d.line([(ox + 14, 22), (ox + 15 - step, 15)], fill=C["wood_d"], width=2)
        d.polygon([(ox + 4, 16), (ox + 7, 4), (ox + 13, 3), (ox + 16, 16)], fill=(100, 80, 70, 255), outline=o)
        d.line([(ox + 7, 6), (ox + 2, 1)], fill=C["wood_d"], width=2)
        d.line([(ox + 13, 5), (ox + 18, 0)], fill=C["wood_d"], width=2)
        d.point((ox + 8, 9), fill=glow)
        d.point((ox + 12, 9), fill=glow)
        d.line([(ox + 6, 12), (ox + 14, 12)], fill=sil_d)
    sheet("assets/enemies/raiz_torta_placeholder.png", 20, 24, 4, raiz)

    def lodo(d, ox, f):  # 16x12: gosma cinza que pula
        h = [0, 2, 3, 1][f]
        d.ellipse([ox + 2, 9, ox + 14, 11], fill=(0, 0, 0, 60))
        d.ellipse([ox + 1, 3 - h, ox + 15, 11 - h // 2], fill=sil, outline=o)
        d.ellipse([ox + 4, 4 - h, ox + 8, 6 - h], fill=(170, 160, 200, 255))
        d.point((ox + 6, 7 - h), fill=o)
        d.point((ox + 10, 7 - h), fill=o)
    sheet("assets/enemies/lodo_cinza_placeholder.png", 16, 12, 4, lodo)

    def morcego(d, ox, f):  # 16x12
        up = f % 2 == 0
        d.ellipse([ox + 6, 4, ox + 10, 9], fill=sil_d, outline=o)
        if up:
            d.polygon([(ox + 6, 6), (ox + 0, 1), (ox + 2, 7)], fill=sil, outline=o)
            d.polygon([(ox + 10, 6), (ox + 16, 1), (ox + 14, 7)], fill=sil, outline=o)
        else:
            d.polygon([(ox + 6, 6), (ox + 0, 10), (ox + 3, 6)], fill=sil, outline=o)
            d.polygon([(ox + 10, 6), (ox + 16, 10), (ox + 13, 6)], fill=sil, outline=o)
        d.point((ox + 7, 6), fill=glow)
        d.point((ox + 9, 6), fill=glow)
    sheet("assets/enemies/morcego_placeholder.png", 16, 12, 4, morcego)

    # javali corrompido: javali com tom do Silêncio
    base = Image.open(out("assets/animals/javali_placeholder.png")).convert("RGBA")
    px = base.load()
    for y in range(base.height):
        for x in range(base.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) != (38, 30, 28):
                px[x, y] = ((r + 90) // 2, (g + 80) // 2, (b + 140) // 2, a)
    base.save(out("assets/enemies/javali_corrompido_placeholder.png"))

    # golpe (arco branco) 24x24 apontando para a direita, e flecha
    img = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.arc([2, 2, 22, 22], -70, 70, fill=(255, 250, 230, 220), width=3)
    d.arc([5, 5, 19, 19], -50, 50, fill=(255, 250, 230, 120), width=1)
    img.save(out("assets/effects/golpe_placeholder.png"))
    img = Image.new("RGBA", (12, 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.line([(0, 2), (9, 2)], fill=C["wood_l"])
    d.polygon([(9, 0), (12, 2), (9, 4)], fill=C["stone"])
    d.point((0, 1), fill=C["white"]); d.point((0, 3), fill=C["white"])
    img.save(out("assets/effects/flecha_voo_placeholder.png"))

    def icon(name, draw):
        im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        draw(ImageDraw.Draw(im))
        im.save(out(f"assets/items/{name}_placeholder.png"))
    metal = (200, 205, 215, 255)
    def blade(length, width, handle=C["wood"]):
        def f(d):
            d.line([(2, 14), (5, 11)], fill=handle, width=2)
            d.line([(4, 10), (6, 12)], fill=C["stone_d"], width=1)
            d.line([(5, 11), (5 + length, 11 - length)], fill=metal, width=width)
            d.point((5 + length, 11 - length), fill=C["white"])
        return f
    icon("facao", blade(8, 2))
    icon("espada", blade(9, 2, (120, 60, 40, 255)))
    def machado(d):
        d.line([(3, 14), (11, 3)], fill=C["wood"], width=2)
        d.polygon([(8, 2), (14, 4), (12, 9), (9, 6)], fill=metal, outline=o)
    def lanca(d):
        d.line([(1, 15), (12, 4)], fill=C["wood_l"], width=1)
        d.polygon([(11, 3), (15, 0), (13, 5)], fill=metal, outline=o)
    def martelo(d):
        d.line([(4, 14), (9, 6)], fill=C["wood"], width=2)
        d.rectangle([6, 1, 14, 6], fill=C["stone_d"], outline=o)
    def arco(d):
        d.arc([3, 1, 13, 15], 270, 90, fill=C["wood"], width=2)
        d.line([(8, 1), (8, 15)], fill=C["white"])
    def flecha(d):
        d.line([(2, 14), (12, 4)], fill=C["wood_l"])
        d.polygon([(11, 3), (14, 2), (13, 5)], fill=C["stone"])
        d.line([(2, 13), (3, 15)], fill=C["white"])
    def madeira(d):
        d.rectangle([2, 6, 14, 11], fill=C["wood"], outline=o)
        d.ellipse([11, 6, 15, 11], fill=C["wood_l"], outline=o)
    def fragmento(d):
        d.polygon([(8, 1), (13, 7), (9, 15), (3, 9)], fill=sil, outline=o)
        d.line([(8, 3), (6, 9)], fill=glow)
    for n, fn in [("machado", machado), ("lanca", lanca), ("martelo", martelo), ("arco", arco), ("flecha", flecha),
                  ("madeira", madeira), ("fragmento_silencio", fragmento)]:
        icon(n, fn)

    # botão de toque: esquiva
    im = Image.new("RGBA", (30, 30), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([0, 0, 29, 29], fill=(60, 90, 140, 170), outline=(226, 206, 168, 200), width=2)
    for k in range(3):
        d.line([(8 + k * 5, 10), (13 + k * 5, 15), (8 + k * 5, 20)], fill=C["bege"], width=2)
    im.save(out("assets/ui/touch_btn_dodge_placeholder.png"))


def make_adventure():
    """Fase 7: mina, minérios, escadas, ruínas, chefes, Mãe-do-Ouro, mural de missões."""
    o = C["outline"]
    sil = (120, 110, 150, 255)
    glow = (190, 170, 255, 255)

    def icon(name, draw):
        im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        draw(ImageDraw.Draw(im))
        im.save(out(f"assets/items/{name}_placeholder.png"))

    def rock_icon(fill, spot=None):
        def f(d):
            d.polygon([(2, 12), (4, 5), (9, 2), (14, 6), (14, 13)], fill=fill, outline=o)
            if spot:
                for (x, y) in [(6, 7), (10, 9), (8, 11)]:
                    d.rectangle([x, y, x + 1, y + 1], fill=spot)
        return f
    icon("pedra", rock_icon(C["stone"]))
    icon("minerio_ferro", rock_icon(C["stone_d"], (170, 90, 60, 255)))
    icon("ouro", rock_icon((120, 100, 60, 255), (250, 210, 60, 255)))
    def quartzo(d):
        d.polygon([(5, 14), (6, 4), (8, 1), (10, 4), (11, 14)], fill=(230, 230, 240, 230), outline=o)
    def cristal(d):
        d.polygon([(4, 14), (5, 5), (8, 1), (11, 5), (12, 14)], fill=glow, outline=o)
        d.line([(8, 3), (7, 12)], fill=C["white"])
    def picareta(d):
        d.line([(4, 14), (9, 6)], fill=C["wood"], width=2)
        d.arc([2, 1, 15, 12], 200, 340, fill=(200, 205, 215, 255), width=2)
    def coracao(d):
        d.polygon([(8, 14), (2, 7), (4, 3), (8, 5), (12, 3), (14, 7)], fill=glow, outline=o)
    for n, fn in [("quartzo", quartzo), ("cristal_vale", cristal), ("picareta", picareta), ("coracao_cristal", coracao)]:
        icon(n, fn)

    def rock_world(name, fill, spot=None, size=(16, 14)):
        w, h = size
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.ellipse([1, h - 4, w - 2, h - 1], fill=(0, 0, 0, 60))
        d.polygon([(1, h - 3), (3, 4), (8, 1), (w - 2, 5), (w - 1, h - 3)], fill=fill, outline=o)
        if spot:
            for (x, y) in [(5, 6), (9, 8), (7, 10)]:
                d.rectangle([x, y, x + 1, y + 1], fill=spot)
        im.save(out(f"assets/environments/{name}_placeholder.png"))
    rock_world("rocha_pedra", C["stone"])
    rock_world("rocha_ferro", C["stone_d"], (170, 90, 60, 255))
    rock_world("rocha_quartzo", (120, 120, 130, 255), (235, 235, 245, 255))
    rock_world("rocha_ouro", (110, 95, 70, 255), (250, 210, 60, 255))
    rock_world("rocha_cristal", (80, 70, 110, 255), glow)
    rock_world("pedregulho", (130, 120, 110, 255), None, (16, 16))

    def simple(name, w, h, draw):
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw(ImageDraw.Draw(im))
        im.save(out(f"assets/environments/{name}_placeholder.png"))
    def escada_desce(d):
        d.rectangle([1, 1, 14, 14], fill=(20, 16, 18, 255), outline=o)
        for y in range(3, 14, 3):
            d.line([(4, y), (11, y)], fill=C["wood_l"])
        d.line([(4, 2), (4, 14)], fill=C["wood"]); d.line([(11, 2), (11, 14)], fill=C["wood"])
    def escada_sobe(d):
        d.line([(4, 0), (4, 15)], fill=C["wood"], width=2); d.line([(11, 0), (11, 15)], fill=C["wood"], width=2)
        for y in range(2, 16, 3):
            d.line([(4, y), (11, y)], fill=C["wood_l"])
    simple("escada_desce", 16, 16, escada_desce)
    simple("escada_sobe", 16, 16, escada_sobe)
    def boca_mina(d):
        d.polygon([(0, 40), (6, 6), (58, 6), (64, 40)], fill=(100, 92, 86, 255), outline=o)
        d.rectangle([20, 14, 44, 40], fill=(16, 12, 14, 255), outline=o)
        d.rectangle([18, 10, 46, 14], fill=C["wood"], outline=o)
        d.line([(20, 14), (20, 40)], fill=C["wood"], width=2); d.line([(44, 14), (44, 40)], fill=C["wood"], width=2)
    simple("boca_mina", 64, 42, boca_mina)
    def portal(open_):
        def f(d):
            d.rectangle([2, 8, 46, 46], fill=(150, 140, 120, 255), outline=o)
            d.rectangle([14, 16, 34, 46], fill=(20, 16, 24, 255) if open_ else sil, outline=o)
            d.polygon([(0, 10), (24, 0), (48, 10)], fill=(130, 120, 104, 255), outline=o)
            for (x, y) in [(6, 20), (40, 20), (6, 34), (40, 34)]:
                d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=glow if not open_ else (250, 210, 60, 255))
        return f
    simple("portal_ruina_fechado", 48, 48, portal(False))
    simple("portal_ruina_aberto", 48, 48, portal(True))
    for i, sym in enumerate(["sol", "lua", "chuva"]):
        for lit in (False, True):
            def totem(d, sym=sym, lit=lit):
                d.ellipse([3, 26, 17, 31], fill=(0, 0, 0, 60))
                d.rectangle([4, 4, 16, 29], fill=(140, 130, 112, 255), outline=o)
                col = (250, 210, 60, 255) if lit else (90, 84, 76, 255)
                if sym == "sol":
                    d.ellipse([7, 9, 13, 15], outline=col, width=2)
                elif sym == "lua":
                    d.arc([6, 8, 14, 16], 60, 300, fill=col, width=2)
                else:
                    for x in (7, 10, 13):
                        d.line([(x, 9), (x - 1, 15)], fill=col, width=1)
                d.line([(6, 20), (14, 20)], fill=col)
            simple(f"totem_{sym}_{'on' if lit else 'off'}", 20, 32, totem)
    def mural(d):
        d.line([(4, 30), (4, 10)], fill=C["wood_d"], width=2); d.line([(28, 30), (28, 10)], fill=C["wood_d"], width=2)
        d.rectangle([1, 2, 31, 20], fill=C["wood_l"], outline=o)
        for (x, y) in [(4, 5), (14, 6), (22, 5), (8, 12)]:
            d.rectangle([x, y, x + 7, y + 6], fill=C["bege"], outline=C["wood_d"])
    simple("mural", 32, 32, mural)

    # chefes e Mãe-do-Ouro
    def guardiao(d, ox, f):
        b = (f % 2)
        d.ellipse([ox + 4, 36, ox + 36, 40], fill=(0, 0, 0, 70))
        d.polygon([(ox + 8, 36), (ox + 6, 14 + b), (ox + 14, 4), (ox + 26, 4), (ox + 34, 14 + b), (ox + 32, 36)], fill=(110, 100, 150, 255), outline=o)
        for (x, y) in [(ox + 12, 10), (ox + 24, 8), (ox + 18, 22), (ox + 28, 26)]:
            d.polygon([(x, y + 6), (x + 3, y), (x + 6, y + 6)], fill=glow, outline=o)
        d.rectangle([ox + 15, 15, ox + 17, 17], fill=C["white"]); d.rectangle([ox + 23, 15, ox + 25, 17], fill=C["white"])
    sheet("assets/enemies/guardiao_cristal_placeholder.png", 40, 40, 4, guardiao)
    def eco(d, ox, f):
        a = 150 + (f % 2) * 60
        d.ellipse([ox + 6, 34, ox + 26, 39], fill=(0, 0, 0, 60))
        d.polygon([(ox + 6, 36), (ox + 10, 8), (ox + 16, 2), (ox + 22, 8), (ox + 26, 36)], fill=(70, 66, 90, a), outline=o)
        d.ellipse([ox + 11, 8, ox + 21, 18], fill=(30, 28, 40, a))
        d.point((ox + 14, 12), fill=glow); d.point((ox + 18, 12), fill=glow)
        for k in range(3):
            d.arc([ox + 4 - k * 2, 14 - k * 2, ox + 28 + k * 2, 30 + k * 2], 200, 340, fill=(160, 150, 200, 120))
    sheet("assets/enemies/eco_silencio_placeholder.png", 32, 40, 4, eco)
    def mae_ouro(d, ox, f):
        r = 8 + (f % 2)
        d.ellipse([ox + 12 - r - 3, 12 - r - 3, ox + 12 + r + 3, 12 + r + 3], fill=(250, 200, 60, 70))
        d.ellipse([ox + 12 - r, 12 - r, ox + 12 + r, 12 + r], fill=(255, 220, 90, 230))
        d.ellipse([ox + 9, 8, ox + 15, 14], fill=(255, 250, 220, 255))
    sheet("assets/npcs/mae_do_ouro_placeholder.png", 24, 24, 4, mae_ouro)
    simple("estilhaco", 8, 8, lambda d: d.polygon([(4, 0), (8, 4), (4, 8), (0, 4)], fill=glow, outline=o))


def make_app_icons():
    """Ícones do app web/PWA (pequi sobre terra vermelha)."""
    for size in (144, 180, 512):
        img = Image.new("RGBA", (16, 16), C["grass"])
        d = ImageDraw.Draw(img)
        d.rectangle([0, 12, 15, 15], fill=C["earth"])
        d.ellipse([3, 2, 12, 11], fill=C["pequi_g"], outline=C["outline"])
        d.ellipse([5, 4, 10, 9], fill=C["pequi"])
        img.resize((size, size), Image.NEAREST).save(out(f"assets/ui/app_icon_{size}.png"))


def make_content():
    """Fase 8: comidas, ingredientes, fogão a lenha, bancada, decoração e festas."""
    o = C["outline"]

    def icon(name, draw):
        im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        draw(ImageDraw.Draw(im))
        im.save(out(f"assets/items/{name}_placeholder.png"))

    def plate(fill, top=None):
        def f(d):
            d.ellipse([1, 8, 14, 14], fill=C["white"], outline=o)
            d.ellipse([3, 5, 12, 12], fill=fill, outline=o)
            if top:
                for (x, y) in [(5, 7), (8, 8), (10, 7), (7, 10)]:
                    d.rectangle([x, y, x, y], fill=top)
        return f

    def bowl(fill, top=None):
        def f(d):
            d.chord([2, 4, 13, 15], 0, 180, fill=C["terracota"], outline=o)
            d.ellipse([2, 5, 13, 10], fill=fill, outline=o)
            if top:
                d.rectangle([6, 6, 8, 7], fill=top)
        return f

    def sack(fill, label):
        def f(d):
            d.polygon([(4, 3), (11, 3), (13, 14), (2, 14)], fill=C["bege"], outline=o)
            d.rectangle([4, 7, 11, 11], fill=fill)
            d.line([(5, 3), (10, 3)], fill=label)
        return f

    def pamonha(d):
        d.polygon([(3, 13), (6, 3), (10, 3), (13, 13)], fill=(150, 170, 80, 255), outline=o)
        d.line([(8, 3), (8, 13)], fill=(120, 140, 60, 255))
        d.rectangle([5, 7, 11, 8], fill=C["bege_d"])
    def doce_leite(d):
        d.rectangle([4, 5, 11, 14], fill=(240, 240, 230, 200), outline=o)
        d.rectangle([5, 8, 10, 13], fill=(170, 110, 50, 255))
        d.rectangle([3, 3, 12, 5], fill=C["shirt"], outline=o)
    def lambari_frito(d):
        plate((200, 150, 70, 255))(d)
        d.polygon([(4, 8), (10, 6), (12, 8), (10, 10)], fill=(220, 170, 80, 255), outline=o)
    def empadao(d):
        d.ellipse([1, 9, 14, 14], fill=C["terracota_d"], outline=o)
        d.chord([2, 3, 13, 14], 180, 360, fill=(230, 180, 90, 255), outline=o)
        d.line([(5, 6), (10, 6)], fill=(190, 140, 60, 255))
    def pao_queijo(d):
        for (x, y) in [(2, 8), (8, 8), (5, 3)]:
            d.ellipse([x, y, x + 6, y + 6], fill=(236, 200, 120, 255), outline=o)
    for n, fn in [
        ("pamonha", pamonha), ("canjica", bowl((245, 236, 210, 255), (180, 130, 60, 255))),
        ("arroz_pequi", plate((236, 200, 60, 255), C["pequi"])),
        ("feijao_tropeiro", plate((150, 100, 60, 255), (230, 200, 120, 255))),
        ("doce_leite", doce_leite), ("lambari_frito", lambari_frito),
        ("caldo_mandioca", bowl((236, 214, 150, 255), (120, 70, 40, 255))),
        ("empadao", empadao), ("pao_queijo", pao_queijo),
        ("arroz", sack((240, 240, 236, 255), C["wood"])), ("acucar", sack((250, 250, 250, 255), C["jeans"])),
        ("farinha", sack((236, 214, 160, 255), C["terracota"])),
    ]:
        icon(n, fn)

    # decoração: ícone 16x16 + objeto no mundo
    def world(name, w, h, draw):
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.ellipse([2, h - 4, w - 3, h - 1], fill=(0, 0, 0, 60))
        draw(d, w, h)
        im.save(out(f"assets/environments/{name}_placeholder.png"))
        ic = im.copy()
        ic.thumbnail((16, 16), Image.NEAREST)
        canvas = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        canvas.paste(ic, ((16 - ic.width) // 2, (16 - ic.height) // 2))
        canvas.save(out(f"assets/items/{name}_placeholder.png"))

    def banco(d, w, h):
        d.rectangle([1, 6, w - 2, 9], fill=C["wood_l"], outline=o)
        d.rectangle([2, 9, 4, h - 2], fill=C["wood_d"]); d.rectangle([w - 5, 9, w - 3, h - 2], fill=C["wood_d"])
    def vaso(d, w, h):
        d.polygon([(4, h - 2), (3, 9), (w - 4, 9), (w - 5, h - 2)], fill=C["terracota"], outline=o)
        for (x, y, c) in [(5, 3, C["ipe"]), (9, 2, C["shirt"]), (7, 5, (230, 120, 170, 255))]:
            d.ellipse([x - 2, y, x + 2, y + 4], fill=c, outline=o)
        d.line([(7, 6), (7, 9)], fill=C["grass_d"])
    def lampiao(d, w, h):
        d.line([(w // 2, 2), (w // 2, h - 2)], fill=C["wood_d"], width=2)
        d.rectangle([w // 2 - 3, 2, w // 2 + 3, 9], fill=(250, 220, 120, 255), outline=o)
    def espantalho(d, w, h):
        d.line([(w // 2, 4), (w // 2, h - 2)], fill=C["wood"], width=2)
        d.line([(2, 9), (w - 3, 9)], fill=C["wood"], width=2)
        d.rectangle([w // 2 - 4, 8, w // 2 + 3, 15], fill=C["jeans"], outline=o)
        d.ellipse([w // 2 - 3, 2, w // 2 + 3, 8], fill=C["bege"], outline=o)
        d.rectangle([w // 2 - 5, 1, w // 2 + 5, 3], fill=C["hat"], outline=o)
    def trofeu(d, w, h):
        d.rectangle([4, h - 4, w - 5, h - 2], fill=C["wood"], outline=o)
        d.polygon([(3, 2), (w - 4, 2), (w - 6, 8), (6, 8)], fill=(240, 200, 50, 255), outline=o)
        d.rectangle([w // 2 - 1, 8, w // 2, h - 4], fill=(220, 180, 40, 255))
        d.ellipse([w // 2 - 2, 3, w // 2 + 1, 6], fill=C["pequi_g"])
    def mascara(d, w, h):
        d.line([(w // 2, 9), (w // 2, h - 2)], fill=C["wood_d"], width=2)
        d.ellipse([2, 1, w - 3, 10], fill=(240, 240, 240, 255), outline=o)
        d.rectangle([4, 4, 5, 5], fill=o); d.rectangle([w - 6, 4, w - 5, 5], fill=o)
        d.polygon([(2, 1), (w // 2, -3), (w - 3, 1)], fill=C["shirt"])
        for x in range(3, w - 3, 3):
            d.rectangle([x, 0, x + 1, 1], fill=C["ipe"])
    world("banco_madeira", 20, 14, banco)
    world("vaso_flores", 14, 16, vaso)
    world("lampiao", 10, 22, lampiao)
    world("espantalho", 16, 24, espantalho)
    world("trofeu_pequi", 14, 18, trofeu)
    world("mascara_cavalhada", 14, 20, mascara)

    def simple(name, w, h, draw):
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw(ImageDraw.Draw(im), w, h)
        im.save(out(f"assets/environments/{name}_placeholder.png"))
    def fogao(d, w, h):
        d.ellipse([1, h - 4, w - 2, h - 1], fill=(0, 0, 0, 60))
        d.rectangle([1, 8, w - 2, h - 2], fill=(200, 190, 170, 255), outline=o)
        d.rectangle([1, 6, w - 2, 9], fill=C["stone_d"], outline=o)
        d.rectangle([4, 12, 9, h - 4], fill=(30, 20, 18, 255))
        d.rectangle([5, 14, 8, h - 5], fill=(240, 120, 40, 255))
        d.rectangle([w - 7, 0, w - 4, 6], fill=C["stone_d"], outline=o)
        d.ellipse([12, 3, 18, 7], fill=(60, 56, 54, 255), outline=o)
    def bancada(d, w, h):
        d.ellipse([1, h - 4, w - 2, h - 1], fill=(0, 0, 0, 60))
        d.rectangle([1, 5, w - 2, 9], fill=C["wood_l"], outline=o)
        d.rectangle([2, 9, 4, h - 2], fill=C["wood_d"]); d.rectangle([w - 5, 9, w - 3, h - 2], fill=C["wood_d"])
        d.line([(5, 4), (12, 2)], fill=(190, 190, 200, 255), width=1)
        d.rectangle([15, 2, 19, 5], fill=C["wood"], outline=o)
    def barraca(d, w, h):
        d.ellipse([1, h - 4, w - 2, h - 1], fill=(0, 0, 0, 60))
        d.rectangle([3, 14, w - 4, h - 2], fill=C["wood_l"], outline=o)
        for i, x in enumerate(range(1, w - 1, 5)):
            d.polygon([(x, 2), (x + 5, 2), (x + 5, 12), (x, 12)], fill=C["shirt"] if i % 2 == 0 else C["white"])
        d.rectangle([1, 2, w - 2, 12], outline=o)
        d.line([(3, 12), (3, h - 2)], fill=C["wood_d"]); d.line([(w - 4, 12), (w - 4, h - 2)], fill=C["wood_d"])
    def fogueira(d, w, h):
        d.ellipse([1, h - 5, w - 2, h - 1], fill=(0, 0, 0, 70))
        for x in range(2, w - 2, 3):
            d.line([(x, h - 2), (w // 2, h - 9)], fill=C["wood"], width=2)
        d.polygon([(w // 2 - 5, h - 4), (w // 2, 1), (w // 2 + 5, h - 4)], fill=(250, 130, 30, 255))
        d.polygon([(w // 2 - 2, h - 4), (w // 2, 6), (w // 2 + 2, h - 4)], fill=(255, 220, 90, 255))
    def bandeira(d, w, h):
        d.ellipse([w // 2 - 4, h - 4, w // 2 + 4, h - 1], fill=(0, 0, 0, 60))
        d.line([(w // 2, 1), (w // 2, h - 2)], fill=C["wood_d"], width=2)
        d.rectangle([w // 2 + 1, 2, w - 1, 14], fill=C["shirt"], outline=o)
        d.rectangle([w // 2 + 4, 5, w - 4, 11], fill=C["white"])
        for i in range(4):
            d.line([(w // 2 + 2 + i * 2, 14), (w // 2 + 2 + i * 2, 20)], fill=[C["ipe"], C["jeans"], C["grass"], C["shirt"]][i])
    def arquibancada(d, w, h):
        d.ellipse([1, h - 4, w - 2, h - 1], fill=(0, 0, 0, 60))
        for i in range(3):
            y = 4 + i * 5
            d.rectangle([1 + i * 2, y, w - 2 - i * 2, y + 3], fill=C["wood_l"] if i % 2 == 0 else C["wood"], outline=o)
        d.rectangle([2, 4, 4, h - 2], fill=C["wood_d"]); d.rectangle([w - 5, 4, w - 3, h - 2], fill=C["wood_d"])
    simple("fogao_lenha", 24, 22, fogao)
    simple("bancada", 24, 18, bancada)
    simple("barraca", 34, 26, barraca)
    simple("fogueira", 18, 20, fogueira)
    simple("bandeira_folia", 20, 26, bandeira)
    simple("arquibancada", 40, 22, arquibancada)


def make_title():
    """Fase 9: fundo da tela de título (320x180, ampliado 2x)."""
    import random
    r = random.Random(4)
    W, H = 320, 180
    im = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(im)
    top, mid = (70, 110, 170), (246, 170, 90)
    for y in range(110):  # céu de fim de tarde
        k = y / 110
        d.line([(0, y), (W, y)], fill=tuple(int(top[i] + (mid[i] - top[i]) * k) for i in range(3)) + (255,))
    d.ellipse([228, 52, 262, 86], fill=(255, 214, 120, 255))
    serra = [(0, 100), (30, 84), (60, 92), (95, 70), (130, 88), (170, 76), (210, 90), (250, 72), (290, 86), (320, 80), (320, 120), (0, 120)]
    d.polygon(serra, fill=(110, 90, 120, 255))
    d.rectangle([0, 104, W, H], fill=C["dry"])
    for _ in range(500):
        x, y = r.randrange(W), r.randrange(106, H)
        d.point((x, y), fill=r.choice([C["dry_l"], C["dry_d"], C["grass"], C["grass_d"]]))
    d.polygon([(130, H), (254, 128), (268, 128), (200, H)], fill=C["earth"])
    pequi = Image.open(out("assets/environments/pequizeiro_placeholder.png"))
    ipe = Image.open(out("assets/environments/ipe_amarelo_placeholder.png"))
    casa = Image.open(out("assets/environments/casa_principal_placeholder.png"))
    im.alpha_composite(casa, (214, 120 - casa.height + 14))
    for (img, x, y) in [(pequi, 40, 128), (ipe, 186, 120), (pequi, 280, 140), (ipe, 90, 112), (pequi, 10, 150)]:
        im.alpha_composite(img, (x, y - img.height + 20))
    im.resize((W * 2, H * 2), Image.NEAREST).save(out("assets/ui/titulo_fundo_placeholder.png"))


if __name__ == "__main__":
    make_touch_ui()
    make_farming()
    make_npcs()
    make_village()
    make_fauna()
    make_combat()
    make_adventure()
    make_content()
    make_weather()
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
    make_title()
    # arte nova (Ninja Adventure repintado) por cima das provisórias, quando o pacote estiver no projeto
    if os.path.isdir(os.path.join(ROOT, "third_party", "ninja_adventure")):
        import subprocess, sys
        subprocess.run([sys.executable, os.path.join(ROOT, "tools", "aplicar_arte_ninja.py")], check=True)
    print("Assets provisórios gerados.")
