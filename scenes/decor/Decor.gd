extends Node2D
## Cairn — Area decoration spawner. Props are GROUNDED on real surfaces (their
## bottom sits on the given surface Y) and arranged in deliberate clusters, so
## nothing floats. Torches (warm light), crystal clusters (teal light), rocks,
## and cobwebs hanging from the ceiling. Purely visual.

const TORCH := preload("res://scenes/decor/Torch.tscn")
const TEX_CRYSTAL := [
	preload("res://assets/decor/crystal1.png"),
	preload("res://assets/decor/crystal2.png"),
	preload("res://assets/decor/crystal3.png"),
]
const TEX_ROCK := preload("res://assets/decor/rock1.png")
const TEX_WEB := preload("res://assets/decor/web.png")

# (x, surface_y) — surface_y is the top of the platform/floor the prop rests on.
const TORCHES := [
	Vector2(110, 252), Vector2(700, 252), Vector2(1390, 252),
	Vector2(360, 196), Vector2(200, 200), Vector2(700, 140),
	Vector2(1030, 160), Vector2(560, 178),
]
const CRYSTALS := [
	Vector2(70, 252), Vector2(450, 252), Vector2(850, 252), Vector2(1360, 252),
	Vector2(595, 178), Vector2(1000, 160), Vector2(1210, 124), Vector2(180, 200),
]
const ROCKS := [
	Vector2(290, 252), Vector2(315, 252), Vector2(520, 252), Vector2(990, 252),
	Vector2(1370, 252), Vector2(905, 200), Vector2(1185, 124), Vector2(660, 140),
]
const WEBS := [40.0, 440.0, 720.0, 960.0, 1400.0]   # x positions, hang from ceiling

var _light_tex: GradientTexture2D


func _ready() -> void:
	_light_tex = _make_radial()
	for p in TORCHES:
		var t := TORCH.instantiate()
		t.position = Vector2(p.x, p.y - 8.0)
		add_child(t)
	for p in CRYSTALS:
		_crystal_cluster(p.x, p.y)
	for p in ROCKS:
		_ground(TEX_ROCK, p.x, p.y, 0.55, 3.0, Color.WHITE)
	for wx in WEBS:
		_web(wx)


func _crystal_cluster(x: float, sy: float) -> void:
	var i := randi() % TEX_CRYSTAL.size()
	_ground(TEX_CRYSTAL[i], x, sy, 0.95, 2.0, Color.WHITE)
	_ground(TEX_CRYSTAL[(i + 1) % TEX_CRYSTAL.size()], x + 11.0, sy, 0.62, 2.0, Color.WHITE)
	var l := PointLight2D.new()
	l.position = Vector2(x + 4.0, sy - 12.0)
	l.color = Color(0.32, 0.82, 0.76)
	l.energy = 0.6
	l.texture = _light_tex
	l.texture_scale = 0.75
	add_child(l)


## Place a sprite so its BOTTOM rests on surface_y (no floating).
func _ground(tex: Texture2D, x: float, surface_y: float, scale_v: float, sink: float, mod: Color) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(scale_v, scale_v)
	s.position = Vector2(x, surface_y - tex.get_height() * scale_v * 0.5 + sink)
	s.modulate = mod
	add_child(s)


func _web(x: float) -> void:
	var s := Sprite2D.new()
	s.texture = TEX_WEB
	var sc := 0.5
	s.scale = Vector2(sc, sc)
	# Hang from the ceiling: top edge near y=14.
	s.position = Vector2(x, 14.0 + TEX_WEB.get_height() * sc * 0.5 - 6.0)
	s.modulate = Color(0.7, 0.72, 0.8, 0.3)
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
