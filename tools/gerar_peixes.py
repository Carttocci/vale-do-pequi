"""Gera data/fish/*.tres. Uso: python3 tools/gerar_peixes.py"""
import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
H = lambda h, m=0: h * 60 + m
# item, habitats, de, até, períodos, climas, dificuldade, peso
FISH = [
    ("lambari", ["lagoa", "rio"], H(6), H(26), [], [], 1, 10.0),
    ("traira", ["lagoa"], H(17), H(26), [], [], 2, 5.0),
    ("piau", ["rio"], H(6), H(18), [], [], 2, 8.0),
    ("tucunare", ["lagoa"], H(8), H(17), ["chuvoso"], [], 3, 4.0),
    ("pacu", ["rio"], H(10), H(18), ["chuvoso"], [], 3, 4.0),
    ("pintado", ["rio"], H(19), H(26), [], [], 4, 3.0),
    ("dourado", ["rio"], H(6), H(12), ["seco"], [], 4, 2.5),
    ("dourado_rei", ["rio"], H(20), H(26), ["chuvoso"], ["chuva", "tempestade"], 5, 0.4),
]
arr = lambda xs: "PackedStringArray(" + ", ".join(f'"{x}"' for x in xs) + ")"
os.makedirs(os.path.join(ROOT, "data", "fish"), exist_ok=True)
for (item, hab, a, b, per, w, dif, wt) in FISH:
    with open(os.path.join(ROOT, "data", "fish", f"{item}.tres"), "w") as f:
        f.write(f"""[gd_resource type="Resource" script_class="FishData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/fishing/fish_data.gd" id="1"]

[resource]
script = ExtResource("1")
item = &"{item}"
habitats = {arr(hab)}
from_minute = {a}
to_minute = {b}
periods = {arr(per)}
weathers = {arr(w)}
difficulty = {dif}
weight = {wt}
""")
print(len(FISH), "peixes")
