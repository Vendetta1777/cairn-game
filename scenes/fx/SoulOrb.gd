extends Node2D
## Cairn — a soul-essence orb: condenses where something died, drifts for a
## breath, then homes to the player and pops in a small flash. Pure flavour —
## the currency was already granted on the kill.

var _t := 0.0
var _vel := Vector2.ZERO


func _ready() -> void:
	_vel = Vector2(randf_range(-30, 30), randf_range(-70, -30))


func _process(delta: float) -> void:
	_t += delta
	if _t < 0.5:
		position += _vel * delta
		_vel *= 1.0 - 2.0 * delta
	else:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			var to: Vector2 = player.global_position + Vector2(0, -12) - global_position
			if to.length() < 12.0:
				VFXManager.dust(global_position, 0.15)
				# Gathering Swarm: the essence arrives with interest.
				if PlayerProgress.charm_bonus("gather") > 0.0:
					var stats = player.get_node_or_null("Stats")
					if stats:
						stats.add_echoes(1)
				queue_free()
				return
			position += to.normalized() * minf(420.0, 140.0 + _t * 260.0) * delta
		elif _t > 3.0:
			queue_free()
			return
	queue_redraw()


func _draw() -> void:
	var pulse := 0.7 + 0.3 * sin(_t * 14.0)
	draw_circle(Vector2.ZERO, 4.5, Color(0.5, 0.8, 0.95, 0.25 * pulse))
	draw_circle(Vector2.ZERO, 2.2, Color(0.7, 0.92, 1.0, 0.9))
	draw_circle(Vector2(0.5, -0.5), 1.0, Color(1, 1, 1))
