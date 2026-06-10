extends Node2D
## Cairn — background cave detail, drawn behind the terrain to give the cave
## depth and theme: distant rock formations, embedded glowing wall-crystals,
## moss patches, soft light shafts, and hanging vines. Purely visual.

@export var bounds := Rect2(0, 0, 1440, 288)

const FAR_A := Color(0.075, 0.085, 0.125)
const FAR_B := Color(0.055, 0.063, 0.095)
const VINE := Color(0.11, 0.21, 0.15)
const VINE_LEAF := Color(0.22, 0.42, 0.3)
const VINE_HI := Color(0.36, 0.6, 0.4)
const WALL_CRY := Color(0.34, 0.74, 0.7)
const WALL_GLINT := Color(0.65, 0.96, 0.9)
const MOSS_BG := Color(0.15, 0.32, 0.27, 0.5)
const SHAFT := Color(0.72, 0.82, 0.98, 0.045)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var w := bounds.size.x
	var h := bounds.size.y

	# Distant rounded rock masses along the bottom (depth behind the platforms).
	var x := 0.0
	while x < w:
		var base := h - rng.randf_range(0.0, 24.0)
		for i in 6:
			draw_circle(Vector2(x + rng.randf_range(-22.0, 22.0), base - i * rng.randf_range(7.0, 15.0)),
				rng.randf_range(16.0, 34.0), FAR_A if rng.randf() > 0.5 else FAR_B)
		x += rng.randf_range(110.0, 190.0)

	# A couple of tall background columns.
	for cx in [w * 0.22, w * 0.58, w * 0.86]:
		for i in 9:
			draw_circle(Vector2(cx + rng.randf_range(-12.0, 12.0), h - i * 20.0),
				rng.randf_range(14.0, 24.0), FAR_B)

	# Soft light shafts from the ceiling.
	for sx in [w * 0.28, w * 0.66]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx - 12.0, 14.0), Vector2(sx + 12.0, 14.0),
			Vector2(sx + 46.0, h), Vector2(sx + 14.0, h)]), SHAFT)

	# Moss patches + embedded wall-crystals scattered on the back wall.
	for i in 26:
		var mx := rng.randf() * w
		var my := rng.randf_range(30.0, h - 50.0)
		draw_rect(Rect2(mx, my, rng.randf_range(3.0, 8.0), rng.randf_range(2.0, 4.0)), MOSS_BG)
	for i in 16:
		var px := rng.randf() * w
		var py := rng.randf_range(36.0, h - 60.0)
		var s := rng.randf_range(2.0, 4.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(px, py - s), Vector2(px + s * 0.7, py), Vector2(px, py + s), Vector2(px - s * 0.7, py)]), WALL_CRY)
		draw_circle(Vector2(px, py - s * 0.4), 0.8, WALL_GLINT)

	# Hanging vines from the ceiling, all across.
	x = 18.0
	while x < w - 18.0:
		_vine(Vector2(x, 14.0), rng.randf_range(22.0, 92.0), rng, 1.0)
		x += rng.randf_range(36.0, 74.0)


## A wavy hanging vine with leaves. alpha scales colors (for fg vs bg).
func _vine(top: Vector2, length: float, rng: RandomNumberGenerator, a: float) -> void:
	var seg := top
	var n := int(length / 8.0)
	for i in n:
		var nxt := seg + Vector2(rng.randf_range(-3.0, 3.0), 8.0)
		draw_line(seg, nxt, Color(VINE.r, VINE.g, VINE.b, a), rng.randf_range(1.0, 2.0))
		if i % 2 == 0:
			var side := 1.0 if rng.randf() > 0.5 else -1.0
			draw_circle(nxt + Vector2(side * 2.6, 0.0), rng.randf_range(1.4, 2.4), Color(VINE_LEAF.r, VINE_LEAF.g, VINE_LEAF.b, a))
		seg = nxt
	draw_circle(seg, 1.6, Color(VINE_HI.r, VINE_HI.g, VINE_HI.b, a))
