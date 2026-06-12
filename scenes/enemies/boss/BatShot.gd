extends Area2D
## Cairn — the Brood Mother's screech shot: a small sonic crescent (a stylised
## shriek/bat-wing) that flies in a fixed direction and damages the player once.
## Animated: wings beat and it trails a faint echo.

var _vel := Vector2.RIGHT
var _speed := 210.0
var _damage := 1
var _life := 2.4
var _age := 0.0
var _hit := false
var _deflected := false


func launch(dir: Vector2) -> void:
	_vel = dir.normalized()


## A timed strike sends it back at 1.5x speed — and now it hunts its makers.
func deflect(dir: Vector2) -> void:
	if _deflected:
		return
	_deflected = true
	_vel = dir.normalized()
	_speed *= 1.5
	_age = 0.0
	collision_mask = 4   # enemy hurtboxes now
	modulate = Color(0.7, 1.0, 0.95)


func _ready() -> void:
	add_to_group("boss_projectile")
	collision_layer = 0
	collision_mask = 2     # the player's hurtbox
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 7.0
	shape.shape = circ
	add_child(shape)
	area_entered.connect(_on_area)


func _process(delta: float) -> void:
	_age += delta
	position += _vel * _speed * delta
	queue_redraw()
	if _age >= _life:
		queue_free()


func _on_area(area: Area2D) -> void:
	var b := area.get_parent()
	if _hit or b == null:
		return
	# Deflected: double damage to whatever's in the way — ideally its maker.
	if _deflected:
		if b.is_in_group("enemy") and b.has_method("take_damage"):
			_hit = true
			b.take_damage(_damage * 2, global_position)
			if b.has_method("stagger"):
				b.stagger(global_position, 180.0, 1.0)
			queue_free()
		return
	if b.is_in_group("player") and b.has_method("receive_attack"):
		_hit = true
		b.receive_attack(self, _damage)
		queue_free()


func _draw() -> void:
	var flap := sin(_age * 22.0) * 0.5 + 0.5
	var a := clampf(1.0 - _age / _life, 0.2, 1.0)
	var col := Color(0.7, 0.6, 0.95, 0.9 * a)
	# Body.
	draw_circle(Vector2.ZERO, 3.0, col)
	# Beating wings (rotate the whole shot to face travel).
	var ang := _vel.angle()
	var wy := 2.0 + flap * 4.0
	var left := Vector2(-7, -wy).rotated(ang)
	var right := Vector2(-7, wy).rotated(ang)
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO, left, Vector2(-9, 0).rotated(ang)]), col)
	draw_colored_polygon(PackedVector2Array([Vector2.ZERO, right, Vector2(-9, 0).rotated(ang)]), col)
	# Echo trail.
	draw_circle(Vector2(-6, 0).rotated(ang), 2.0, Color(col.r, col.g, col.b, 0.3 * a))
