extends Node2D
## Cairn — buried-civilization backdrop. The deep was a kingdom; the player just
## arrived to find it silent. This draws a distant overgrown town skyline (with a
## few remnant window-lights still burning), and grand carved pillars + an arch
## framing the space — the architecture of a people who are gone. Hazy = depth.

@export var bounds := Rect2(0, 0, 3700, 288)

const TOWN_FAR := Color(0.115, 0.12, 0.175)
const TOWN_NEAR := Color(0.085, 0.09, 0.135)
const ROOF := Color(0.07, 0.075, 0.115)
const WIN_DARK := Color(0.04, 0.045, 0.07)
const WIN_LIT := Color(0.85, 0.55, 0.28)     # a few lights still burn
const PILLAR := Color(0.1, 0.105, 0.155)
const PILLAR_HI := Color(0.17, 0.19, 0.25)
const PILLAR_SH := Color(0.05, 0.055, 0.085)
const VINE := Color(0.1, 0.2, 0.14)
const VINE_LEAF := Color(0.2, 0.4, 0.28)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var w := bounds.size.x

	# Two town bands for depth: far (small, hazy, higher) then nearer (taller).
	_draw_town(rng, 234.0, 24.0, 70.0, TOWN_FAR, 36.0)
	_draw_town(rng, 250.0, 40.0, 120.0, TOWN_NEAR, 48.0)

	# Grand carved pillars rising floor->ceiling, with arches between them.
	var cols := [w * 0.17, w * 0.5, w * 0.83]
	for cx in cols:
		_draw_pillar(rng, cx, 250.0, 34.0)
	for i in cols.size() - 1:
		_draw_arch(cols[i], cols[i + 1], 70.0)


func _draw_town(rng: RandomNumberGenerator, base_y: float, min_h: float, max_h: float, col: Color, step: float) -> void:
	var x := -10.0
	while x < bounds.size.x + 10.0:
		var bw := rng.randf_range(step * 0.7, step * 1.3)
		var bh := rng.randf_range(min_h, max_h)
		var top := base_y - bh
		draw_rect(Rect2(x, top, bw, bh), col)
		# Roof: peaked or flat parapet.
		if rng.randf() > 0.5:
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - 1.0, top), Vector2(x + bw + 1.0, top), Vector2(x + bw * 0.5, top - bw * 0.45)]), ROOF)
		else:
			draw_rect(Rect2(x - 1.0, top - 3.0, bw + 2.0, 3.0), ROOF)
		# Windows grid — mostly dark, a rare warm light.
		var wy := top + 6.0
		while wy < base_y - 6.0:
			var wx := x + 4.0
			while wx < x + bw - 5.0:
				var lit := rng.randf() > 0.86
				draw_rect(Rect2(wx, wy, 2.5, 3.5), WIN_LIT if lit else WIN_DARK)
				wx += 7.0
			wy += 9.0
		x += bw + rng.randf_range(-2.0, 8.0)


func _draw_pillar(rng: RandomNumberGenerator, cx: float, floor_y: float, ceil_y: float) -> void:
	var pw := 11.0
	# Shaft with fluting.
	draw_rect(Rect2(cx - pw, ceil_y, pw * 2.0, floor_y - ceil_y), PILLAR)
	draw_rect(Rect2(cx - pw, ceil_y, 2.0, floor_y - ceil_y), PILLAR_HI)
	draw_rect(Rect2(cx + pw - 2.0, ceil_y, 2.0, floor_y - ceil_y), PILLAR_SH)
	for i in 3:
		draw_rect(Rect2(cx - pw * 0.5 + i * pw * 0.5, ceil_y, 1.0, floor_y - ceil_y), PILLAR_SH)
	# Base + capital blocks.
	draw_rect(Rect2(cx - pw - 4.0, floor_y - 10.0, pw * 2.0 + 8.0, 10.0), PILLAR)
	draw_rect(Rect2(cx - pw - 5.0, ceil_y, pw * 2.0 + 10.0, 9.0), PILLAR)
	draw_rect(Rect2(cx - pw - 5.0, ceil_y + 9.0, pw * 2.0 + 10.0, 2.0), PILLAR_HI)
	# Overgrown: a vine trailing down one side.
	var vx := cx + pw + 1.0
	var seg := Vector2(vx, ceil_y + 12.0)
	for i in int(rng.randf_range(6.0, 14.0)):
		var nxt := seg + Vector2(rng.randf_range(-2.0, 2.0), 9.0)
		draw_line(seg, nxt, VINE, 1.0)
		if i % 3 == 0:
			draw_circle(nxt + Vector2(2.0, 0.0), 1.8, VINE_LEAF)
		seg = nxt


func _draw_arch(x1: float, x2: float, top_y: float) -> void:
	# A shallow stone arch between two pillar capitals.
	var mid := (x1 + x2) * 0.5
	var rise := 18.0
	var pts := PackedVector2Array()
	var steps := 14
	for i in steps + 1:
		var t := float(i) / steps
		var px := lerpf(x1, x2, t)
		var py := top_y - sin(t * PI) * rise
		pts.append(Vector2(px, py))
	for i in steps + 1:
		var t := float(steps - i) / steps
		var px := lerpf(x1, x2, t)
		var py := top_y - sin(t * PI) * rise + 7.0
		pts.append(Vector2(px, py))
	draw_colored_polygon(pts, PILLAR)
