"""
Planta das casas por dentro: cada casa com um formato diferente, paredes grossas.

Gera data/maps/interior_<casa>.txt (planta em ASCII, lida pelo FarmGround) e
data/interiores.json (móveis, porta, saída), lido por scripts/world/interior_level.gd.

Como a planta é montada:
  - tudo começa "vazio" (X);
  - cada cômodo é um retângulo (x, y, largura, altura) com piso e tipo de parede;
    as 2 primeiras linhas viram a parede do fundo (parte de cima + barrado);
  - vazio encostado em cômodo vira parede (T); entre dois cômodos fica 2 de
    espessura, então a parede é grossa;
  - passagens ligam os cômodos; a porta de fora fica na parede de baixo.

Móveis: posição em tiles relativa ao chão do cômodo (0,0 = primeiro tile de
chão embaixo da parede do fundo); x = centro, y = base do móvel.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
T = 16
PAREDE = {"caiada": "Aa", "taipa": "Ee", "tijolo": "Kk", "tabua": "Vv", "branca": "Gg"}
# altura de cada móvel (px), para encostar na parede do fundo
ALTURA = {
    "cama_jogador": 30, "cama_helena": 30, "cama_alzira": 30, "cama_joao": 30, "cama_toninho": 30,
    "cama_mariana": 30, "guarda_roupa": 34, "guarda_roupa_branco": 34, "comoda_santo": 26, "comoda_vaso": 26,
    "fogao_casa": 30, "fogao_gas": 22, "pia": 22, "filtro_barro": 22, "estante": 32, "armario_remedio": 26,
    "maca": 18, "bancada": 18, "barril": 18, "sacos": 14, "vaso_planta": 18, "bigorna": 14, "mesa_madeira": 20,
}
CORPO = {
    "cama_jogador": (18, 16), "cama_helena": (28, 16), "cama_alzira": (18, 16), "cama_joao": (16, 16),
    "cama_toninho": (18, 16), "cama_mariana": (18, 16), "guarda_roupa": (20, 10), "guarda_roupa_branco": (20, 10),
    "comoda_santo": (18, 8), "comoda_vaso": (18, 8), "fogao_casa": (32, 10), "fogao_gas": (16, 8), "pia": (24, 8),
    "filtro_barro": (10, 6), "estante": (20, 10), "armario_remedio": (16, 8), "maca": (28, 8), "bancada": (22, 6),
    "barril": (12, 6), "sacos": (18, 6), "vaso_planta": (8, 4), "bigorna": (16, 6), "mesa_madeira": (28, 10),
    "mesa_xadrez": (28, 10), "mesa_azul": (24, 10), "cadeira": (8, 4), "cadeira_azul": (8, 4),
    "banco_madeira_casa": (22, 4), "balcao_clinica": (32, 8),
}


class Casa:
    def __init__(self, nome, w, h):
        self.nome = nome
        self.w, self.h = w, h
        self.g = [["X"] * w for _ in range(h)]
        self.comodos = {}
        self.itens = []
        self.porta = None

    def comodo(self, id, x, y, w, h, piso, parede):
        self.comodos[id] = (x, y, w, h)
        cima, baixo = PAREDE[parede]
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.g[yy][xx] = cima if yy == y else (baixo if yy == y + 1 else piso)

    def passagem(self, x, y, w, h, piso):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.g[yy][xx] = piso

    def fechar(self):
        """Vazio encostado (8 vizinhos) em cômodo vira parede."""
        dentro = lambda c: c not in "XT"
        novo = [row[:] for row in self.g]
        for y in range(self.h):
            for x in range(self.w):
                if self.g[y][x] != "X":
                    continue
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < self.w and 0 <= ny < self.h and dentro(self.g[ny][nx]):
                            novo[y][x] = "T"
        self.g = novo

    def saida(self, x, y, piso):
        self.g[y][x] = piso
        self.porta = (x, y)

    def chao(self, comodo, fx, fy):
        x, y, _, _ = self.comodos[comodo]
        return ((x + fx) * T, (y + 2 + fy) * T)

    def movel(self, nome, comodo, fx, fy=None, dica="", acao="", corpo=None):
        """fy=None: encostado na parede do fundo."""
        if fy is None:
            px, py = self.chao(comodo, fx, 0)
            py += ALTURA.get(nome, 16) - 6
        else:
            px, py = self.chao(comodo, fx, fy)
        c = corpo if corpo is not None else CORPO.get(nome, (0, 0))
        self.itens.append([nome, [px, py], list(c), dica, acao])

    def parede(self, nome, comodo, fx):
        x, y, _, _ = self.comodos[comodo]
        self.itens.append([nome, [(x + fx) * T, (y + 2) * T - 3], [0, 0], "", ""])

    def tapete(self, nome, comodo, fx, fy):
        px, py = self.chao(comodo, fx, fy)
        self.itens.append([nome, [px, py], [0, 0], "", ""])

    def texto(self):
        return "\n".join("".join(r) for r in self.g) + "\n"


def casa_jogador():
    # formato em L: quarto e sala à esquerda, cozinha no alto à direita
    c = Casa("casa", 22, 16)
    c.comodo("quarto", 1, 1, 8, 7, "w", "tabua")
    c.comodo("cozinha", 11, 1, 10, 8, "o", "taipa")
    c.comodo("sala", 1, 10, 12, 5, "w", "tabua")
    c.passagem(3, 8, 2, 4, "w")        # quarto -> sala
    c.passagem(11, 9, 2, 3, "o")       # cozinha -> sala
    c.fechar()
    c.saida(6, 15, "w")
    c.parede("quadro_ipe", "quarto", 4)
    c.movel("cama_jogador", "quarto", 1.4, None, "Dormir (passa o dia e salva)", "dormir")
    c.movel("comoda_santo", "quarto", 4.2, None, "Olhar o oratório", "O oratório da vó. A vela ainda acende todo dia.")
    c.movel("guarda_roupa", "quarto", 6.6, None, "Abrir o guarda-roupa",
            "Roupa de roça, chapéu de palha reserva e um terno que nunca saiu do cabide.")
    c.tapete("tapete_redondo", "quarto", 4, 3.4)
    c.parede("prateleira_panelas", "cozinha", 6.5)
    c.parede("relogio_parede", "cozinha", 9.2)
    c.movel("fogao_casa", "cozinha", 2.2, None, "Cozinhar no fogão a lenha", "cozinha")
    c.movel("pia", "cozinha", 6.5, None, "Lavar a louça", "Louça lavada. A água do poço é geladinha.")
    c.movel("filtro_barro", "cozinha", 9.2, None, "Beber água do filtro", "Água de filtro de barro: a mais gostosa que tem.")
    c.movel("mesa_xadrez", "cozinha", 5.5, 4.3)
    c.movel("cadeira", "cozinha", 4.2, 4.0)
    c.movel("cadeira", "cozinha", 6.8, 4.0)
    c.movel("sacos", "cozinha", 9.0, 5.8, "Olhar os sacos", "Feijão e milho guardados. Fartura é saco cheio.")
    c.parede("quadro_paisagem", "sala", 8)
    c.movel("banco_madeira_casa", "sala", 8.5, 1.4)
    c.movel("vaso_planta", "sala", 0.6, 2.9)
    c.movel("barril", "sala", 11.3, 2.9)
    c.tapete("tapete_redondo", "sala", 8.5, 2.6)
    c.cama = c.chao("quarto", 1.4, 2.6)
    return c


def casa_helena():
    # formato em T: quarto e cozinha lado a lado, sala estreita embaixo no meio
    c = Casa("casa_helena", 20, 15)
    c.comodo("quarto", 1, 1, 8, 6, "w", "caiada")
    c.comodo("cozinha", 11, 1, 8, 6, "q", "caiada")
    c.comodo("sala", 5, 9, 10, 5, "w", "caiada")
    c.passagem(6, 7, 2, 4, "w")
    c.passagem(12, 7, 2, 4, "q")
    c.fechar()
    c.saida(9, 14, "w")
    c.parede("quadro_paisagem", "quarto", 4)
    c.movel("cama_helena", "quarto", 1.6, None, "Olhar a cama", "Colcha de crochê azul, sem uma dobra fora do lugar.")
    c.movel("comoda_vaso", "quarto", 4.4)
    c.movel("guarda_roupa_branco", "quarto", 6.6)
    c.tapete("tapete_azul", "quarto", 4, 2.9)
    c.parede("quadro_ipe", "cozinha", 4)
    c.movel("fogao_gas", "cozinha", 1.2, None, "Olhar o fogão", "Um bule de café ainda morno em cima do fogão.")
    c.movel("pia", "cozinha", 3.6)
    c.movel("filtro_barro", "cozinha", 7.2)
    c.movel("mesa_azul", "cozinha", 4.5, 3.6, "Olhar a mesa", "Caderninho de contas da mercearia, cheio de anotação.")
    c.movel("cadeira_azul", "cozinha", 3.2, 3.4)
    c.movel("cadeira_azul", "cozinha", 5.8, 3.4)
    c.parede("relogio_parede", "sala", 5)
    c.movel("estante", "sala", 1.4, None, "Olhar a estante", "Romance de banca, livro de receita e um álbum de fotos da vila.")
    c.movel("vaso_planta", "sala", 8.5, 0.9)
    c.movel("vaso_planta", "sala", 0.6, 2.9)
    c.tapete("tapete_azul", "sala", 5, 2.2)
    return c


def casa_alzira():
    # formato em U: dois quartos nas alas de cima, cozinha grande embaixo
    c = Casa("casa_alzira", 24, 16)
    c.comodo("quarto_alzira", 1, 1, 7, 7, "h", "taipa")
    c.comodo("quarto_joao", 16, 1, 7, 7, "h", "taipa")
    c.comodo("cozinha", 1, 10, 22, 5, "o", "tijolo")
    c.passagem(3, 8, 2, 4, "h")
    c.passagem(19, 8, 2, 4, "h")
    c.fechar()
    c.saida(11, 15, "o")
    c.parede("quadro_paisagem", "quarto_alzira", 3.5)
    c.movel("cama_alzira", "quarto_alzira", 1.4, None, "Olhar a cama", "Cama da Dona Alzira. Tem um terço pendurado na cabeceira.")
    c.movel("comoda_santo", "quarto_alzira", 5.3)
    c.tapete("tapete_redondo", "quarto_alzira", 3.5, 3.6)
    c.parede("varas_pesca", "quarto_joao", 5.5)
    c.movel("cama_joao", "quarto_joao", 1.4, None, "Olhar a cama",
            "Cama do João Pedro. Cheiro de rio e uma revista de pescaria no travesseiro.")
    c.movel("barril", "quarto_joao", 5.5, 2.0, "Olhar o balde", "Isca e linha emaranhada. O João jura que tá organizado.")
    c.parede("prateleira_panelas", "cozinha", 14)
    c.movel("fogao_casa", "cozinha", 10.5, None, "Olhar o fogão", "Panela de galinhada borbulhando. Que cheiro!")
    c.movel("pia", "cozinha", 14, None)
    c.movel("filtro_barro", "cozinha", 16.5, None)
    c.movel("mesa_madeira", "cozinha", 6, 1.6)
    c.movel("cadeira", "cozinha", 4.6, 1.4)
    c.movel("cadeira", "cozinha", 7.4, 1.4)
    c.movel("banco_madeira_casa", "cozinha", 6, 2.7)
    c.movel("sacos", "cozinha", 20.5, 2.8)
    c.movel("vaso_planta", "cozinha", 0.6, 2.9)
    return c


def casa_toninho():
    # oficina larga embaixo à esquerda; quartinho mais alto, nos fundos à direita
    c = Casa("casa_toninho", 23, 14)
    c.comodo("oficina", 1, 4, 13, 9, "h", "tijolo")
    c.comodo("quarto", 16, 1, 6, 7, "w", "tabua")
    c.passagem(14, 6, 2, 2, "w")
    c.fechar()
    c.saida(6, 13, "h")
    c.parede("ferramentas_parede", "oficina", 3)
    c.parede("ferramentas_parede", "oficina", 9)
    c.movel("barril", "oficina", 0.7, None)
    c.movel("bancada", "oficina", 6, None, "Olhar a bancada", "Lâmina de facão esperando cabo novo.")
    c.movel("bigorna", "oficina", 6, 3.6, "Olhar a bigorna", "A bigorna ainda tá quente. Não encosta!")
    c.movel("sacos", "oficina", 11.5, 6.6, "Olhar os sacos", "Carvão pra forja. Muito carvão.")
    c.movel("barril", "oficina", 0.7, 6.6)
    c.parede("quadro_paisagem", "quarto", 4)
    c.movel("cama_toninho", "quarto", 1.4, None, "Olhar a cama",
            "Cama do Toninho. Simples, pesada... e com uma bigorna de enfeite do lado.")
    c.movel("comoda_vaso", "quarto", 4.6, None)
    c.movel("filtro_barro", "quarto", 5.4, 4.6)
    return c


def casa_mariana():
    # formato em cruz: recepção no meio, cozinha em cima, consultório e quarto nos lados
    c = Casa("casa_mariana", 21, 14)
    c.comodo("cozinha", 7, 1, 6, 4, "q", "branca")
    c.comodo("recepcao", 7, 7, 6, 6, "h", "branca")
    c.comodo("consultorio", 1, 7, 4, 6, "h", "branca")
    c.comodo("quarto", 15, 7, 5, 6, "w", "caiada")
    c.passagem(9, 5, 2, 4, "q")
    c.passagem(5, 10, 2, 2, "h")
    c.passagem(13, 10, 2, 2, "w")
    c.fechar()
    c.saida(9, 13, "h")
    c.movel("fogao_gas", "cozinha", 1.0, None)
    c.movel("pia", "cozinha", 3.2, None)
    c.movel("filtro_barro", "cozinha", 5.3, None)
    c.parede("quadro_paisagem", "recepcao", 3)
    c.movel("balcao_clinica", "recepcao", 3, 1.6, "Ler o caderno", "Fichas dos bichos do vale. A sua ainda tá em branco.")
    c.movel("vaso_planta", "recepcao", 0.6, 0.9)
    c.movel("vaso_planta", "recepcao", 5.4, 0.9)
    c.movel("cadeira", "recepcao", 0.6, 3.2)
    c.movel("maca", "consultorio", 2, None, "Olhar a maca", "Maca de atender bezerro. Tem pelo de cachorro grudado.")
    c.movel("armario_remedio", "consultorio", 1, 3.6, "Olhar o armário", "Vermífugo, vacina, pomada de casco. Tudo etiquetado.")
    c.parede("quadro_ipe", "quarto", 3.6)
    c.movel("cama_mariana", "quarto", 1.3, None, "Olhar a cama", "Cama da Mariana, colcha branquinha de crochê.")
    c.movel("estante", "quarto", 3.8, None, "Olhar a estante",
            "Livro de zoologia, guia de aves do cerrado e um romance pela metade.")
    c.tapete("tapete_verde", "quarto", 2.5, 3.0)
    return c


INFO = {
    "casa": {"name": "Sua casa", "outside": "farm", "outside_spawn": "", "save_outside": False},
    "casa_helena": {"name": "Casa da Helena", "outside": "vila", "outside_spawn": "porta_casa_azul", "save_outside": True},
    "casa_alzira": {"name": "Casa da Dona Alzira", "outside": "vila", "outside_spawn": "porta_casa_amarela", "save_outside": True},
    "casa_toninho": {"name": "Ferraria do Toninho", "outside": "vila", "outside_spawn": "porta_ferreiro", "save_outside": True},
    "casa_mariana": {"name": "Clínica da Mariana", "outside": "vila", "outside_spawn": "porta_clinica", "save_outside": True},
}


def gerar():
    dados = {}
    for fn in (casa_jogador, casa_helena, casa_alzira, casa_toninho, casa_mariana):
        c = fn()
        with open(os.path.join(ROOT, "data", "maps", "interior_%s.txt" % c.nome), "w", encoding="utf-8") as f:
            f.write(c.texto())
        d = dict(INFO[c.nome])
        d["door"] = list(c.porta)
        d["items"] = c.itens
        if hasattr(c, "cama"):
            d["bed_spot"] = list(c.cama)
        dados[c.nome] = d
    with open(os.path.join(ROOT, "data", "interiores.json"), "w", encoding="utf-8") as f:
        json.dump(dados, f, ensure_ascii=False, indent=1)
    return dados


if __name__ == "__main__":
    for k, v in gerar().items():
        print(k)
        print(open(os.path.join(ROOT, "data", "maps", "interior_%s.txt" % k)).read())
