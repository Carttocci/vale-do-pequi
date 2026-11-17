@tool
class_name FenceLine
extends Node2D
## Cerca reta, montada a partir de um comprimento em tiles.
## Uma única colisão cobre o trecho todo (mais leve que um corpo por mourão).
## É @tool para aparecer no editor enquanto você ajusta os valores.

const TILE := 16
const TEX_H: Texture2D = preload("res://assets/environments/cerca_placeholder.png")
const TEX_V: Texture2D = preload("res://assets/environments/cerca_vertical_placeholder.png")

## Quantidade de trechos de 16 px.
@export var length_tiles: int = 4:
    set(value):
        length_tiles = maxi(1, value)
        _rebuild()
@export var vertical: bool = false:
    set(value):
        vertical = value
        _rebuild()


func _ready() -> void:
    _rebuild()


func _rebuild() -> void:
    if not is_inside_tree():
        return
    for child in get_children():
        remove_child(child)
        child.queue_free()

    var step := Vector2(0, TILE) if vertical else Vector2(TILE, 0)
    for i in length_tiles:
        var s := Sprite2D.new()
        s.texture = TEX_V if vertical else TEX_H
        s.centered = true
        # Origem do trecho = base do mourão (para o y-sort funcionar).
        s.position = step * i
        s.offset = Vector2(0, -8)
        add_child(s)

    var body := StaticBody2D.new()
    body.collision_layer = 1
    body.collision_mask = 0
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    if vertical:
        rect.size = Vector2(6, TILE * length_tiles)
        shape.position = Vector2(0, TILE * (length_tiles - 1) * 0.5 - 8)
    else:
        rect.size = Vector2(TILE * length_tiles, 6)
        shape.position = Vector2(TILE * (length_tiles - 1) * 0.5, -3)
    shape.shape = rect
    body.add_child(shape)
    add_child(body)
