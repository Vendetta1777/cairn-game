extends Node2D
## Cairn — the parry ring: a bright white ring snapping outward, gone in a
## quarter second. The universal "you read that perfectly" stamp.

var _t := 0.0
const LIFE := 0.28


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var p := _t / LIFE
	var r := 8.0 + p * 42.0
	var a := 1.0 - p
	draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1, 1, 1, a), 3.0 * (1.0 - p) + 1.0)
	draw_arc(Vector2.ZERO, r * 0.8, 0, TAU, 32, Color(0.7, 0.85, 1.0, a * 0.5), 1.5)
