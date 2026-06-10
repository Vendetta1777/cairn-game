extends Node2D
## Cairn — foreground framing (in front of the player). A dark fade across the
## empty top, subtle corner rock masses, a couple of foreground vines, and a
## faint bottom fog. Kept restrained so it frames the scene, not blocks it.

@export var bounds := Rect2(0, 0, 1440, 288)

const FG_ROCK := Color(0.02, 0.025, 0.04)
const FG_VINE := Color(0.05, 0.1, 0.07, 0.8)
const FG_LEAF := Color(0.1, 0.22, 0.15, 0.8)
const FOG := Color(0.1, 0.09, 0.16, 0.22)
const TOP_DARK := Color(0.012, 0.014, 0.022)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var w := bounds.size.x
	var h := bounds.size.y

	# Dark gradient over the empty top — nothing important is up there.
	for i in 30:
		var a := 0.72 * (1.0 - float(i) / 30.0)
		draw_rect(Rect2(0.0, i * 2.0, w, 2.0), Color(TOP_DARK.r, TOP_DARK.g, TOP_DARK.b, a))

	# Subtle near-black rock framing in the top corners.
	for corner in [Vector2(0.0, 0.0), Vector2(w, 0.0)]:
		for i in 6:
			draw_circle(corner + Vector2(rng.randf_range(-26.0, 26.0), rng.randf_range(0.0, 44.0)),
				rng.randf_range(18.0, 36.0), FG_ROCK)

	# A couple of foreground vines, off to the sides.
	for fx in [w * 0.12, w * 0.88]:
		_vine(Vector2(fx, 14.0), rng.randf_range(60.0, 110.0), rng)

	# Faint fog along the bottom.
	draw_rect(Rect2(0.0, h - 38.0, w, 38.0), FOG)


func _vine(top: Vector2, length: float, rng: RandomNumberGenerator) -> void:
	var seg := top
	var n := int(length / 8.0)
	for i in n:
		var nxt := seg + Vector2(rng.randf_range(-3.5, 3.5), 8.0)
		draw_line(seg, nxt, FG_VINE, rng.randf_range(2.0, 3.0))
		if i % 2 == 0:
			var side := 1.0 if rng.randf() > 0.5 else -1.0
			draw_circle(nxt + Vector2(side * 3.2, 0.0), rng.randf_range(2.0, 3.0), FG_LEAF)
		seg = nxt
