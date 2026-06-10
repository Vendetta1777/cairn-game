extends Node2D
## Cairn — Area decoration spawner. Scatters atmospheric props (animated torches
## with warm light, glowing teal crystals, rocks, cobwebs) from position lists,
## so the cave feels lived-in and lit. Purely visual (no collision).

const TORCH := preload("res://scenes/decor/Torch.tscn")
const TEX_CRYSTAL := [
	preload("res://assets/decor/crystal1.png"),
	preload("res://assets/decor/crystal2.png"),
	preload("res://assets/decor/crystal3.png"),
]
const TEX_ROCK := preload("res://assets/decor/rock1.png")
const TEX_WEB := preload("res://assets/decor/web.png")

# Standing/mounted torches (warm light pools).
const TORCHES := [
	Vector2(92, 246), Vector2(330, 246), Vector2(560, 168), Vector2(690, 246),
	Vector2(1130, 246), Vector2(1380, 246), Vector2(195, 194), Vector2(700, 132),
]
# Glowing crystals on ledges & floor corners.
const CRYSTALS := [
	Vector2(120, 248), Vector2(455, 248), Vector2(595, 174), Vector2(1000, 156),
	Vector2(1250, 120), Vector2(820, 248), Vector2(1355, 248), Vector2(360, 192),
]
# Rocks on the ground.
const ROCKS := [
	Vector2(280, 244), Vector2(520, 246), Vector2(905, 246), Vector2(1185, 246),
	Vector2(640, 246), Vector2(990, 246),
]
# Cobwebs in upper corners.
const WEBS := [
	Vector2(50, 30), Vector2(420, 28), Vector2(905, 26), Vector2(1390, 30),
]

var _light_tex: GradientTexture2D


func _ready() -> void:
	_light_tex = _make_radial()
	for p in TORCHES:
		var t := TORCH.instantiate()
		t.position = p
		add_child(t)
	for p in CRYSTALS:
		_crystal(p)
	for p in ROCKS:
		_sprite(TEX_ROCK, p, 0.6, Color.WHITE)
	for p in WEBS:
		_sprite(TEX_WEB, p, 0.5, Color(0.7, 0.72, 0.8, 0.32))


func _crystal(p: Vector2) -> void:
	var tex: Texture2D = TEX_CRYSTAL[randi() % TEX_CRYSTAL.size()]
	_sprite(tex, p, 0.85, Color.WHITE)
	var l := PointLight2D.new()
	l.position = p
	l.color = Color(0.32, 0.82, 0.76)
	l.energy = 0.6
	l.texture = _light_tex
	l.texture_scale = 0.7
	add_child(l)


func _sprite(tex: Texture2D, p: Vector2, scale_v: float, mod: Color) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = p
	s.scale = Vector2(scale_v, scale_v)
	s.modulate = mod
	add_child(s)


func _make_radial() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 128
	gt.height = 128
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	return gt
