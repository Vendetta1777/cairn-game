extends Node2D
## Cairn — foreground framing (in front of the player). A dark fade across the
## empty top, subtle corner rock masses, a couple of foreground vines, and a
## faint bottom fog. Kept restrained so it frames the scene, not blocks it.

@export var bounds := Rect2(0, 0, 2800, 288)

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

	# A couple of foreground vines hanging from the ceiling, off to the sides.
	for fx in [w * 0.1, w * 0.9]:
		_vine(Vector2(fx, 34.0), rng.randf_range(70.0, 120.0), rng)

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
