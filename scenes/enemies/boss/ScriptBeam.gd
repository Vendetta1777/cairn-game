extends Node2D
## Cairn — FORBIDDEN SCRIPT BEAM (Pale Librarian, phase 3): a thin line of
## burning text that draws itself across the arena — a warning glimmer first,
## then the live beam sweeps a slow rotation. Touching the live beam hurts.
## Spawned at the boss's heart; group boss_projectile.

@export var length: float = 360.0
@export var tell_time: float = 0.65
@export var fire_time: float = 1.2
@export var sweep_radians: float = 0.7
@export var damage: int = 1

var _t := 0.0
var _angle := 0.0
var _base_angle := 0.0
var _hit_cd := 0.0


func aim(angle: float) -> void:
	_base_angle = angle
	_angle = angle


func _ready() -> void:
	add_to_group("boss_projectile")
	AudioManager.play_at("bolt", global_position, -10.0)


func _process(delta: float) -> void:
	_t += delta
	_hit_cd = maxf(0.0, _hit_cd - delta)
	if _t >= tell_time + fire_time:
		queue_free()
		return
	if _t > tell_time:
		var p := (_t - tell_time) / fire_time
		_angle = _base_angle + (p - 0.5) * sweep_radians
		# Hurt the player on the line.
		var player := get_tree().get_first_node_in_group("player")
		if player and _hit_cd <= 0.0:
			var a := global_position
			var b := global_position + Vector2.from_angle(_angle) * length
			var closest := Geometry2D.get_closest_point_to_segment(player.global_position + Vector2(0, -12), a, b)
			if closest.distance_to(player.global_position + Vector2(0, -12)) < 10.0:
				_hit_cd = 0.6
				if player.has_method("receive_attack"):
					player.receive_attack(self, damage)
	queue_redraw()


func _draw() -> void:
	var dir := Vector2.from_angle(_angle)
	var endp := dir * length
	if _t <= tell_time:
		# The warning: a faint dotted line of letters assembling.
		var n := int(length / 14.0)
		var a := 0.25 + 0.45 * (_t / tell_time)
		for i in n:
			var p := dir * (i * 14.0 + fmod(_t * 60.0, 14.0))
			draw_line(p, p + dir * 5.0, Color(0.8, 0.75, 0.95, a), 1.0)
	else:
		# The live beam: a hot core wrapped in drifting glyph strokes.
		draw_line(Vector2.ZERO, endp, Color(0.95, 0.92, 1.0, 0.95), 2.0)
		draw_line(Vector2.ZERO, endp, Color(0.6, 0.5, 0.9, 0.4), 5.0)
		for i in int(length / 26.0):
			var p := dir * (i * 26.0 + 8.0)
			var nrm := dir.orthogonal() * (2.0 + sin(_t * 9.0 + i) * 1.5)
			draw_line(p - nrm, p + nrm, Color(0.85, 0.8, 1.0, 0.7), 1.0)
