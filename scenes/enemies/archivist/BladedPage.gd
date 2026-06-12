extends Area2D
## Cairn — a BLADED PAGE: a sheet of razor vellum thrown by Archivist Shades
## (and rained by the Pale Librarian). Flies a shallow arc, fluttering as it
## goes; damages once; shreds on the world. Group boss_projectile so fight
## resets clear it.

var _vel := Vector2.ZERO
var _damage := 1
var _t := 0.0
var _hit := false


func launch(dir: Vector2, speed: float = 190.0, damage: int = 1) -> void:
	_vel = dir.normalized() * speed
	_damage = damage


func _ready() -> void:
	add_to_group("boss_projectile")
	monitoring = true
	monitorable = false
	collision_mask = 3   # player hurtbox (2) + world (1)
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 5.0
	shape.shape = c
	add_child(shape)
	area_entered.connect(func(a): _try_hit(a.get_parent()))
	body_entered.connect(_on_body)
	get_tree().create_timer(3.5).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_t += delta
	_vel.y += 120.0 * delta            # shallow arc
	position += _vel * delta
	rotation = _vel.angle()
	queue_redraw()


func _on_body(_b: Node) -> void:
	_shred()


func _try_hit(node: Node) -> void:
	if _hit or node == null:
		return
	if node.is_in_group("player") and node.has_method("receive_attack"):
		_hit = true
		node.receive_attack(self, _damage)
		_shred()


func _shred() -> void:
	set_process(false)
	set_deferred("monitoring", false)
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 6
	p.lifetime = 0.4
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 60.0
	p.gravity = Vector2(0, 160)
	p.color = Color(0.85, 0.82, 0.72, 0.8)
	get_parent().add_child(p)
	p.global_position = global_position
	get_tree().create_timer(0.6).timeout.connect(p.queue_free)
	queue_free()


func _draw() -> void:
	# A fluttering page: a pale quad that twists as it flies.
	var twist := absf(sin(_t * 14.0))
	var h := 4.0 * (0.3 + 0.7 * twist)
	var page := Color(0.88, 0.85, 0.75)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -h), Vector2(6, -h * 0.7), Vector2(6, h), Vector2(-6, h * 0.7)]), page)
	draw_line(Vector2(-4, 0), Vector2(4, 0), Color(0.4, 0.38, 0.34, 0.7), 0.8)
	draw_line(Vector2(6, -h * 0.7), Vector2(6, h), Color(1, 1, 1, 0.9), 1.0)   # the edge
