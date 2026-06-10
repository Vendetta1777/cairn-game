extends Node2D
## Cairn — animated decoration hanging under the ceiling, layered for depth:
##   - a dense FAR curtain of fine vines (small, dim) behind
##   - sparser NEAR feature vines (larger, brighter) in front
##   - glowworms (pulsing glow on a swinging thread)
##   - crimson kingdom BANNERS, swaying (the deep was a civilisation)
## Redraws each frame so everything sways.

@export var bounds := Rect2(0, 0, 1440, 288)

const CEIL := 34.0
const VINE_FAR := Color(0.08, 0.16, 0.11)
const VINE := Color(0.12, 0.24, 0.16)
const VINE_LEAF := Color(0.24, 0.46, 0.32)
const VINE_HI := Color(0.4, 0.65, 0.44)
const THREAD := Color(0.2, 0.3, 0.24)
const ORB := Color(0.5, 0.92, 0.8)
const ORB_CORE := Color(0.88, 1.0, 0.92)
const CRIMSON := Color(0.46, 0.12, 0.15)
const CRIMSON_HI := Color(0.62, 0.19, 0.21)
const TRIM := Color(0.72, 0.58, 0.3)
const EMBLEM := Color(0.82, 0.7, 0.42)

const WORM_SPOTS := [240.0, 620.0, 1000.0, 1340.0]
const BANNER_SPOTS := [200.0, 720.0, 1240.0]

var _far: Array = []
var _near: Array = []
var _worms: Array = []
var _banners: Array = []
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var x := 22.0
	while x < bounds.size.x - 18.0:   # dense far curtain
		_far.append({"x": x, "len": rng.randf_range(12.0, 38.0), "ph": rng.randf() * TAU, "sway": rng.randf_range(1.5, 4.0)})
		x += rng.randf_range(24.0, 40.0)
	x = 40.0
	while x < bounds.size.x - 40.0:   # sparse near features
		_near.append({"x": x, "len": rng.randf_range(28.0, 80.0), "ph": rng.randf() * TAU, "sway": rng.randf_range(4.0, 9.0)})
		x += rng.randf_range(70.0, 120.0)

	var tex := _radial()
	for gx in WORM_SPOTS:
		var l := PointLight2D.new()
		l.color = ORB
		l.energy = 0.6
		l.texture = tex
		l.texture_scale = 0.6
		add_child(l)
		_worms.append({"x": gx, "len": rng.randf_range(34.0, 60.0), "ph": rng.randf() * TAU, "light": l})
	for bx in BANNER_SPOTS:
		_banners.append({"x": bx, "ph": rng.randf() * TAU, "h": rng.randf_range(40.0, 54.0)})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	for g in _worms:
		var sx: float = sin(_t * 1.1 + g["ph"]) * 7.0
		g["light"].position = Vector2(g["x"] + sx, CEIL + g["len"])
		g["light"].energy = 0.55 + 0.25 * (0.5 + 0.5 * sin(_t * 2.5 + g["ph"]))


func _draw() -> void:
	for v in _far:
		_vine(v, VINE_FAR, VINE_FAR, 1.0, 1.1)
	for v in _near:
		_vine(v, VINE, VINE_LEAF, 1.5, 1.4)
	for b in _banners:
		_banner(b)
	for g in _worms:
		var sx: float = sin(_t * 1.1 + g["ph"]) * 7.0
		var endp := Vector2(g["x"] + sx, CEIL + g["len"])
		draw_line(Vector2(g["x"], CEIL), endp, THREAD, 1.0)
		var pulse: float = 0.5 + 0.5 * sin(_t * 2.5 + g["ph"])
		draw_circle(endp, 4.5, Color(ORB.r, ORB.g, ORB.b, 0.35 * pulse))
		draw_circle(endp, 2.2, ORB)
		draw_circle(endp, 1.0, ORB_CORE)


func _vine(v: Dictionary, col: Color, leaf: Color, width: float, speed: float) -> void:
	var n := int(v["len"] / 8.0)
	var vx: float = v["x"]
	var seg := Vector2(vx, CEIL)
	for i in n:
		var depth: float = float(i + 1) / float(maxi(n, 1))
		var sx: float = sin(_t * speed + v["ph"] + depth * 2.5) * v["sway"] * depth
		var nxt := Vector2(vx + sx, CEIL + float(i + 1) * 8.0)
		draw_line(seg, nxt, col, width)
		if i % 2 == 0 and width > 1.0:
			var side := 2.6 if i % 4 == 0 else -2.6
			draw_circle(nxt + Vector2(side, 0.0), 2.0, leaf)
		seg = nxt
	if width > 1.0:
		draw_circle(seg, 1.8, VINE_HI)


func _banner(b: Dictionary) -> void:
	var bx: float = b["x"]
	var top := CEIL
	var hw := 9.0
	var h: float = b["h"]
	var sway: float = sin(_t * 0.8 + b["ph"]) * 4.0
	var bl := Vector2(bx - hw + sway, top + h)
	var br := Vector2(bx + hw + sway, top + h)
	var notch := Vector2(bx + sway, top + h - 9.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(bx - hw, top), Vector2(bx + hw, top), br, notch, bl]), CRIMSON)
	draw_line(Vector2(bx - hw + 2.0, top), bl + Vector2(2.0, 0.0), CRIMSON_HI, 1.0)
	draw_rect(Rect2(bx - hw - 1.0, top - 2.0, hw * 2.0 + 2.0, 3.0), TRIM)   # gold rod
	var ec := Vector2(bx + sway * 0.5, top + h * 0.42)
	draw_colored_polygon(PackedVector2Array([
		ec + Vector2(0, -4), ec + Vector2(3, 0), ec + Vector2(0, 4), ec + Vector2(-3, 0)]), EMBLEM)


func _radial() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 64
	gt.height = 64
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	return gt
