class_name FarmAnimal
extends Node2D
## Animal de criação: anda à toa dentro do cercado e aceita carinho (1x por dia).

const SPEED := 14.0

var kind: StringName
var record: Dictionary   # referência ao registro salvo no Ranch
var pen: Rect2

var _target := Vector2.ZERO
var _wait := 0.0
var _anim := 0.0
var _rng := RandomNumberGenerator.new()
var sprite: Sprite2D
var interactable: Interactable


func setup(animal_kind: StringName, rec: Dictionary, pen_rect: Rect2, info: Dictionary) -> FarmAnimal:
    kind = animal_kind
    record = rec
    pen = pen_rect
    sprite = Sprite2D.new()
    sprite.texture = load(info.young_sprite if rec.get("young", false) and info.has("young_sprite") else info.sprite)
    sprite.hframes = 4
    sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 1)
    add_child(sprite)
    interactable = Interactable.new()
    interactable.target_priority = 1
    var shape := CollisionShape2D.new()
    var c := CircleShape2D.new()
    c.radius = 10.0
    shape.shape = c
    shape.position = Vector2(0, -6)
    interactable.add_child(shape)
    add_child(interactable)
    interactable.prompt = "Fazer carinho na %s" % rec.get("name", info.name.to_lower()) if kind != &"touro" \
        else "Fazer carinho no %s" % rec.get("name", "touro")
    if rec.get("status", "ok") == "ferido":
        sprite.modulate = Color(1, 0.75, 0.75)
    interactable.interacted.connect(func(_a: Node) -> void: pet())
    position = Vector2(_rng.randf_range(pen.position.x, pen.end.x), _rng.randf_range(pen.position.y, pen.end.y))
    _target = position
    return self


## Levou um golpe num ataque: pisca e dá um pulinho de susto.
func flash() -> void:
    sprite.modulate = Color(2, 1.4, 1.4)
    var t := create_tween()
    t.tween_property(sprite, "modulate", Color(1, 0.75, 0.75), 0.2)
    _target = position + Vector2(randf_range(-12, 12), randf_range(-6, 6))


func pet() -> void:
    if int(record.get("pet_day", 0)) == GameState.day:
        EventBus.show_message("%s já ganhou carinho hoje. (felicidade %d)" % [record.get("name", ""), record.happiness], 1.5)
        return
    record.pet_day = GameState.day
    record.happiness = mini(100, int(record.happiness) + 8)
    GameState.add_xp(&"criacao", 3)
    EventBus.show_message("♥ %s ficou feliz! (felicidade %d)" % [record.get("name", ""), record.happiness], 1.5)


func _process(delta: float) -> void:
    if position.distance_to(_target) < 1.0:
        _wait -= delta
        _anim = 0.0
        if _wait <= 0.0:
            _target = Vector2(_rng.randf_range(pen.position.x, pen.end.x), _rng.randf_range(pen.position.y, pen.end.y))
            _wait = _rng.randf_range(1.5, 5.0)
    else:
        var dir := (_target - position).normalized()
        position += dir * SPEED * delta
        sprite.flip_h = dir.x < 0
        _anim += delta
    sprite.frame = int(_anim * 6.0) % 4
