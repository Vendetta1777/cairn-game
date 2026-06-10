extends Node2D
## Cairn — background cave detail (curated, not littered). Layered for depth:
## a hazy far formation band, a darker near formation band along the floor, a
## couple of soft light shafts, a few PURPOSEFUL glowing crystal clusters by
## landmarks, and a handful of feature vines. The top is left mostly empty/dark.

@export var bounds := Rect2(0, 0, 1440, 288)

const FAR := Color(0.125, 0.135, 0.2)     # hazy, recedes
const NEAR := Color(0.07, 0.08, 0.12)     # darker, closer
const HAZE := Color(0.22, 0.2, 0.34, 0.07)
const SHAFT := Color(0.72, 0.82, 0.98, 0.05)
const CRY := Color(0.34, 0.74, 0.7)
const CRY_HI := Color(0.66, 0.97, 0.9)
const VINE := Color(0.11, 0.21, 0.15)
const VINE_LEAF := Color(0.22, 0.42, 0.3)
const MOSS := Color(0.15, 0.32, 0.27, 0.45)

# Crystal clusters placed against the wall near landmarks (x, y).
const CRYSTAL_SPOTS := [Vector2(250, 150), Vector2(770, 100), Vector2(1190, 95)]
# Feature vines hanging from the ceiling at a few deliberate spots.
const VINE_SPOTS := [Vector2(120, 14), Vector2(540, 14), Vector2(905, 14), Vector2(1280, 14)]


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var w := bounds.size.x
	var h := bounds.size.y

	# Far hazy formation band (distant peaks) — light, sits mid-height.
	var x := -40.0
	while x < w + 40.0:
		draw_circle(Vector2(x, h - rng.randf_range(70.0, 120.0)), rng.randf_range(34.0, 60.0), FAR)
		x += rng.randf_range(70.0, 130.0)
	draw_rect(Rect2(0, h * 0.35, w, h * 0.45), HAZE)   # atmospheric haze over the far layer

	# Near formation band rising from the floor — darker, closer.
	x = -20.0
	while x < w + 20.0:
		var base := h - rng.randf_range(0.0, 18.0)
		for i in 4:
			draw_circle(Vector2(x + rng.randf_range(-18.0, 18.0), base - i * rng.randf_range(8.0, 16.0)),
				rng.randf_range(18.0, 32.0), NEAR)
		x += rng.randf_range(130.0, 210.0)

	# Two soft light shafts.
	for sx in [w * 0.3, w * 0.68]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx - 12.0, 14.0), Vector2(sx + 12.0, 14.0),
			Vector2(sx + 44.0, h), Vector2(sx + 12.0, h)]), SHAFT)

	# A few moss patches near the floor only.
	for i in 10:
		var mx := rng.randf() * w
		var my := h - rng.randf_range(10.0, 60.0)
		draw_rect(Rect2(mx, my, rng.randf_range(3.0, 7.0), rng.randf_range(2.0, 4.0)), MOSS)

	# Purposeful crystal clusters (3-4 shards each).
	for spot in CRYSTAL_SPOTS:
		for j in 4:
			var cp: Vector2 = spot + Vector2(rng.randf_range(-9.0, 9.0), rng.randf_range(-7.0, 7.0))
			var s := rng.randf_range(2.0, 4.5)
			draw_colored_polygon(PackedVector2Array([
				cp + Vector2(0, -s), cp + Vector2(s * 0.7, 0), cp + Vector2(0, s), cp + Vector2(-s * 0.7, 0)]), CRY)
			draw_circle(cp + Vector2(0, -s * 0.4), 0.9, CRY_HI)

	# A few feature vines (NOT across the whole ceiling).
	for v in VINE_SPOTS:
		_vine(v, rng.randf_range(34.0, 70.0), rng)


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
