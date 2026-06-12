extends Area2D
## Cairn — CROWN THROW (Buried King, phase 2): he tears the stone crown from
## his own head and hurls it. It bounces across the arena three times in tall
## arcs, spinning, then crumbles. Touching it hurts.

@export var floor_y: float = 252.0
@export var damage: int = 2

var _vel := Vector2.ZERO
var _bounces := 3
var _spin := 0.0
var _hit_cd := 0.0


func launch(dir: float) -> void:
	_vel = Vector2(dir * 190.0, -330.0)


func _ready() -> void:
	add_to_group("boss_projectile")
	monitoring = true
	monitorable = false
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 11.0
	shape.shape = c
	add_child(shape)
	area_entered.connect(func(a): _try_hit(a.get_parent()))


func _process(delta: float) -> void:
	_hit_cd = maxf(0.0, _hit_cd - delta)
	_spin += delta * 9.0
	_vel.y += 900.0 * delta
	position += _vel * delta
	if global_position.y >= floor_y - 10.0 and _vel.y > 0.0:
		_bounces -= 1
		if _bounces <= 0:
			_crumble()
			return
		global_position.y = floor_y - 10.0
		_vel.y = -330.0
		AudioManager.play_at("parry", global_position, -10.0)
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.25)
	queue_redraw()


func _try_hit(node: Node) -> void:
	if _hit_cd > 0.0 or node == null:
		return
	if node.is_in_group("player") and node.has_method("receive_attack"):
		_hit_cd = 0.8
		node.receive_attack(self, damage)


func _crumble() -> void:
	set_process(false)
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 10
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.spread = 100.0
	p.direction = Vector2(0, -1)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 100.0
	p.gravity = Vector2(0, 320)
	p.color = Color(0.7, 0.58, 0.3)
	get_parent().add_child(p)
	p.global_position = global_position
	get_tree().create_timer(0.7).timeout.connect(p.queue_free)
	queue_free()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, _spin, Vector2.ONE)
	var gold := Color(0.72, 0.6, 0.3)
	var gold_d := Color(0.5, 0.4, 0.2)
	draw_rect(Rect2(-10, -3, 20, 7), gold)
	draw_rect(Rect2(-10, 2, 20, 2), gold_d)
	for k in 3:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-9 + k * 7, -3), Vector2(-6 + k * 7, -10), Vector2(-3 + k * 7, -3)]), gold)
