extends Node2D
## Cairn — a CRUMBLING FLOOR GAP (Pale Sovereign, phases 2–3): the throne-room
## tiles crack, shudder, then drop away. The open crevasse bites anything that
## stumbles in (damage + a desperate hop out). Group boss_projectile so a fight
## reset re-knits the floor.

@export var width: float = 70.0
@export var crack_time: float = 1.1
@export var damage: int = 1

var _t := 0.0
var _open := false
var _hit_cd := 0.0


func _ready() -> void:
	add_to_group("boss_projectile")


func _process(delta: float) -> void:
	_t += delta
	_hit_cd = maxf(0.0, _hit_cd - delta)
	if not _open and _t >= crack_time:
		_open = true
		AudioManager.play_at("boss_slam", global_position, -10.0)
		VFXManager.dust(global_position, 0.7)
	if _open:
		var player := get_tree().get_first_node_in_group("player")
		if player and _hit_cd <= 0.0 \
				and absf(player.global_position.x - global_position.x) < width * 0.5 - 6.0 \
				and player.global_position.y > global_position.y - 14.0 \
				and player.is_on_floor():
			_hit_cd = 0.9
			player.receive_attack(self, damage)
			player.velocity.y = -300.0   # bitten, thrown back out
	queue_redraw()


func _draw() -> void:
	if not _open:
		# Cracks racing across the tiles, shaking dust.
		var p := _t / crack_time
		var rng := RandomNumberGenerator.new()
		rng.seed = int(global_position.x)
		var n := int(4 + p * 6.0)
		for i in n:
			var x0 := -width * 0.5 + rng.randf() * width
			var seg := Vector2(x0, 0)
			for k in 3:
				var nxt := seg + Vector2(rng.randf_range(-7, 7), rng.randf_range(1, 4))
				draw_line(seg, nxt, Color(0.08, 0.06, 0.1, 0.5 + p * 0.5), 1.4)
				seg = nxt
		return
	# The open crevasse: black depth with broken tile lips.
	draw_rect(Rect2(-width * 0.5, -2, width, 16), Color(0.02, 0.015, 0.03))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x) + 7
	var x := -width * 0.5
	while x < width * 0.5 - 6.0:
		var w := rng.randf_range(6.0, 14.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, -2), Vector2(x + w, -2), Vector2(x + w * 0.5, rng.randf_range(2.0, 7.0))]),
			Color(0.14, 0.11, 0.16))
		x += w
	# A cold updraft glints out of it.
	var glow := 0.2 + 0.15 * sin(_t * 3.0)
	draw_rect(Rect2(-width * 0.5, -4, width, 2), Color(0.5, 0.6, 0.9, glow))
