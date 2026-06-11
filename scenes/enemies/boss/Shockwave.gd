extends Area2D
## Cairn — Hollow Warden ground shockwave. Travels outward along the floor from a
## slam, damaging the player once on contact, then fades. Purely a hazard: it
## reads as a low crescent of force skimming the ground, so the player learns to
## jump it.

var _dir := 1.0
var _speed := 230.0
var _damage := 3
var _life := 0.62
var _age := 0.0
var _hit := false


func launch(dir: float, damage: int) -> void:
	_dir = signf(dir)
	_damage = damage


func _ready() -> void:
	monitoring = true
	monitorable = false
	# Detect the player's hurtbox (layer 2).
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 26)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	add_child(shape)
	area_entered.connect(_on_area)
	body_entered.connect(_on_body)


func _process(delta: float) -> void:
	_age += delta
	position.x += _dir * _speed * delta
	_speed = maxf(60.0, _speed - 120.0 * delta)
	queue_redraw()
	if _age >= _life:
		queue_free()


func _on_area(area: Area2D) -> void:
	_try_hit(area.get_parent())


func _on_body(body: Node) -> void:
	_try_hit(body)


func _try_hit(node: Node) -> void:
	if _hit or node == null:
		return
	if node.is_in_group("player") and node.has_method("receive_attack"):
		_hit = true
		node.receive_attack(self, _damage)


func _draw() -> void:
	var a := clampf(1.0 - _age / _life, 0.0, 1.0)
	var h := 18.0 * (0.5 + a * 0.5)
	var col := Color(0.66, 0.58, 0.95, 0.7 * a)
	var edge := Color(0.85, 0.8, 1.0, 0.85 * a)
	# A leaning crescent of force.
	var pts := PackedVector2Array([
		Vector2(-10 * _dir, 0),
		Vector2(-2 * _dir, -h),
		Vector2(6 * _dir, -h * 0.6),
		Vector2(10 * _dir, 0),
	])
	draw_colored_polygon(pts, col)
	draw_polyline(pts, edge, 1.5, true)
	# Faint dust at the base.
	draw_circle(Vector2(0, 0), 3.0 * a, Color(0.8, 0.78, 0.9, 0.4 * a))
