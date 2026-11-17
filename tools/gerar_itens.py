"""
Gera data/items/*.tres a partir da tabela abaixo (fonte única dos itens).
Uso: python3 tools/gerar_itens.py   — rode depois de editar a tabela.

Categorias (ItemData.Category): 0 TOOL 1 SEED 2 CROP 3 FORAGE 4 MATERIAL
5 FISH 6 ANIMAL_PRODUCT 7 WEAPON 8 FOOD 9 PLACEABLE 10 MINERAL 11 QUEST
Ferramentas (ToolType): 1 enxada 2 regador 3 vara 4 picareta
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
E = lambda t: json.dumps(t, ensure_ascii=False)

# id, nome, descrição, categoria, pilha, venda, compra, extras(dict)
ITEMS = [
    ("enxada", "Enxada", "Capina a terra para plantar. Era do seu avô.", 0, 1, 0, 0, {"tool_type": 1}),
    ("regador", "Regador", "Rega a terra capinada. Encha no poço ou na lagoa.", 0, 1, 0, 0, {"tool_type": 2}),
    ("semente_milho", "Semente de milho", "Milho: 4 dias regados. Só no período chuvoso.", 1, 99, 5, 10, {"crop_id": "milho"}),
    ("semente_feijao", "Semente de feijão", "Feijão: 3 dias regados e continua produzindo. O ano todo.", 1, 99, 4, 8, {"crop_id": "feijao"}),
    ("semente_abobora", "Semente de abóbora", "Abóbora: 6 dias regados. Só no período chuvoso.", 1, 99, 8, 16, {"crop_id": "abobora"}),
    ("semente_mandioca", "Rama de mandioca", "Mandioca: 8 dias regados. Aguenta o ano todo.", 1, 99, 10, 20, {"crop_id": "mandioca"}),
    ("milho", "Milho", "Espiga fresquinha.", 2, 99, 15, 0, {}),
    ("feijao", "Feijão", "Um punhado de feijão.", 2, 99, 10, 0, {}),
    ("abobora", "Abóbora", "Abóbora madura e pesada.", 2, 99, 35, 0, {}),
    ("mandioca", "Mandioca", "Raiz de mandioca, pronta pra cozinhar ou virar farinha.", 2, 99, 40, 0, {}),
    ("pequi", "Pequi", "Fruto do Cerrado. Cuidado com os espinhos do caroço!", 3, 99, 12, 0, {}),
    # Fase 5 — pesca
    ("vara_bambu", "Vara de bambu", "Vara simples. Use de frente para a água. Precisa de isca.", 0, 1, 0, 60, {"tool_type": 3}),
    ("isca", "Minhoca", "Isca para pescar. Uma por lançada.", 4, 99, 1, 2, {}),
    ("lambari", "Lambari", "Pequeno e prateado. Vive em bando na lagoa.", 5, 99, 8, 0, {}),
    ("traira", "Traíra", "Dentuça e brava. Gosta de água parada.", 5, 99, 20, 0, {}),
    ("piau", "Piau", "Peixe de rio, listrado e esperto.", 5, 99, 25, 0, {}),
    ("tucunare", "Tucunaré", "Tem uma pinta no rabo que parece um olho.", 5, 99, 35, 0, {}),
    ("pacu", "Pacu", "Redondo e forte. Come fruta que cai no rio.", 5, 99, 40, 0, {}),
    ("pintado", "Pintado", "Bagre grande e pintado. Sai mais à noite.", 5, 99, 60, 0, {}),
    ("dourado", "Dourado", "O rei do rio: briga muito e brilha como ouro.", 5, 99, 90, 0, {}),
    ("dourado_rei", "Dourado-rei", "Lendário. Dizem que só aparece em noite de chuva no Rio das Araras.", 5, 1, 600, 0, {}),
    # Fase 5 — criação e caça
    ("racao", "Ração", "Comida para os animais. Coloque no comedouro.", 4, 99, 2, 4, {}),
    ("ovo", "Ovo caipira", "Fresquinho do galinheiro.", 6, 99, 12, 0, {}),
    ("leite", "Leite", "Leite tirado na hora.", 6, 99, 25, 0, {}),
    ("carne_javali", "Carne de javali", "O javali é invasor e destrói as roças. A caça dele é controle.", 6, 99, 45, 0, {}),
    ("couro", "Couro", "Couro curtido. Serve para artesanato.", 4, 99, 30, 0, {}),
    ("armadilha", "Armadilha de javali", "Arme na Mata dos Ipês. Na manhã seguinte pode ter javali.", 9, 20, 10, 40,
     {"place_scene": "res://scenes/mata/armadilha.tscn", "place_regions": ["mata"]}),
    # Fase 6 — combate
    ("facao", "Facão", "Rápido e equilibrado. Era do seu avô.", 7, 1, 20, 80,
     {"damage": 10, "attack_cooldown": 0.3, "reach": 16.0, "arc_width": 22.0, "knockback": 100.0}),
    ("espada", "Espada", "Equilíbrio entre velocidade e dano.", 7, 1, 80, 320,
     {"damage": 15, "attack_cooldown": 0.4, "reach": 18.0, "arc_width": 24.0, "knockback": 120.0}),
    ("machado", "Machado", "Golpe pesado que quebra defesas.", 7, 1, 70, 280,
     {"damage": 22, "attack_cooldown": 0.65, "reach": 16.0, "arc_width": 22.0, "knockback": 170.0}),
    ("lanca", "Lança", "Alcance maior: mantém o bicho longe.", 7, 1, 70, 280,
     {"damage": 14, "attack_cooldown": 0.5, "reach": 28.0, "arc_width": 12.0, "knockback": 140.0}),
    ("martelo", "Martelo", "Impacto que atordoa.", 7, 1, 100, 420,
     {"damage": 26, "attack_cooldown": 0.8, "reach": 16.0, "arc_width": 26.0, "knockback": 200.0, "stun": 0.8}),
    ("arco", "Arco", "Ataque de longe. Gasta flechas.", 7, 1, 90, 360,
     {"damage": 12, "attack_cooldown": 0.55, "reach": 160.0, "ranged": True, "ammo_item": "flecha"}),
    ("flecha", "Flecha", "Munição para o arco.", 4, 99, 1, 5, {}),
    ("madeira", "Madeira", "Pedaço de madeira. Serve para artesanato.", 4, 99, 3, 0, {}),
    # Fase 7 — mineração e aventura
    ("picareta", "Picareta", "Quebra pedras e minérios. Gasta energia.", 0, 1, 0, 200, {"tool_type": 4}),
    ("pedra", "Pedra", "Pedra comum. Serve para construir.", 10, 99, 2, 0, {}),
    ("minerio_ferro", "Minério de ferro", "O Toninho transforma isso em ferramenta.", 10, 99, 15, 0, {}),
    ("quartzo", "Quartzo", "Cristal transparente da Serra do Cristal.", 10, 99, 30, 0, {}),
    ("ouro", "Pepita de ouro", "Goiás nasceu da corrida do ouro. Ainda tem um pouco na serra.", 10, 99, 120, 0, {}),
    ("cristal_vale", "Cristal do Vale", "Brilha sozinho no escuro. Faz um zumbido baixinho.", 10, 99, 250, 0, {}),
    ("coracao_cristal", "Coração de cristal", "Pulsava dentro do Guardião. Está frio como o Silêncio.", 11, 1, 0, 0, {}),
    ("fragmento_silencio", "Fragmento do Silêncio", "Caco frio e sem som que sobra das criaturas corrompidas.", 11, 99, 0, 0, {}),
]

TEMPLATE = """[gd_resource type="Resource" script_class="ItemData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/inventory/item_data.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/items/{icon}_placeholder.png" id="2"]

[resource]
script = ExtResource("1")
id = &"{id}"
display_name = {name}
description = {desc}
icon = ExtResource("2")
category = {cat}
max_stack = {mx}
sell_price = {sell}
buy_price = {buy}
{extras}"""


def fmt(k, v):
    if isinstance(v, bool):
        return f"{k} = {'true' if v else 'false'}"
    if isinstance(v, (int, float)):
        return f"{k} = {v}"
    if isinstance(v, list):
        return f"{k} = PackedStringArray(" + ", ".join(E(x) for x in v) + ")"
    if k in ("crop_id", "ammo_item", "buff"):
        return f'{k} = &"{v}"'
    return f"{k} = {E(v)}"


if __name__ == "__main__":
    out = os.path.join(ROOT, "data", "items")
    os.makedirs(out, exist_ok=True)
    for (iid, name, desc, cat, mx, sell, buy, extra) in ITEMS:
        extras = "\n".join(fmt(k, v) for k, v in extra.items())
        icon = extra.get("icon", iid)
        extra.pop("icon", None)
        text = TEMPLATE.format(id=iid, name=E(name), desc=E(desc), icon=icon, cat=cat, mx=mx, sell=sell, buy=buy,
                               extras=(extras + "\n") if extras else "")
        with open(os.path.join(out, f"{iid}.tres"), "w", encoding="utf-8") as f:
            f.write(text)
    print(f"{len(ITEMS)} itens gerados.")
