"""
Gera assets/fonts/Simbolos.ttf: fonte "reserva" com os símbolos que o jogo usa
(★ ♥ ♡ → ↑ ✓ ♪ ◆ ✦), desenhados em pixel na grade da Upheaval
(1000 por em, 50 unidades = 1 px no tamanho 20; cada ponto do desenho vale 2×2 px,
grosso como as letras dela).
Quando a fonte principal não tem um caractere, o Godot busca nesta.
Uso: python3 tools/gerar_fonte_simbolos.py   (precisa de fonttools)
"""
import os

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PX = 100
UPEM = 1000

# 5x5, de cima pra baixo; a última linha fica na linha de base
GLYPHS = {
    "★": ["..#..", "#####", ".###.", ".#.#.", "#...#"],
    "♥": [".#.#.", "#####", "#####", ".###.", "..#.."],
    "♡": [".#.#.", "#.#.#", "#...#", ".#.#.", "..#.."],
    "→": ["..#..", "...#.", "#####", "...#.", "..#.."],
    "↑": ["..#..", ".###.", "#.#.#", "..#..", "..#.."],
    "✓": ["....#", "...#.", "#.#..", ".#...", "....."],
    "♪": ["..##.", "..#.#", "..#..", "###..", "###.."],
    "◆": ["..#..", ".###.", "#####", ".###.", "..#.."],
    "✦": ["..#..", "..#..", "##.##", "..#..", "..#.."],
}


def glyph(rows):
    pen = TTGlyphPen(None)
    h = len(rows)
    for r, line in enumerate(rows):
        for c, ch in enumerate(line):
            if ch != "#":
                continue
            x0, y0 = c * PX, (h - 1 - r) * PX
            pen.moveTo((x0, y0))
            pen.lineTo((x0, y0 + PX))
            pen.lineTo((x0 + PX, y0 + PX))
            pen.lineTo((x0 + PX, y0))
            pen.closePath()
    return pen.glyph()


def main():
    names = [".notdef"] + ["u%04X" % ord(c) for c in GLYPHS]
    fb = FontBuilder(UPEM, isTTF=True)
    fb.setupGlyphOrder(names)
    fb.setupCharacterMap({ord(c): "u%04X" % ord(c) for c in GLYPHS})
    glyphs = {".notdef": TTGlyphPen(None).glyph()}
    for c, rows in GLYPHS.items():
        glyphs["u%04X" % ord(c)] = glyph(rows)
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics({n: (6 * PX if n != ".notdef" else 4 * PX, 0) for n in names})
    fb.setupHorizontalHeader(ascent=750, descent=-150)
    fb.setupNameTable({"familyName": "ValeSimbolos", "styleName": "Regular"})
    fb.setupOS2(sTypoAscender=750, sTypoDescender=-150, usWinAscent=750, usWinDescent=150)
    fb.setupPost()
    path = os.path.join(ROOT, "assets", "fonts", "Simbolos.ttf")
    fb.save(path)
    print("Fonte de símbolos gerada:", path)


if __name__ == "__main__":
    main()
