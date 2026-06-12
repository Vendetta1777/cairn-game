extends Node2D
## Cairn — a MINECART RIDE (The Iron Warrens): board with E and the cart tears
## down its rail through a hazard gauntlet. The rail is a polyline of authored
## waypoints; the player is locked to the cart while riding and can JUMP off at
## any moment (and must, at the end — the cart crashes into the buffer).
## The cart resets to the start a few seconds after a run.

@export var waypoints: Array[Vector2] = []   ## local rail points, first = rest
@export var speed: float = 240.0
@export var reset_delay: float = 3.0

var _riding := false
var _running := false
var _seg := 0
var _seg_t := 0.0
var _cart_pos := Vector2.ZERO
var _player: Node2D
var _near := false
var _wheel_spin := 0.0

@onready var _zone: Area2D = $Zone
@onready var _prompt: Control = $Prompt


func _ready() -> void:
	if waypoints.is_empty():
		waypoints = [Vector2.ZERO, Vector2(200, 0)]
	_cart_pos = waypoints[0]
	_zone.position = _cart_pos
	_zone.area_entered.connect(_on_zone)
	_zone.area_exited.connect(_off_zone)
	_prompt.modulate.a = 0.0


func _on_zone(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player") and not _running:
		_near = true
		create_tween().tween_property(_prompt, "modulate:a", 1.0, 0.15)


func _off_zone(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		_near = false
		create_tween().tween_property(_prompt, "modulate:a", 0.0, 0.15)


func _physics_process(delta: float) -> void:
	if _near and not _running and Input.is_action_just_pressed("interact"):
		_board()
	if not _running:
		return
	_wheel_spin += delta * speed * 0.1
	# Advance along the rail.
	var remaining := speed * delta
	while remaining > 0.0 and _seg < waypoints.size() - 1:
		var a := waypoints[_seg]
		var b := waypoints[_seg + 1]
		var seg_len := a.distance_to(b)
		var left := (1.0 - _seg_t) * seg_len
		if remaining < left:
			_seg_t += remaining / seg_len
			remaining = 0.0
		else:
			remaining -= left
			_seg += 1
			_seg_t = 0.0
	_cart_pos = _rail_point()
	# Carry the rider.
	if _riding and _player and is_instance_valid(_player):
		_player.global_position = global_position + _cart_pos + Vector2(0, -16)
		_player.velocity = Vector2.ZERO
		if Input.is_action_just_pressed("jump"):
			_dismount(true)
	# End of the line: kick the rider off and stop.
	if _seg >= waypoints.size() - 1:
		if _riding:
			_dismount(true)
		_running = false
		AudioManager.play_at("land", global_position + _cart_pos, -6.0)
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.3)
		get_tree().create_timer(reset_delay).timeout.connect(_reset)
	queue_redraw()


func _board() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	_riding = true
	_running = true
	_seg = 0
	_seg_t = 0.0
	_player.set_physics_process(false)
	_prompt.modulate.a = 0.0
	AudioManager.play_at("door", global_position + _cart_pos, -12.0)


func _dismount(hop: bool) -> void:
	_riding = false
	if _player and is_instance_valid(_player):
		_player.set_physics_process(true)
		if hop:
			_player.velocity = Vector2(_rail_dir().x * speed * 0.5, -260.0)
	_player = null


func _reset() -> void:
	if _running:
		return
	_seg = 0
	_seg_t = 0.0
	_cart_pos = waypoints[0]
	_zone.position = _cart_pos
	queue_redraw()


func _rail_point() -> Vector2:
	if _seg >= waypoints.size() - 1:
		return waypoints[-1]
	return waypoints[_seg].lerp(waypoints[_seg + 1], _seg_t)


func _rail_dir() -> Vector2:
	if _seg >= waypoints.size() - 1:
		return Vector2.RIGHT
	return (waypoints[_seg + 1] - waypoints[_seg]).normalized()


func _draw() -> void:
	# The rail: ties + twin rails along the waypoint polyline.
	var rail := Color(0.4, 0.32, 0.24)
	var tie := Color(0.22, 0.16, 0.11)
	for i in waypoints.size() - 1:
		var a := waypoints[i]
		var b := waypoints[i + 1]
		var n := (b - a).normalized().orthogonal() * 2.0
		draw_line(a + n, b + n, rail, 1.5)
		draw_line(a - n, b - n, rail, 1.5)
		var ties := int(a.distance_to(b) / 14.0)
		for k in ties:
			var p := a.lerp(b, float(k) / maxf(ties, 1.0))
			draw_line(p + n * 2.2, p - n * 2.2, tie, 2.0)
	# Buffer stop at the end.
	var endp := waypoints[-1]
	draw_rect(Rect2(endp.x - 3, endp.y - 12, 6, 12), Color(0.3, 0.22, 0.16))
	# The cart.
	var c := _cart_pos
	var iron := Color(0.36, 0.3, 0.28)
	var iron_d := Color(0.2, 0.16, 0.15)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-14, -14), c + Vector2(14, -14), c + Vector2(10, 0), c + Vector2(-10, 0)]), iron)
	draw_rect(Rect2(c.x - 14, c.y - 15, 28, 3), iron_d)
	for wx in [-7.0, 7.0]:
		var wc := c + Vector2(wx, 1)
		draw_circle(wc, 3.4, iron_d)
		draw_line(wc, wc + Vector2.from_angle(_wheel_spin) * 2.6, Color(0.5, 0.44, 0.4), 1.0)
