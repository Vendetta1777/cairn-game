extends Node2D
## Cairn — buried-civilization backdrop. The deep was a kingdom; you just arrived
## to find it silent. Instead of a generic city skyline this draws clustered ROCK
## HUTS — squat carved-stone dwellings terraced into the rock face, with arched
## doorways and a few windows where a remnant light still burns — framed by grand
## carved pillars and arches. Two depth bands (far/hazy, near) read as a village
## climbing the cavern wall.

@export var bounds := Rect2(0, 0, 3700, 288)

const HUT_FAR := Color(0.125, 0.13, 0.185)
const HUT_NEAR := Color(0.092, 0.097, 0.142)
const HUT_CAP := Color(0.15, 0.16, 0.215)     # lit top edge of the dwelling
const HUT_SH := Color(0.055, 0.06, 0.092)      # shaded side
const DOOR := Color(0.03, 0.035, 0.055)
const WIN_DARK := Color(0.045, 0.05, 0.075)
const WIN_LIT := Color(0.92, 0.58, 0.3)        # a remnant hearth
const WIN_GLOW := Color(0.95, 0.6, 0.32, 0.14)
const PILLAR := Color(0.1, 0.105, 0.155)
const PILLAR_HI := Color(0.17, 0.19, 0.25)
const PILLAR_SH := Color(0.05, 0.055, 0.085)
const VINE := Color(0.1, 0.2, 0.14)
const VINE_LEAF := Color(0.2, 0.4, 0.28)

# Village clusters: x-centre of each huddle of dwellings.
const FAR_VILLAGES := [360.0, 1150.0, 2050.0, 3050.0]
const NEAR_VILLAGES := [700.0, 1600.0, 2750.0, 3380.0]


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21

	# Far band: small, hazy dwellings high on the wall.
	for vx in FAR_VILLAGES:
		_draw_village(rng, vx, 226.0, 0.7, HUT_FAR, 0.10)
	# Near band: larger dwellings nearer the floor.
	for vx in NEAR_VILLAGES:
		_draw_village(rng, vx, 250.0, 1.0, HUT_NEAR, 0.16)

	# Grand carved pillars + arches framing the space.
	var w := bounds.size.x
	var cols := [w * 0.17, w * 0.5, w * 0.83]
	for cx in cols:
		_draw_pillar(rng, cx, 250.0, 34.0)
	for i in cols.size() - 1:
		_draw_arch(cols[i], cols[i + 1], 70.0)


## A huddle of 3–5 terraced rock huts around a centre.
func _draw_village(rng: RandomNumberGenerator, cx: float, base_y: float, scale: float, col: Color, lit_chance: float) -> void:
	var n := rng.randi_range(3, 5)
	var x := cx - n * 22.0 * scale
	for i in n:
		var hw := rng.randf_range(16.0, 26.0) * scale
		var hh := rng.randf_range(22.0, 40.0) * scale
		var terrace := rng.randf_range(-6.0, 10.0) * scale   # step huts up/down the slope
		_draw_hut(rng, x + hw, base_y - terrace, hw, hh, col, lit_chance)
		x += hw * rng.randf_range(1.7, 2.2)


## One carved-stone dwelling: a tapered body, a stepped cap, an arched doorway,
## and a window or two (rarely lit). cx,base = bottom-centre.
func _draw_hut(rng: RandomNumberGenerator, cx: float, base_y: float, hw: float, hh: float, col: Color, lit_chance: float) -> void:
	var top := base_y - hh
	# Body: slightly wider at the base (battered stone walls).
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - hw, base_y), Vector2(cx + hw, base_y),
		Vector2(cx + hw * 0.82, top), Vector2(cx - hw * 0.82, top)]), col)
	# Shaded right face for a touch of form.
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + hw, base_y), Vector2(cx + hw * 0.82, top),
		Vector2(cx + hw * 0.55, top), Vector2(cx + hw * 0.7, base_y)]), HUT_SH)
	# Cap: a stepped/peaked stone roof.
	if rng.randf() > 0.45:
		# Peaked.
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - hw * 0.9, top + 1.0), Vector2(cx + hw * 0.9, top + 1.0),
			Vector2(cx, top - hh * 0.32)]), col)
		draw_line(Vector2(cx - hw * 0.9, top + 1.0), Vector2(cx, top - hh * 0.32), HUT_CAP, 1.0)
	else:
		# Flat stepped parapet.
		draw_rect(Rect2(cx - hw * 0.92, top - 3.0, hw * 1.84, 3.0), col)
		draw_rect(Rect2(cx - hw * 0.92, top - 3.0, hw * 1.84, 1.0), HUT_CAP)
	# Lit top edge.
	draw_line(Vector2(cx - hw * 0.82, top), Vector2(cx + hw * 0.82, top), HUT_CAP, 1.0)

	# Arched doorway at the base centre.
	var dw := hw * 0.34
	var dh := hh * 0.5
	draw_rect(Rect2(cx - dw, base_y - dh, dw * 2.0, dh), DOOR)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - dw, base_y - dh), Vector2(cx + dw, base_y - dh), Vector2(cx, base_y - dh - dw)]), DOOR)

	# A window or two — usually dark, rarely a warm hearth.
	var wy := top + hh * 0.28
	var slots := [-hw * 0.5, hw * 0.5]
	for sx in slots:
		if rng.randf() > 0.4:
			var lit := rng.randf() < lit_chance / 0.6
			var c := WIN_LIT if lit else WIN_DARK
			var wp := Vector2(cx + sx, wy)
			if lit:
				draw_circle(wp + Vector2(1.0, 1.5), 5.0, WIN_GLOW)
			draw_rect(Rect2(wp.x, wp.y, 2.6, 3.4), c)


func _draw_pillar(rng: RandomNumberGenerator, cx: float, floor_y: float, ceil_y: float) -> void:
	var pw := 11.0
	draw_rect(Rect2(cx - pw, ceil_y, pw * 2.0, floor_y - ceil_y), PILLAR)
	draw_rect(Rect2(cx - pw, ceil_y, 2.0, floor_y - ceil_y), PILLAR_HI)
	draw_rect(Rect2(cx + pw - 2.0, ceil_y, 2.0, floor_y - ceil_y), PILLAR_SH)
	for i in 3:
		draw_rect(Rect2(cx - pw * 0.5 + i * pw * 0.5, ceil_y, 1.0, floor_y - ceil_y), PILLAR_SH)
	draw_rect(Rect2(cx - pw - 4.0, floor_y - 10.0, pw * 2.0 + 8.0, 10.0), PILLAR)
	draw_rect(Rect2(cx - pw - 5.0, ceil_y, pw * 2.0 + 10.0, 9.0), PILLAR)
	draw_rect(Rect2(cx - pw - 5.0, ceil_y + 9.0, pw * 2.0 + 10.0, 2.0), PILLAR_HI)
	var seg := Vector2(cx + pw + 1.0, ceil_y + 12.0)
	for i in int(rng.randf_range(6.0, 14.0)):
		var nxt := seg + Vector2(rng.randf_range(-2.0, 2.0), 9.0)
		draw_line(seg, nxt, VINE, 1.0)
		if i % 3 == 0:
			draw_circle(nxt + Vector2(2.0, 0.0), 1.8, VINE_LEAF)
		seg = nxt


func _draw_arch(x1: float, x2: float, top_y: float) -> void:
	var rise := 18.0
	var pts := PackedVector2Array()
	var steps := 14
	for i in steps + 1:
		var t := float(i) / steps
		pts.append(Vector2(lerpf(x1, x2, t), top_y - sin(t * PI) * rise))
	for i in steps + 1:
		var t := float(steps - i) / steps
		pts.append(Vector2(lerpf(x1, x2, t), top_y - sin(t * PI) * rise + 7.0))
	draw_colored_polygon(pts, PILLAR)
