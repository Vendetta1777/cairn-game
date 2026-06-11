extends Node2D
## Cairn — background cave detail. Layered ROCK STRATA for depth: four jagged
## silhouette bands rising from the floor (far/hazy -> near/dark), each carved
## with strata lines and dotted with stalagmites, plus light shafts, deliberate
## crystal clusters, and a few feature vines. No round "blob" rocks — real
## rocky edges. The architecture layer (huts/pillars) sits in front of these.

@export var bounds := Rect2(0, 0, 3700, 288)

# Strata bands, far -> near.
const BANDS := [
	{"top": 120.0, "amp": 30.0, "col": Color(0.13, 0.14, 0.205), "seed": 1.0, "step": 22.0, "jag": 5.0},
	{"top": 158.0, "amp": 36.0, "col": Color(0.10, 0.11, 0.165), "seed": 5.0, "step": 19.0, "jag": 7.0},
	{"top": 198.0, "amp": 40.0, "col": Color(0.072, 0.082, 0.125), "seed": 9.0, "step": 16.0, "jag": 9.0},
	{"top": 236.0, "amp": 26.0, "col": Color(0.05, 0.056, 0.088), "seed": 13.0, "step": 13.0, "jag": 7.0},
]
const STRATA_LINE := Color(0.2, 0.22, 0.3, 0.10)
const HAZE := Color(0.24, 0.22, 0.36, 0.06)
const SHAFT := Color(0.72, 0.82, 0.98, 0.05)
const CRY := Color(0.34, 0.74, 0.7)
const CRY_HI := Color(0.66, 0.97, 0.9)
const VINE := Color(0.11, 0.21, 0.15)
const VINE_LEAF := Color(0.22, 0.42, 0.3)
const MOSS := Color(0.15, 0.32, 0.27, 0.45)

const CRYSTAL_SPOTS := [Vector2(450, 150), Vector2(1300, 110), Vector2(2100, 120), Vector2(2600, 100)]
const VINE_SPOTS := [Vector2(220, 14), Vector2(900, 14), Vector2(1700, 14), Vector2(2400, 14)]


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var w := bounds.size.x
	var h := bounds.size.y

	# Soft atmospheric haze over the far half.
	draw_rect(Rect2(0, h * 0.3, w, h * 0.5), HAZE)

	# Two light shafts behind the rock (drawn first so rock occludes their base).
	for sx in [w * 0.3, w * 0.68]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx - 12.0, 14.0), Vector2(sx + 12.0, 14.0),
			Vector2(sx + 44.0, h), Vector2(sx + 12.0, h)]), SHAFT)

	# Layered rock strata, far to near.
	for band in BANDS:
		_draw_band(band, w, h, rng)

	# A few moss patches near the floor.
	for i in 12:
		var mx := rng.randf() * w
		var my := h - rng.randf_range(8.0, 56.0)
		draw_rect(Rect2(mx, my, rng.randf_range(3.0, 7.0), rng.randf_range(2.0, 4.0)), MOSS)

	# Purposeful crystal clusters.
	for spot in CRYSTAL_SPOTS:
		for j in 4:
			var cp: Vector2 = spot + Vector2(rng.randf_range(-9.0, 9.0), rng.randf_range(-7.0, 7.0))
			var s := rng.randf_range(2.0, 4.5)
			draw_colored_polygon(PackedVector2Array([
				cp + Vector2(0, -s), cp + Vector2(s * 0.7, 0), cp + Vector2(0, s), cp + Vector2(-s * 0.7, 0)]), CRY)
			draw_circle(cp + Vector2(0, -s * 0.4), 0.9, CRY_HI)

	# Feature vines.
	for v in VINE_SPOTS:
		_vine(v, rng.randf_range(34.0, 70.0), rng)


## One jagged rock band: a silhouette rising from the floor with a rocky top
## edge, internal strata lines, and a few stalagmite teeth.
func _draw_band(band: Dictionary, w: float, h: float, rng: RandomNumberGenerator) -> void:
	var top: float = band["top"]
	var amp: float = band["amp"]
	var seed: float = band["seed"]
	var step: float = band["step"]
	var jag: float = band["jag"]
	var col: Color = band["col"]

	var pts := PackedVector2Array([Vector2(-30.0, h + 20.0)])
	var edge: Array[Vector2] = []
	var x := -30.0
	while x <= w + 30.0:
		# Smooth rolling humps + a touch of rocky jag.
		var hump := (sin(x * 0.006 + seed) * 0.5 + 0.5) * amp \
			+ (sin(x * 0.017 + seed * 1.7) * 0.5 + 0.5) * amp * 0.45 \
			+ (sin(x * 0.041 + seed * 2.3)) * jag
		var y := top + amp - hump + rng.randf_range(-jag * 0.4, jag * 0.4)
		var p := Vector2(x, y)
		pts.append(p)
		edge.append(p)
		x += step
	pts.append(Vector2(w + 30.0, h + 20.0))
	draw_colored_polygon(pts, col)

	# Internal strata lines (a few faint horizontal-ish seams following the top).
	var lighter := Color(col.r + 0.04, col.g + 0.045, col.b + 0.06, 1.0)
	for s in range(1, 4):
		var line := PackedVector2Array()
		for e in edge:
			line.append(e + Vector2(0, s * 9.0))
		if line.size() > 1:
			draw_polyline(line, STRATA_LINE, 1.0)
	# A rim highlight along the very top edge.
	if edge.size() > 1:
		draw_polyline(PackedVector2Array(edge), lighter, 1.0)

	# Occasional stalagmite teeth on the top edge.
	var i := 2
	while i < edge.size() - 2:
		if rng.randf() > 0.78:
			var b: Vector2 = edge[i]
			var sh := rng.randf_range(8.0, 20.0)
			draw_colored_polygon(PackedVector2Array([
				b + Vector2(-4, 0), b + Vector2(4, 0), b + Vector2(0, -sh)]), col)
			draw_line(b + Vector2(0, -sh), b + Vector2(1, 0), lighter, 1.0)
		i += 1


func _vine(top: Vector2, length: float, rng: RandomNumberGenerator) -> void:
	var seg := top
	var n := int(length / 8.0)
	for i in n:
		var nxt := seg + Vector2(rng.randf_range(-3.0, 3.0), 8.0)
		draw_line(seg, nxt, VINE, rng.randf_range(1.0, 2.0))
		if i % 2 == 0:
			var side := 1.0 if rng.randf() > 0.5 else -1.0
			draw_circle(nxt + Vector2(side * 2.6, 0.0), rng.randf_range(1.4, 2.4), VINE_LEAF)
		seg = nxt
	draw_circle(seg, 1.6, VINE_LEAF)
