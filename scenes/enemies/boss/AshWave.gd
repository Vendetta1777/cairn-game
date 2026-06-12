extends Area2D
## Cairn — the Ashen Warden's ASH SWEEP: a horizontal wave of embers that rakes
## the arena floor. Jump it. Damages once, decelerates as it spends itself.
## (Group boss_projectile so a fight reset clears it.)

var _dir := 1.0
var _speed := 270.0
var _damage := 2
var _life := 1.5
var _age := 0.0
var _hit := false


func launch(dir: float, damage: int) -> void:
	_dir = signf(dir)
	_damage = damage


func _ready() -> void:
	add_to_group("boss_projectile")
	monitoring = true
	monitorable = false
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 24)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	add_child(shape)
	area_entered.connect(func(a): _try_hit(a.get_parent()))
	body_entered.connect(_try_hit)


func _process(delta: float) -> void:
	_age += delta
	position.x += _dir * _speed * delta
	_speed = maxf(90.0, _speed - 80.0 * delta)
	queue_redraw()
	if _age >= _life:
		queue_free()


func _try_hit(node: Node) -> void:
	if _hit or node == null:
		return
	if node.is_in_group("player") and node.has_method("receive_attack"):
		_hit = true
		node.receive_attack(self, _damage)


func _draw() -> void:
	var a := clampf(1.0 - _age / _life, 0.0, 1.0)
	var h := 20.0 * (0.55 + a * 0.45)
	# A cresting wave of embers: hot core, sooty crest, trailing sparks.
	var pts := PackedVector2Array([
		Vector2(-12 * _dir, 0), Vector2(-3 * _dir, -h),
		Vector2(6 * _dir, -h * 0.55), Vector2(11 * _dir, 0)])
	draw_colored_polygon(pts, Color(1.0, 0.5, 0.16, 0.75 * a))
	draw_polyline(pts, Color(1.0, 0.85, 0.45, 0.9 * a), 1.5, true)
	for i in range(3):
		var sx := -_dir * (14.0 + i * 9.0)
		var sy := -4.0 - (i * 3.0) - sin(_age * 20.0 + i) * 2.0
		draw_circle(Vector2(sx, sy), 1.6, Color(1.0, 0.6, 0.25, 0.5 * a))
	draw_circle(Vector2.ZERO, 3.0 * a, Color(1.0, 0.75, 0.4, 0.4 * a))
