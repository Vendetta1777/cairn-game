extends Node2D
## Cairn — the Buried King's crown, fallen and permanent: a quiet gold glint in
## the arena dust after the fight. Spawned on his death; the Warrens root also
## places it on every return visit (flag boss_buried_king_dead).

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var gold := Color(0.72, 0.6, 0.3)
	var gold_d := Color(0.48, 0.39, 0.2)
	# Tilted into the rubble.
	draw_set_transform(Vector2.ZERO, -0.18, Vector2.ONE)
	draw_rect(Rect2(-11, -8, 22, 7), gold)
	draw_rect(Rect2(-11, -2, 22, 2), gold_d)
	for k in 3:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-10 + k * 8, -8), Vector2(-7 + k * 8, -15), Vector2(-4 + k * 8, -8)]), gold)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# A patient glint.
	var glint := 0.3 + 0.3 * maxf(0.0, sin(_t * 0.8))
	draw_circle(Vector2(-3, -10), 1.2, Color(1.0, 0.95, 0.8, glint))
	draw_circle(Vector2(0, -4), 20.0, Color(1.0, 0.8, 0.4, 0.04))
