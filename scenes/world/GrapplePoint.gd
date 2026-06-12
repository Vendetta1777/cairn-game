extends Node2D
## Cairn — a GRAPPLE ANCHOR: an old iron ring set into the stone, left by the
## kingdom's riggers. With the grapple hook (won from the Pale Librarian), press
## F near one and the line pulls you to it. Drawn procedurally: a rusted ring on
## a mounting plate, glinting faintly when you hold the hook and stand in range.

var _t := 0.0
var _flash := 0.0
var _player: Node2D


func _ready() -> void:
	add_to_group("grapple_point")


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 2.5)
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	queue_redraw()


## The controller pings this when a grapple fires at us.
func flash() -> void:
	_flash = 1.0
	AudioManager.play_at("parry", global_position, -16.0)


func _in_reach() -> bool:
	return _player != null and PlayerProgress.has_ability("grapple") \
		and _player.global_position.distance_to(global_position) < 170.0


func _draw() -> void:
	var rust := Color(0.42, 0.3, 0.2)
	var rust_d := Color(0.26, 0.18, 0.12)
	var glint := Color(0.85, 0.9, 1.0)
	# Mounting plate bolted to the stone.
	draw_rect(Rect2(-6, -3, 12, 6), rust_d)
	draw_rect(Rect2(-5, -2, 2, 2), rust)
	draw_rect(Rect2(3, -2, 2, 2), rust)
	# The ring, hanging below, swaying just barely.
	var sway := sin(_t * 1.3 + global_position.x * 0.05) * 0.08
	var c := Vector2(sin(sway) * 8.0, 3.0 + cos(sway) * 8.0)
	draw_arc(c, 6.0, 0, TAU, 14, rust, 2.2)
	draw_arc(c + Vector2(-1, -1), 6.0, PI * 0.9, PI * 1.6, 6, Color(0.6, 0.45, 0.3), 1.2)
	# In-range glint when the hook is held.
	if _in_reach():
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		draw_circle(c, 9.0, Color(glint.r, glint.g, glint.b, 0.08 + 0.1 * pulse))
		draw_circle(c + Vector2(2, -3), 1.2, Color(glint.r, glint.g, glint.b, 0.5 + 0.4 * pulse))
	if _flash > 0.0:
		draw_circle(c, 11.0, Color(1, 1, 1, 0.35 * _flash))
