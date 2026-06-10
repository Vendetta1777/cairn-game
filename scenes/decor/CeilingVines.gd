extends Node2D
## Cairn — animated decoration hanging UNDER the ceiling: vines that gently sway
## and a few glowworms (a thread with a pulsing glow on the end that swings).
## Redraws each frame for the sway animation. Hangs from the rocky ceiling.

@export var bounds := Rect2(0, 0, 1440, 288)

const CEIL := 34.0
const VINE := Color(0.12, 0.24, 0.16)
const VINE_LEAF := Color(0.24, 0.46, 0.32)
const VINE_HI := Color(0.4, 0.65, 0.44)
const THREAD := Color(0.2, 0.3, 0.24)
const ORB := Color(0.5, 0.92, 0.8)
const ORB_CORE := Color(0.88, 1.0, 0.92)

const WORM_SPOTS := [240.0, 620.0, 1000.0, 1340.0]

var _vines: Array = []
var _worms: Array = []
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var x := 30.0
	while x < bounds.size.x - 30.0:
		_vines.append({"x": x, "len": rng.randf_range(24.0, 80.0), "ph": rng.randf() * TAU, "sway": rng.randf_range(3.0, 8.0)})
		x += rng.randf_range(52.0, 86.0)

	var tex := _radial()
	for gx in WORM_SPOTS:
		var l := PointLight2D.new()
		l.color = ORB
		l.energy = 0.6
		l.texture = tex
		l.texture_scale = 0.6
		add_child(l)
		_worms.append({"x": gx, "len": rng.randf_range(34.0, 60.0), "ph": rng.randf() * TAU, "light": l})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	for g in _worms:
		var sx: float = sin(_t * 1.1 + g["ph"]) * 7.0
		g["light"].position = Vector2(g["x"] + sx, CEIL + g["len"])
		g["light"].energy = 0.55 + 0.25 * (0.5 + 0.5 * sin(_t * 2.5 + g["ph"]))


func _draw() -> void:
	for v in _vines:
		var n := int(v["len"] / 8.0)
		var vx: float = v["x"]
		var seg := Vector2(vx, CEIL)
		for i in n:
			var depth: float = float(i + 1) / float(maxi(n, 1))
			var sx: float = sin(_t * 1.4 + v["ph"] + depth * 2.5) * v["sway"] * depth
			var nxt := Vector2(vx + sx, CEIL + float(i + 1) * 8.0)
			draw_line(seg, nxt, VINE, 1.5)
			if i % 2 == 0:
				var side := 2.6 if i % 4 == 0 else -2.6
				draw_circle(nxt + Vector2(side, 0.0), 2.0, VINE_LEAF)
			seg = nxt
		draw_circle(seg, 1.8, VINE_HI)

	for g in _worms:
		var sx: float = sin(_t * 1.1 + g["ph"]) * 7.0
		var endp := Vector2(g["x"] + sx, CEIL + g["len"])
		draw_line(Vector2(g["x"], CEIL), endp, THREAD, 1.0)
		var pulse: float = 0.5 + 0.5 * sin(_t * 2.5 + g["ph"])
		draw_circle(endp, 4.5, Color(ORB.r, ORB.g, ORB.b, 0.35 * pulse))
		draw_circle(endp, 2.2, ORB)
		draw_circle(endp, 1.0, ORB_CORE)


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
