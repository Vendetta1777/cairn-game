extends Node2D
## Cairn — a knocked-loose STALACTITE (Buried King, phase 2). Shudders overhead
## for a beat (its shadow flickers on the floor — that's your warning), then
## drops. Hits the PLAYER for a heart — but lands on the KING for massive
## damage, and the rubble it leaves is a platform for a while. Lure him under.

@export var floor_y: float = 252.0
@export var tell_time: float = 0.7
@export var player_damage: int = 2
@export var boss_damage: int = 6
@export var rubble_time: float = 8.0

var _t := 0.0
var _falling := false
var _vel := 0.0
var _done := false


func _ready() -> void:
	add_to_group("boss_projectile")


func _process(delta: float) -> void:
	_t += delta
	if _done:
		return
	if not _falling:
		if _t >= tell_time:
			_falling = true
			AudioManager.play_at("enemy_hurt", global_position, -8.0)
	else:
		_vel = minf(_vel + 1500.0 * delta, 560.0)
		position.y += _vel * delta
		_check_hits()
		if global_position.y >= floor_y - 14.0:
			_land()
	queue_redraw()


func _check_hits() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and absf(player.global_position.x - global_position.x) < 12.0 \
			and absf(player.global_position.y - global_position.y) < 22.0 \
			and player.has_method("receive_attack"):
		player.receive_attack(self, player_damage)
		_land()
		return
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss.has_method("take_damage") and not boss.get("_collapsing") \
				and absf(boss.global_position.x - global_position.x) < 26.0 \
				and absf(boss.global_position.y - global_position.y) < 40.0:
			# A direct hit through the armour — the one thing that always hurts him.
			boss.take_damage(boss_damage, Vector2.ZERO)
			GameManager.hitstop(0.08)
			var cam := get_viewport().get_camera_2d()
			if cam and cam.has_method("add_trauma"):
				cam.add_trauma(0.7)
			_land()
			return


func _land() -> void:
	if _done:
		return
	_done = true
	global_position.y = floor_y - 14.0
	AudioManager.play_at("boss_slam", global_position, -8.0)
	# Dust burst.
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 12
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.gravity = Vector2(0, 300)
	p.color = Color(0.5, 0.45, 0.4, 0.8)
	add_child(p)
	# The rubble becomes a small platform for a while.
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(26, 12)
	cs.shape = shape
	cs.position = Vector2(0, 8)
	body.add_child(cs)
	add_child(body)
	get_tree().create_timer(rubble_time).timeout.connect(func():
		if is_instance_valid(self):
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 0.5)
			tw.tween_callback(queue_free))


func _draw() -> void:
	var rock := Color(0.32, 0.3, 0.28)
	var rock_d := Color(0.18, 0.17, 0.16)
	if _done:
		# Rubble mound.
		draw_colored_polygon(PackedVector2Array([
			Vector2(-14, 14), Vector2(-6, 2), Vector2(2, 6), Vector2(8, 0), Vector2(14, 14)]), rock)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-6, 2), Vector2(2, 6), Vector2(-2, 14)]), rock_d)
		return
	if not _falling:
		# The shudder tell: the spike vibrates, dust trickles, shadow pulses below.
		var sh := sin(_t * 50.0) * 1.5
		draw_colored_polygon(PackedVector2Array([
			Vector2(-9 + sh, -16), Vector2(9 + sh, -16), Vector2(sh, 22)]), rock)
		var ground := floor_y - global_position.y
		var a := 0.2 + 0.2 * sin(_t * 14.0)
		draw_rect(Rect2(-10, ground - 2, 20, 2), Color(0, 0, 0, a))
	else:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-9, -16), Vector2(9, -16), Vector2(0, 22)]), rock)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-6, -14), Vector2(0, -14), Vector2(-1, 12)]), rock_d)
		draw_line(Vector2(0, -22), Vector2(0, -34), Color(0.5, 0.45, 0.4, 0.4), 2.0)
