"""
Personagens do Vale do Pequi em pixel art 2D chapada (desenhados à mão em ASCII).

Folha 128x256: 4 quadros de caminhada (32x32) x 8 direções
(S, SE, E, NE, N, NW, W, SW). Pés em y=30. Quadro 0 = parado.
NW, W e SW são o espelho de NE, E e SE.

Cada morador é o mesmo "boneco" com outra paleta + peças (chapéu, cabelo
comprido, coque, bigode, avental, saia...).

Legenda dos desenhos:
  o contorno   s pele   S pele sombra   e olho
  h cabelo     H cabelo sombra
  c roupa      C roupa sombra
  p calça      P calça sombra   b sapato
  w avental/jaleco   W sombra do avental
  t chapéu     T chapéu sombra  k fita do chapéu   m bigode/barba
  . transparente
"""
import numpy as np
from PIL import Image

F = 32
ORDEM = ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
ESPELHO = {"NW": "NE", "W": "E", "SW": "SE"}
CAB_X, CAB_Y = 10, 7     # canto da cabeça (12x11)
TRONCO_Y = 18            # tronco (12x7)
PERNA_Y = 25             # pernas (12x6), pé termina em y=30


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def escurece(c, k=0.22):
    return tuple(int(v * (1 - k)) for v in c[:3]) + (255,)


def D(txt):
    linhas = [l for l in txt.strip("\n").split("\n")]
    w = max(len(l) for l in linhas)
    return [l.ljust(w, ".") for l in linhas]


# --- cabeças (12x11) ---------------------------------------------------------------

CABECA = {
    "S": D("""
...oooooo...
..ohhhhhho..
.ohhhhhhhho.
.ohhhhhhhho.
ohhsssssshho
ohssssssssho
osssessesss.
osssessesss.
oSssssssssSo
.oSssssssSo.
..oooooooo..
"""),
    "SE": D("""
...oooooo...
..ohhhhhho..
.ohhhhhhhho.
.ohhhhhhhhho
ohhhhsssssso
ohhhssssssso
ohhsssesseso
ohhsssesseso
oHSsssssssSo
.oSssssssSo.
..oooooooo..
"""),
    "E": D("""
...oooooo...
..ohhhhhho..
.ohhhhhhhho.
.ohhhhhhhhho
ohhhhhhsssso
ohhhhhssssso
ohhhhssssesoo
ohhhhsssseso
oHHSssssssso
.oHSsssssso.
..oooooooo..
"""),
    "NE": D("""
...oooooo...
..ohhhhhho..
.ohhhhhhhho.
.ohhhhhhhhho
ohhhhhhhhhho
ohhhhhhhhhso
ohhhhhhhhsso
ohhhhhhhhsso
oHhhhhhhHSSo
.oHHHHHHSSo.
..oooooooo..
"""),
    "N": D("""
...oooooo...
..ohhhhhho..
.ohhhhhhhho.
.ohhhhhhhho.
ohhhhhhhhhho
ohhhhhhhhhho
ohhhhhhhhhho
ohhhhhhhhhho
oHhhhhhhhhHo
.oHHHHHHHHo.
..oooooooo..
"""),
}
# fecha o contorno do rosto de frente (linhas dos olhos)
CABECA["S"][6] = "osssessessso"
CABECA["S"][7] = "osssessessso"

# --- tronco com braços (12x7); E tem 3 posições de braço ----------------------------

TRONCO = {
    "S": D("""
...oossoo...
.ooccccccoo.
occccccccccco
oCoccccccoCo
oCoccccccoCo
osoCCCCCCoso
.oooppppooo.
"""),
    "SE": D("""
...oossoo...
..oocccccoo.
.occcccccco.
.oCcccccoCo.
.oCcccccoCo.
.osCCCCCoso.
..oopppppo..
"""),
    "E0": D("""
....ooso....
...occcco...
..occcccCo..
..ocCcccCo..
..ocCcccCo..
..ocsCCCCo..
...oppppo...
"""),
    "E1": D("""
....ooso....
...occcco...
..occcccCo..
..occCcccCo.
..occcCcccoo
..oCCCCCsso.
...oppppoo..
"""),
    "E3": D("""
....ooso....
...occcco...
..occcccCo..
.oCcccccCo..
oCocccccCo..
ossCCCCCCo..
.o.oppppo...
"""),
    "NE": D("""
....oooo....
..oocccccoo.
.occcccccco.
.oCcccccoCo.
.oCcccccoCo.
.oCCCCCCoso.
..oopppppo..
"""),
    "N": D("""
....oooo....
.ooccccccoo.
occccccccccco
oCoccccccoCo
oCoccccccoCo
osoCCCCCCoso
.oooppppooo.
"""),
}
for k in ("S", "N"):
    TRONCO[k][2] = "occccccccco"[:0] + "occcccccccco"

# --- pernas (12x6): 4 quadros; 2 = 0 --------------------------------------------

PERNAS = {
    "S": [D("""
.oppppppppo.
.opppoopppo.
..oPpooPpo..
..oPpooPpo..
..obboobbo..
..oooooooo..
"""), D("""
.oppppppppo.
.opppoopppo.
..oPpooPpo..
..obbooPpo..
..ooooobbo..
......oooo..
"""), None, D("""
.oppppppppo.
.opppoopppo.
..oPpooPpo..
..oPpoobbo..
..obboooo...
..oooo......
""")],
    "SE": [D("""
..oppppppo..
..opppppppo.
..oPpooPppo.
..oPpo.oPpo.
..obbbooobbbo
..ooooo.ooooo
"""), D("""
..oppppppo..
..opppppppo.
..oPpo.oPppo
..obbbo.oPpo
..ooooo.obbbo
........ooooo
"""), None, D("""
..oppppppo..
..opppppppo.
.oPpo..oPpo.
.oPpo..obbbo
.obbbo.ooooo
.ooooo......
""")],
    "E": [D("""
...oppppo...
...opppPo...
...oppPPo...
...oppPPo...
...obbbbbo..
...ooooooo..
"""), D("""
...oppppo...
..opppppPo..
.oPpo.oPpo..
.oPpo..oPPo.
obbbo..obbbo
ooooo..ooooo
"""), None, D("""
...oppppo...
..oPpppppo..
..oPpo.oPpo.
.oPPo..oPpo.
obbbo..obbbo
ooooo..ooooo
""")],
}
PERNAS["N"] = PERNAS["S"]
PERNAS["NE"] = PERNAS["SE"]
for k in PERNAS:
    PERNAS[k][2] = PERNAS[k][0]

# --- saia (por cima do topo das pernas) -----------------------------------------
SAIA = {
    "S": D("""
.occcccccco.
oCccccccccCo
oooooooooooo
"""),
    "E": D("""
..occcccco..
.oCcccccCCo.
.oooooooooo.
"""),
}
for k in ("SE", "NE", "N"):
    SAIA[k] = SAIA["S"]

# --- chapéus e enfeites (posição relativa ao canto da cabeça) -----------------------

PALHA = (-2, -3, D("""
.....oooooo.....
....otttttto....
...okkkkkkkko...
.oottttttttttoo.
otttttttttttttto
oTTTTTTTTTTTTTTo
.oooooooooooooo.
"""))

COURO = (-1, -3, D("""
....oooooo....
...otttttto...
..oTkkkkkkTo..
oootttttttttoo
otttttttttttto
.ooTTTTTTTTTo.
...oooooooo...
"""))

BONE = {
    "S": (0, -1, D("""
...oooooo...
..otttttto..
.otttttttto.
.oTTTTTTTTo.
ooTTTTTTTToo
.oooooooooo.
""")),
    "SE": (0, -1, D("""
...oooooo...
..otttttto..
.otttttttto.
.oTTTTTTtTTo
..ooooooTTTTo
.......ooooo
""")),
    "E": (0, -1, D("""
...oooooo....
..otttttto...
.ottttttttoo.
.oTTTTTTTTTTo
..ooooooooooo
""")),
    "NE": (0, -1, D("""
...oooooo...
..otttttto..
.otttttttto.
.oTTTTTTTTTo
..ooooooooo.
""")),
    "N": (0, -1, D("""
...oooooo...
..otttttto..
.otttttttto.
.oTTTTTTTTo.
..oooooooo..
""")),
}

LENCO_NO = {"S": None, "SE": (-2, 2, D("""
.oo.
otto
.oo.
""")), "E": (-2, 1, D("""
.oo.
otto
otto
.oo.
""")), "NE": (-1, 3, D("""
.oo.
otto
.oo.
""")), "N": (4, 5, D("""
.oooo.
ottTto
.oooo.
"""))}

COQUE = {"S": (3, -2, D("""
.oooooo.
ohhhhhho
""")), "SE": (0, -1, D("""
.ooo.
ohhho
ohhHo
.ooo.
""")), "E": (-1, 1, D("""
.ooo.
ohhho
ohHHo
.ooo.
""")), "NE": (0, 0, D("""
.oooo.
ohhhho
oHHHHo
.oooo.
""")), "N": (3, -1, D("""
.oooooo.
ohhhhhho
oHHHHHHo
.oooooo.
"""))}

RABO = {"S": None, "SE": (-1, 7, D("""
.oo.
ohho
ohHo
ohHo
.oo.
""")), "E": (-1, 6, D("""
.oo.
ohho
ohHo
ohHo
ohHo
.oo.
""")), "NE": (1, 8, D("""
.oo.
ohho
ohHo
ohHo
.oo.
""")), "N": (4, 9, D("""
.oooo.
.ohho.
.ohHo.
.ohHo.
..oo..
"""))}

LONGO = {"S": (-1, 4, D("""
oo..........oo
ho..........oh
ho..........oh
hHo........oHh
HHo........oHH
oo..........oo
""")), "SE": (-1, 4, D("""
oo.........
ho.........
hho........
hHo........
HHo........
oo.........
""")), "E": (0, 5, D("""
ohhhho
ohhhHo
ohhHHo
ohHHo.
oHHo..
ooo...
""")), "NE": (0, 8, D("""
ohhhhhhhhho.
ohhhhhhhhHo.
oHHhhhhhHHo.
.oHHHHHHHo..
..ooooooo...
""")), "N": (0, 8, D("""
ohhhhhhhhhho
ohhhhhhhhhho
oHhhhhhhhhHo
.oHHHHHHHHo.
..oooooooo..
"""))}

BIGODE = {"S": (4, 8, ["mmmm"]), "SE": (6, 8, ["mmmm"]), "E": (8, 8, ["mmm"]), "NE": None, "N": None}

BARBA = {"S": (2, 8, D("""
.mmmmmmm.
.mmmmmmm.
..mmmmm..
""")), "SE": (4, 8, D("""
.mmmmmm.
.mmmmmm.
..mmmm..
""")), "E": (6, 8, D("""
mmmmm
mmmm.
.mm..
""")), "NE": None, "N": None}

AVENTAL = {"S": (3, 1, D("""
.wwwwww.
.wwwwww.
.wwwwww.
.wWwwWw.
.wwwwww.
""")), "SE": (4, 1, D("""
wwwww
wwwww
wwwww
wWwWw
""")), "E": (6, 1, D("""
ww
ww
ww
Ww
"""))}

JALECO = {"S": (1, 1, D("""
oww....wwo
oww....wwo
oww....wwo
oWw....wWo
oWw....wWo
oWw....wWo
.oo....oo.
""")), "SE": (1, 1, D("""
owww.....wo
owww.....wo
owww.....wo
oWww.....Wo
oWww.....Wo
oWww......o
.ooo.......
""")), "E": (2, 1, D("""
owww
owww
oWww
oWww
oWWw
oWWw
.ooo
""")), "NE": (1, 1, D("""
owwwwwwwwo.
owwwwwwwwo.
owwwwwwwwo.
oWwwwwwwWo.
oWwwwwwwWo.
oWWWWWWWWo.
.oooooooo..
""")), "N": (0, 1, D("""
.owwwwwwwwo.
.owwwwwwwwo.
.owwwwwwwwo.
.oWwwwwwwWo.
.oWwwwwwwWo.
.oWWWWWWWWo.
..oooooooo..
"""))}


# --- montagem -------------------------------------------------------------------

def carimbo(img, desenho, x0, y0, cores, so_em=False):
    for y, linha in enumerate(desenho):
        for x, ch in enumerate(linha):
            if ch == "." or ch not in cores:
                continue
            X, Y = x0 + x, y0 + y
            if not (0 <= X < F and 0 <= Y < F):
                continue
            if so_em and img[Y, X, 3] < 255:
                continue
            img[Y, X] = cores[ch]


def paleta(p):
    chapeu = p.get("cor_chapeu", hexc("e8c36a"))
    av = p.get("avental", hexc("f2eee4"))
    return {
        "o": hexc("2b1d18"), "e": hexc("2b1d18"),
        "s": p["pele"], "S": escurece(p["pele"], 0.15),
        "h": p["cabelo"], "H": escurece(p["cabelo"]),
        "c": p["roupa"], "C": escurece(p["roupa"]),
        "p": p["calca"], "P": escurece(p["calca"]),
        "b": p.get("sapato", hexc("4a2f1f")),
        "w": av, "W": escurece(av, 0.15),
        "t": chapeu, "T": escurece(chapeu), "k": p.get("fita", escurece(chapeu, 0.4)),
        "m": p.get("bigode", p["cabelo"]),
    }


def quadro(p, vista, q):
    img = np.zeros((F, F, 4), dtype=np.uint8)
    cores = paleta(p)
    bob = -1 if q in (1, 3) else 0
    # sombra no chão
    for x in range(11, 21):
        img[30, x] = (30, 20, 15, 70)
    for x in range(12, 20):
        img[31, x] = (30, 20, 15, 45)
    estilo = p.get("estilo")
    if estilo == "longo" and vista in ("S", "SE"):
        dx, dy, d = LONGO[vista]
        carimbo(img, d, CAB_X + dx, CAB_Y + dy + bob, cores)
    pc = dict(cores)
    if p.get("saia"):
        pc["p"], pc["P"] = cores["s"], cores["S"]
    carimbo(img, PERNAS[vista][q], CAB_X, PERNA_Y, pc)
    t = TRONCO["E" + str({0: 0, 1: 1, 2: 0, 3: 3}[q])] if vista == "E" else TRONCO[vista]
    carimbo(img, t, CAB_X, TRONCO_Y + bob, cores)
    if p.get("padrao"):
        for y in range(TRONCO_Y + bob, TRONCO_Y + bob + 7):
            for x in range(F):
                if tuple(img[y, x]) == cores["c"]:
                    if p["padrao"] == "xadrez" and (x // 2 + y // 2) % 2 == 0:
                        img[y, x] = cores["C"]
                    elif p["padrao"] == "listra" and y % 2 == 1:
                        img[y, x] = p.get("cor_listra", cores["C"])
    if p.get("saia"):
        sc = dict(cores)
        sc["c"], sc["C"] = p["saia"], escurece(p["saia"])
        carimbo(img, SAIA[vista], CAB_X, TRONCO_Y + 5 + bob, sc)
    if p.get("jaleco"):
        dx, dy, d = JALECO[vista]
        carimbo(img, d, CAB_X + dx, TRONCO_Y + dy - 1 + bob, cores)
    elif p.get("avental") and vista in AVENTAL:
        dx, dy, d = AVENTAL[vista]
        carimbo(img, d, CAB_X + dx, TRONCO_Y + dy + bob, cores)
    if estilo == "longo" and vista in ("E", "NE", "N"):
        dx, dy, d = LONGO[vista]
        carimbo(img, d, CAB_X + dx, CAB_Y + dy + bob, cores)
    if estilo == "rabo" and RABO[vista]:
        dx, dy, d = RABO[vista]
        carimbo(img, d, CAB_X + dx, CAB_Y + dy + bob, cores)
    carimbo(img, CABECA[vista], CAB_X, CAB_Y + bob, cores)
    if p.get("chapeu") == "lenco":
        for y in range(CAB_Y + bob, CAB_Y + bob + 5):
            for x in range(F):
                if tuple(img[y, x]) in (cores["h"], cores["H"]):
                    img[y, x] = cores["T"] if (x + 2 * y) % 5 == 0 else cores["t"]
        if LENCO_NO[vista]:
            dx, dy, d = LENCO_NO[vista]
            carimbo(img, d, CAB_X + dx, CAB_Y + dy + bob, cores)
    if estilo == "coque":
        dx, dy, d = COQUE[vista]
        carimbo(img, d, CAB_X + dx, CAB_Y + dy + bob, cores)
    if p.get("barba") and BARBA[vista]:
        dx, dy, d = BARBA[vista]
        bc = dict(cores)
        bc["m"] = p["barba"]
        carimbo(img, d, CAB_X + dx, CAB_Y + dy + bob, bc, so_em=True)
    if p.get("bigode") and BIGODE[vista]:
        dx, dy, d = BIGODE[vista]
        carimbo(img, d, CAB_X + dx, CAB_Y + dy + bob, cores, so_em=True)
    ch = p.get("chapeu")
    if ch in ("palha", "couro"):
        dx, dy, d = PALHA if ch == "palha" else COURO
        carimbo(img, d, CAB_X + dx, CAB_Y + dy + bob, cores)
        if ch == "palha":  # trançadinho
            for y in range(CAB_Y + dy + bob, CAB_Y + dy + bob + 7):
                for x in range(F):
                    if tuple(img[y, x]) == cores["t"] and (x + y * 2) % 5 == 0:
                        img[y, x] = cores["T"]
    elif ch == "bone":
        dx, dy, d = BONE[vista]
        carimbo(img, d, CAB_X + dx, CAB_Y + dy + bob, cores)
    return img


def folha(p):
    out = np.zeros((F * 8, F * 4, 4), dtype=np.uint8)
    for linha, d in enumerate(ORDEM):
        vista = ESPELHO.get(d, d)
        for q in range(4):
            img = quadro(p, vista, q)
            if d in ESPELHO:
                img = img[:, ::-1]
            out[linha * F:(linha + 1) * F, q * F:(q + 1) * F] = img
    return Image.fromarray(out, "RGBA")


# --- elenco -----------------------------------------------------------------------

PELE = {"clara": hexc("f3c9a4"), "morena": hexc("d9a173"), "parda": hexc("bd8056"),
        "escura": hexc("94603e"), "negra": hexc("74492f")}

ELENCO = {
    "player": dict(pele=PELE["morena"], cabelo=hexc("5a3720"), chapeu="palha", cor_chapeu=hexc("ecc66a"),
                   fita=hexc("b23a2e"), roupa=hexc("c8483b"), padrao="xadrez", calca=hexc("40639a"),
                   sapato=hexc("5b3a22")),
    "helena": dict(pele=PELE["parda"], cabelo=hexc("33201a"), estilo="rabo",
                   roupa=hexc("e3b33f"), calca=hexc("3f5e4a"), saia=hexc("4f8a6b"), avental=hexc("f3efe2"),
                   sapato=hexc("6b3d22")),
    "benedito": dict(pele=PELE["escura"], cabelo=hexc("d4d0c8"), chapeu="couro", cor_chapeu=hexc("8f5e35"),
                     fita=hexc("4a2f1f"), barba=hexc("ece9e2"), bigode=hexc("ece9e2"),
                     roupa=hexc("9cc0d8"), calca=hexc("9a8259"), sapato=hexc("4a2f1f")),
    "toninho": dict(pele=PELE["parda"], cabelo=hexc("221915"), bigode=hexc("221915"),
                    roupa=hexc("8f8b85"), avental=hexc("7d4c2b"), calca=hexc("4a443e"), sapato=hexc("2e211a")),
    "alzira": dict(pele=PELE["negra"], cabelo=hexc("bdb6ad"), estilo="coque", chapeu="lenco",
                   cor_chapeu=hexc("c43d2e"), roupa=hexc("dd7d9e"), saia=hexc("c95f86"), avental=hexc("f6f1e6"),
                   calca=hexc("c95f86"), sapato=hexc("5b3a22")),
    "joao_pedro": dict(pele=PELE["negra"], cabelo=hexc("1b1411"), chapeu="bone", cor_chapeu=hexc("2e6fb0"),
                       roupa=hexc("f0ece2"), padrao="listra", cor_listra=hexc("e07a3a"),
                       calca=hexc("6b7a3a"), sapato=hexc("c9a46b")),
    "mariana": dict(pele=PELE["clara"], cabelo=hexc("a0502a"), estilo="longo",
                    roupa=hexc("5a9566"), calca=hexc("40639a"), avental=hexc("f6f6f2"), jaleco=True,
                    sapato=hexc("6b4a35")),
}


def gerar(root):
    import os
    for nome, p in ELENCO.items():
        if nome == "player":
            caminho = os.path.join(root, "assets", "characters", "player_placeholder.png")
        else:
            caminho = os.path.join(root, "assets", "npcs", nome + "_placeholder.png")
        yield caminho, folha(p)


if __name__ == "__main__":
    import os
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    for c, im in gerar(root):
        im.save(c)
        print(c)
