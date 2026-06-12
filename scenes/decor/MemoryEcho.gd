extends Node2D
## Cairn — a MEMORY ECHO (The Sovereign's Throne): a translucent figure of the
## old court replaying a moment that ended centuries ago. Walks its path,
## pauses, bows or gestures, flickers, repeats. Non-interactive — pure
## atmosphere. Drawn procedurally: robed silhouettes in spectral blue-white.

@export var walk_to := Vector2(120, 0)   ## relative end of its pacing line
@export var period: float = 9.0          ## full loop time
@export var kind: String = "courtier"    ## courtier / guard / kneeling
@export var phase: float = 0.0

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _loop_pos() -> float:
	# 0..1..0 ping-pong with dwell at the ends.
	var p := fmod((_t + phase * period) / period, 1.0)
	var q := absf(p * 2.0 - 1.0)          # 1..0..1
	return smoothstep(0.12, 0.88, 1.0 - q)


func _draw() -> void:
	var f := _loop_pos()
	var pos := walk_to * f
	# Spectral flicker: occasionally the echo thins almost to nothing.
	var flicker := 0.6 + 0.4 * sin(_t * 1.3 + phase * 7.0)
	if fmod(_t + phase * 3.0, 6.0) < 0.25:
		flicker *= 0.25
	var a := 0.16 * flicker
	var c := Color(0.6, 0.75, 0.95, a)
	var c_dim := Color(0.5, 0.62, 0.85, a * 0.6)
	var bob := sin(_t * 5.0) * (1.0 if absf(walk_to.x) > 1.0 else 0.0)
	match kind:
		"guard":
			# A halberdier at rest.
			draw_rect(Rect2(pos.x - 5, pos.y - 26 + bob, 10, 26), c)
			draw_circle(pos + Vector2(0, -30 + bob), 5.0, c)
			draw_rect(Rect2(pos.x - 4, pos.y - 33 + bob, 8, 3), c_dim)
			draw_line(pos + Vector2(8, 0), pos + Vector2(8, -42), c_dim, 1.5)
			draw_colored_polygon(PackedVector2Array([
				pos + Vector2(6, -42), pos + Vector2(12, -38), pos + Vector2(8, -34)]), c_dim)
		"kneeling":
			draw_rect(Rect2(pos.x - 5, pos.y - 16, 10, 16), c)
			draw_circle(pos + Vector2(2, -20), 4.5, c)
			draw_rect(Rect2(pos.x - 8, pos.y - 4, 6, 4), c_dim)
		_:
			# A robed courtier mid-procession.
			draw_colored_polygon(PackedVector2Array([
				pos + Vector2(-6, 0), pos + Vector2(-4, -24 + bob), pos + Vector2(4, -24 + bob), pos + Vector2(6, 0)]), c)
			draw_circle(pos + Vector2(0, -28 + bob), 5.0, c)
			draw_rect(Rect2(pos.x - 7, pos.y - 20 + bob, 14, 2), c_dim)
	# Ground shimmer.
	draw_rect(Rect2(pos.x - 8, pos.y - 1, 16, 2), Color(0.5, 0.7, 0.95, a * 0.4))
