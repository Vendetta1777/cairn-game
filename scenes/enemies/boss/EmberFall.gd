extends Area2D
## Cairn — CINDER RAIN ember: one burning mote shaken loose from the Ashpits'
## ceiling during the Ashen Warden's phase-2 storm. Falls with a slight drift,
## damages once on contact, dies on the floor with a spark.

var _damage := 1
var _vel := Vector2.ZERO
var _floor_y := 252.0
var _hit := false


func setup(damage: int, floor_y: float) -> void:
	_damage = damage
	_floor_y = floor_y


func _ready() -> void:
	add_to_group("boss_projectile")
	monitoring = true
	monitorable = false
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 5.0
	shape.shape = c
	add_child(shape)
	area_entered.connect(func(a): _try_hit(a.get_parent()))
	_vel = Vector2(randf_range(-26.0, 26.0), randf_range(120.0, 180.0))


func _process(delta: float) -> void:
	_vel.y = minf(_vel.y + 240.0 * delta, 320.0)
	position += _vel * delta
	queue_redraw()
	if global_position.y >= _floor_y - 2.0:
		_spark_and_die()


func _try_hit(node: Node) -> void:
	if _hit or node == null:
		return
	if node.is_in_group("player") and node.has_method("receive_attack"):
		_hit = true
		node.receive_attack(self, _damage)
		queue_free()


func _spark_and_die() -> void:
	set_process(false)
	monitoring = false
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 6
	p.lifetime = 0.3
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 75.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 70.0
	p.gravity = Vector2(0, 300)
	p.color = Color(1.0, 0.6, 0.25, 0.9)
	get_parent().add_child(p)
	p.global_position = global_position
	get_tree().create_timer(0.5).timeout.connect(p.queue_free)
	queue_free()


func _draw() -> void:
	# A falling ember with a short hot tail.
	var tail := -_vel.normalized() * 9.0
	draw_line(Vector2.ZERO, tail, Color(1.0, 0.45, 0.15, 0.5), 2.0)
	draw_circle(Vector2.ZERO, 2.4, Color(1.0, 0.62, 0.22))
	draw_circle(Vector2(0, -0.5), 1.1, Color(1.0, 0.9, 0.6))
