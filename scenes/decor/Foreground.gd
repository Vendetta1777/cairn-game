extends Node2D
## Cairn — foreground framing, drawn IN FRONT of the player for depth: near-black
## rock masses in the top corners, a few big vines hanging in front, and a faint
## fog band along the bottom. Kept sparse so it frames without blocking play.

@export var bounds := Rect2(0, 0, 1440, 288)

const FG_ROCK := Color(0.02, 0.025, 0.04)
const FG_VINE := Color(0.05, 0.1, 0.07, 0.8)
const FG_LEAF := Color(0.1, 0.22, 0.15, 0.8)
const FOG := Color(0.1, 0.09, 0.16, 0.22)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var w := bounds.size.x
	var h := bounds.size.y

	# Near-black rock masses framing the top corners.
	for corner in [Vector2(0.0, 0.0), Vector2(w, 0.0)]:
		for i in 9:
			draw_circle(corner + Vector2(rng.randf_range(-34.0, 34.0), rng.randf_range(0.0, 56.0)),
				rng.randf_range(22.0, 46.0), FG_ROCK)

	# Big foreground vines hanging in front of the action.
	for fx in [w * 0.16, w * 0.52, w * 0.84]:
		_vine(Vector2(fx, 14.0), rng.randf_range(70.0, 130.0), rng)

	# Faint fog along the bottom.
	draw_rect(Rect2(0.0, h - 42.0, w, 42.0), FOG)


func _vine(top: Vector2, length: float, rng: RandomNumberGenerator) -> void:
	var seg := top
	var n := int(length / 8.0)
	for i in n:
		var nxt := seg + Vector2(rng.randf_range(-3.5, 3.5), 8.0)
		draw_line(seg, nxt, FG_VINE, rng.randf_range(2.0, 3.0))
		if i % 2 == 0:
			var side := 1.0 if rng.randf() > 0.5 else -1.0
			draw_circle(nxt + Vector2(side * 3.2, 0.0), rng.randf_range(2.0, 3.2), FG_LEAF)
		seg = nxt
