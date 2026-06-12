extends Node2D
## Cairn — the Pale Sovereign's SOUL SHOCKWAVE: a ring of grief expanding from
## the throne. It hurts exactly at its edge — stand inside or outside, or jump
## the band as it passes. Group boss_projectile.

@export var max_radius: float = 320.0
@export var speed: float = 240.0
@export var damage: int = 2
@export var band: float = 12.0

var _r := 14.0
var _hit_cd := 0.0


func _ready() -> void:
	add_to_group("boss_projectile")
	AudioManager.play_at("bolt", global_position, -6.0)


func _process(delta: float) -> void:
	_r += speed * delta
	_hit_cd = maxf(0.0, _hit_cd - delta)
	if _r >= max_radius:
		queue_free()
		return
	var player := get_tree().get_first_node_in_group("player")
	if player and _hit_cd <= 0.0:
		var d: float = player.global_position.distance_to(global_position)
		if absf(d - _r) < band and player.has_method("receive_attack"):
			_hit_cd = 0.5
			player.receive_attack(self, damage)
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - _r / max_radius
	draw_arc(Vector2.ZERO, _r, 0, TAU, 64, Color(0.7, 0.85, 1.0, 0.8 * fade), 3.0)
	draw_arc(Vector2.ZERO, _r - 4.0, 0, TAU, 64, Color(0.4, 0.5, 0.9, 0.4 * fade), 6.0)
