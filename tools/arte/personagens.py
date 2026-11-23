"""
Personagens do Vale do Pequi em pixel art 2D chapada, estilo "chibi":
cabeção, corpinho curto, olhão e bochecha rosada (desenhados à mão em ASCII).

Folha 128x256: 4 quadros de caminhada (32x32) x 8 direções
(S, SE, E, NE, N, NW, W, SW). Pés em y=30. Quadro 0 = parado.
NW, W e SW são o espelho de NE, E e SE. Na caminhada o corpo sobe e
desce, os braços balançam e os pés alternam.

Legenda dos desenhos:
  o contorno   s pele   S pele sombra   e olho   r bochecha
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
CAB_X, CAB_Y = 9, 11     # cabeça 14x11
TRONCO_Y = 22            # tronco 14x5
PERNA_Y = 27             # pernas 14x4 (pé termina em y=30)


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def escurece(c, k=0.22):
    return tuple(int(v * (1 - k)) for v in c[:3]) + (255,)


def D(txt, w=None):
    linhas = [l for l in txt.strip("\n").split("\n") if l]
    larg = max(len(l) for l in linhas)
    if w is not None:
        assert larg == w and all(len(l) == w for l in linhas), (w, [len(l) for l in linhas], linhas)
    return [l.ljust(larg, ".") for l in linhas]


def espelha(desenho):
    return [l[::-1] for l in desenho]


# --- cabeças (14x11) ---------------------------------------------------------------
TOPO = """
....oooooo....
..oohhhhhhoo..
.ohhhhhhhhhho.
ohhhhhhhhhhhho
ohhhhhhhhhhhho
"""
CABECA = {
    "S": D(TOPO + """
ohhsshhhhsshho
ohssessssessho
osssessssessso
osrrssssssrrso
.oSssssssssSo.
..oooooooooo..
""", 14),
    "SE": D(TOPO + """
ohhhhhsshhssso
ohhhssesssesso
ohhsssesssesso
oHhssrrsssrrso
.oHSsssssssSo.
..oooooooooo..
""", 14),
    "E": D(TOPO + """
ohhhhhhhhhssso
ohhhhhhsssesso
ohhhhhssssesso
oHhhhssssrrsso
.oHHSsssssSo..
..oooooooooo..
""", 14),
    "NE": D(TOPO + """
ohhhhhhhhhhhso
ohhhhhhhhhhsso
ohhhhhhhhhhsso
oHhhhhhhhhhSso
.oHHHHHHHHSSo.
..oooooooooo..
""", 14),
    "N": D(TOPO + """
ohhhhhhhhhhhho
ohhhhhhhhhhhho
ohhhhhhhhhhhho
oHhhhhhhhhhhHo
.oHHHHHHHHHHo.
..oooooooooo..
""", 14),
}

# --- tronco com braços (14x5): parado, braço esquerdo pra frente, direito pra frente ---
T_FRENTE = D("""
...occcccco...
.oCccccccccCo.
.oCccccccccCo.
.osCCCCCCCCso.
..oppppppppo..
""", 14)
T_FRENTE_A = D("""
...occcccco...
.oCccccccccCo.
.osccccccccCo.
.oCCCCCCCCCCo.
..oppppppppso.
""", 14)
T_LADO = D("""
...occcccco...
..oCccccccco..
..oCccccccco..
..oCsCCCCCCo..
...oppppppo...
""", 14)
T_LADO_A = D("""
...occcccco...
..occcccccCo..
..occcccccCso.
..oCCCCCCCoo..
...oppppppo...
""", 14)
T_LADO_B = D("""
...occcccco...
..occcccccco..
.osCCcccccco..
..ooCCCCCCCo..
...oppppppo...
""", 14)

# --- pernas (14x4) ------------------------------------------------------------------
P_FRENTE = D("""
...oppppppo...
...oPpoopPo...
..obbo..obbo..
..oooo..oooo..
""", 14)
P_FRENTE_A = D("""
...oppppppo...
..obbo.oPpo...
..oooo.obbo...
.......oooo...
""", 14)
P_LADO = D("""
...opppppPo...
...oPppppPo...
...obbbbbbbo..
...ooooooooo..
""", 14)
P_LADO_A = D("""
...opppppPo...
..oPpo.oppPo..
.obbbo..obbbo.
.ooooo..ooooo.
""", 14)
P_LADO_B = D("""
...opppppPo...
...oPpPppPo...
...obbbbbbbo..
...ooooooooo..
""", 14)


def tronco(vista, q):
    if vista == "E":
        return [T_LADO, T_LADO_A, T_LADO, T_LADO_B][q]
    return [T_FRENTE, T_FRENTE_A, T_FRENTE, espelha(T_FRENTE_A)][q]


def pernas(vista, q):
    if vista == "E":
        return [P_LADO, P_LADO_A, P_LADO_B, P_LADO_A][q]
    return [P_FRENTE, P_FRENTE_A, P_FRENTE, espelha(P_FRENTE_A)][q]


# --- saia (por cima do topo das pernas, começa na linha da cintura) ------------------
SAIA = {"F": D("""
..occcccccco..
.oCccccccccCo.
.oooooooooooo.
""", 14), "E": D("""
...occccccо...
..oCccccccCo..
..oooooooooo..
""".replace("о", "o"), 14)}

# --- chapéus e enfeites (posição relativa ao canto da cabeça) -----------------------
PALHA = (-2, -3, D("""
......oooooo......
....oottttttoo....
...okkkkkkkkkko...
.oottttttttttttoo.
otttttttttttttttto
oTTTTTTTTTTTTTTTTo
.oooooooooooooooo.
""", 18))

COURO = (-1, -3, D("""
.....oooooo.....
....otttttto....
...oTkkkkkkTo...
.oottttttttttoo.
otttttttttttttto
.ooTTTTTTTTTTTo.
...oooooooooo...
""", 16))

BONE = {
    "S": (0, -1, D("""
....oooooo....
..oottttttoo..
.otttttttttto.
.oTTTTTTTTTTo.
ooTTTTTTTTTToo
.oooooooooooo.
""", 14)),
    "SE": (0, -1, D("""
....oooooo....
..oottttttoo..
.otttttttttto.
.oTTTTTTTTtTTo
..oooooooTTTTo
.........oooo.
""", 14)),
    "E": (0, -1, D("""
....oooooo.....
..oottttttoo...
.otttttttttoo..
.oTTTTTTTTTTTo.
..oooooooooooo.
""", 15)),
    "NE": (0, -1, D("""
....oooooo....
..oottttttoo..
.otttttttttto.
.oTTTTTTTTTTo.
..oooooooooo..
""", 14)),
}
BONE["N"] = BONE["NE"]

LENCO_NO = {"S": None, "SE": (-1, 4, D("""
.oo.
otto
.oo.
""")), "E": (-2, 3, D("""
.oo.
otto
otto
.oo.
""")), "NE": (0, 5, D("""
.oo.
otto
.oo.
""")), "N": (5, 4, D("""
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
""")), "NE": (1, -1, D("""
.oooo.
ohhhho
oHHHHo
.oooo.
""")), "N": (3, -2, D("""
.oooooo.
ohhhhhho
oHHHHHHo
.oooooo.
"""))}

RABO = {"S": None, "SE": (-1, 6, D("""
.oo.
ohho
ohHo
ohHo
.oo.
""")), "E": (-1, 5, D("""
.oo.
ohho
ohHo
ohHo
ohHo
.oo.
""")), "NE": (2, 8, D("""
.oo.
ohho
ohHo
ohHo
.oo.
""")), "N": (5, 9, D("""
.oooo.
.ohho.
.ohHo.
.ohHo.
..oo..
"""))}

LONGO = {"S": (0, 7, D("""
oh..........ho
oh..........ho
ohh........hho
oHho......ohHo
oHHo......oHHo
.oo........oo.
""", 14)), "SE": (0, 7, D("""
oh..
oh..
ohh.
oHho
oHHo
.oo.
""")), "E": (0, 6, D("""
ohhhho
ohhhHo
ohhHHo
ohHHo.
oHHo..
ooo...
""")), "NE": (1, 8, D("""
ohhhhhhhho..
ohhhhhhhHo..
oHHhhhhHHo..
.oHHHHHHo...
..oooooo....
""")), "N": (1, 8, D("""
ohhhhhhhhhho
ohhhhhhhhhho
oHhhhhhhhhHo
.oHHHHHHHHo.
..oooooooo..
"""))}

BIGODE = {"S": (5, 8, ["mmmm"]), "SE": (7, 8, ["mmm"]), "E": (10, 8, ["mm"]), "NE": None, "N": None}
BARBA = {"S": (2, 8, ["mmmmmmmmmm", ".mmmmmmmm."]), "SE": (4, 8, ["mmmmmmmm", ".mmmmmm."]),
         "E": (7, 8, ["mmmmm", ".mmm."]), "NE": None, "N": None}

AVENTAL = {"S": (4, 1, D("""
wwwwww
wwwwww
wWwwWw
wwwwww
""")), "SE": (5, 1, D("""
wwwww
wwwww
wWwWw
wwwww
""")), "E": (8, 1, D("""
ww
ww
Ww
"""))}

JALECO = {"S": (1, 0, D("""
.oww....wwo.
.oww....wwo.
.oWw....wWo.
.oWw....wWo.
.oWw....wWo.
..oo....oo..
""")), "SE": (1, 0, D("""
.owww....wo.
.owww....wo.
.oWww....Wo.
.oWww....Wo.
.oWww.....o.
..ooo.......
""")), "E": (3, 0, D("""
.owww
.owww
.oWww
.oWWw
.oWWw
..ooo
""")), "NE": (1, 0, D("""
.owwwwwwwwo.
.owwwwwwwwo.
.oWwwwwwwWo.
.oWwwwwwwWo.
.oWWWWWWWWo.
..oooooooo..
"""))}
JALECO["N"] = JALECO["NE"]


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
        "r": p.get("bochecha", hexc("e8826e")),
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
    lado = "E" if vista == "E" else "F"
    # sombrinha no chão
    for x in range(11, 21):
        img[30, x] = (30, 20, 15, 60)
    for x in range(12, 20):
        img[31, x] = (30, 20, 15, 40)
    estilo = p.get("estilo")
    hy = CAB_Y + bob
    if estilo == "longo" and vista in ("S", "SE"):
        dx, dy, d = LONGO[vista]
        carimbo(img, d, CAB_X + dx, hy + dy, cores)
    pc = dict(cores)
    if p.get("saia"):
        pc["p"], pc["P"] = cores["s"], cores["S"]
    carimbo(img, pernas(vista, q), CAB_X, PERNA_Y, pc)
    carimbo(img, tronco(vista, q), CAB_X, TRONCO_Y + bob, cores)
    if p.get("padrao"):
        for y in range(TRONCO_Y + bob, TRONCO_Y + bob + 4):
            for x in range(F):
                if tuple(img[y, x]) == cores["c"]:
                    if p["padrao"] == "xadrez" and (x // 2 + y // 2) % 2 == 0:
                        img[y, x] = cores["C"]
                    elif p["padrao"] == "listra" and y % 2 == 1:
                        img[y, x] = p.get("cor_listra", cores["C"])
    if p.get("saia"):
        sc = dict(cores)
        sc["c"], sc["C"] = p["saia"], escurece(p["saia"])
        carimbo(img, SAIA[lado], CAB_X, TRONCO_Y + 4 + bob, sc)
    if p.get("jaleco"):
        dx, dy, d = JALECO[vista]
        carimbo(img, d, CAB_X + dx, TRONCO_Y + dy + bob, cores)
    elif p.get("avental") and vista in AVENTAL:
        dx, dy, d = AVENTAL[vista]
        carimbo(img, d, CAB_X + dx, TRONCO_Y + dy + bob, cores)
    if estilo == "longo" and vista in ("E", "NE", "N"):
        dx, dy, d = LONGO[vista]
        carimbo(img, d, CAB_X + dx, hy + dy, cores)
    if estilo == "rabo" and RABO[vista]:
        dx, dy, d = RABO[vista]
        carimbo(img, d, CAB_X + dx, hy + dy, cores)
    carimbo(img, CABECA[vista], CAB_X, hy, cores)
    if p.get("chapeu") == "lenco":
        for y in range(hy, hy + 6):
            for x in range(F):
                if tuple(img[y, x]) in (cores["h"], cores["H"]):
                    img[y, x] = cores["T"] if (x + 2 * y) % 5 == 0 else cores["t"]
        if LENCO_NO[vista]:
            dx, dy, d = LENCO_NO[vista]
            carimbo(img, d, CAB_X + dx, hy + dy, cores)
    if estilo == "coque":
        dx, dy, d = COQUE[vista]
        carimbo(img, d, CAB_X + dx, hy + dy, cores)
    if p.get("barba") and BARBA[vista]:
        dx, dy, d = BARBA[vista]
        bc = dict(cores)
        bc["m"] = p["barba"]
        carimbo(img, d, CAB_X + dx, hy + dy, bc, so_em=True)
    if p.get("bigode") and BIGODE[vista]:
        dx, dy, d = BIGODE[vista]
        carimbo(img, d, CAB_X + dx, hy + dy, cores, so_em=True)
    ch = p.get("chapeu")
    if ch in ("palha", "couro"):
        dx, dy, d = PALHA if ch == "palha" else COURO
        carimbo(img, d, CAB_X + dx, hy + dy, cores)
        if ch == "palha":  # trançadinho
            for y in range(hy + dy, hy + dy + 7):
                for x in range(F):
                    if tuple(img[y, x]) == cores["t"] and (x + y * 2) % 5 == 0:
                        img[y, x] = cores["T"]
    elif ch == "bone":
        dx, dy, d = BONE[vista]
        carimbo(img, d, CAB_X + dx, hy + dy, cores)
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

PELE = {"clara": hexc("f6cfae"), "morena": hexc("e2a97c"), "parda": hexc("c4875b"),
        "escura": hexc("9a6442"), "negra": hexc("7a4c32")}

ELENCO = {
    "player": dict(pele=PELE["morena"], cabelo=hexc("6b3f22"), chapeu="palha", cor_chapeu=hexc("f0ca6c"),
                   fita=hexc("d0402f"), roupa=hexc("dc4b3c"), padrao="xadrez", calca=hexc("4a6fae"),
                   sapato=hexc("6b4126"), bochecha=hexc("ef8a72")),
    "helena": dict(pele=PELE["parda"], cabelo=hexc("3a2419"), estilo="rabo",
                   roupa=hexc("e9b844"), calca=hexc("3f5e4a"), saia=hexc("55957a"), avental=hexc("f6f1e4"),
                   sapato=hexc("6b3d22"), bochecha=hexc("d77a62")),
    "benedito": dict(pele=PELE["escura"], cabelo=hexc("d8d4cc"), chapeu="couro", cor_chapeu=hexc("94613a"),
                     fita=hexc("4a2f1f"), barba=hexc("efece6"), bigode=hexc("efece6"),
                     roupa=hexc("a3c6dd"), calca=hexc("a08a60"), sapato=hexc("4a2f1f"), bochecha=hexc("b06e52")),
    "toninho": dict(pele=PELE["parda"], cabelo=hexc("261c17"), bigode=hexc("261c17"),
                    roupa=hexc("94908a"), avental=hexc("82502d"), calca=hexc("4a443e"), sapato=hexc("2e211a"),
                    bochecha=hexc("d07a5e")),
    "alzira": dict(pele=PELE["negra"], cabelo=hexc("c2bbb2"), estilo="coque", chapeu="lenco",
                   cor_chapeu=hexc("cf4433"), roupa=hexc("e283a4"), saia=hexc("cf6690"), avental=hexc("f8f3e8"),
                   calca=hexc("cf6690"), sapato=hexc("5b3a22"), bochecha=hexc("a05a46")),
    "joao_pedro": dict(pele=PELE["negra"], cabelo=hexc("1f1714"), chapeu="bone", cor_chapeu=hexc("3478bd"),
                       roupa=hexc("f3efe6"), padrao="listra", cor_listra=hexc("e8823e"),
                       calca=hexc("707f3e"), sapato=hexc("d1ad74"), bochecha=hexc("a05a46")),
    "mariana": dict(pele=PELE["clara"], cabelo=hexc("ad5a2e"), estilo="longo",
                    roupa=hexc("5f9d6c"), calca=hexc("4a6fae"), avental=hexc("f8f8f4"), jaleco=True,
                    sapato=hexc("6b4a35"), bochecha=hexc("f0947e")),
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
