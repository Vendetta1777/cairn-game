extends Node2D
## Cairn — an enemy CORPSE: the body holds its shape for three seconds before
## the deep takes it. While it lasts:
##   - POGO off it (it's in the player's hitbox layer)
##   - it BLOCKS projectiles (they shred against it)
##   - a combo FINISHER near it LAUNCHES it — a corpse in flight knocks down
##     the first living thing it meets.

var tint := Color(0.5, 0.5, 0.55)
var _t := 0.0
var _flying := false
var _vel := Vector2.ZERO


func _ready() -> void:
	add_to_group("corpse")
	# Layer 4 (player hitbox sees it -> pogo/launch) + 16 (projectiles shred).
	var zone := Area2D.new()
	zone.collision_layer = 4 | 16
	zone.collision_mask = 4   # while flying: detect enemy hurtboxes
	zone.monitoring = false
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(24, 12)
	cs.shape = sh
	cs.position = Vector2(0, -6)
	zone.add_child(cs)
	add_child(zone)
	zone.area_entered.connect(_on_area)


func _process(delta: float) -> void:
	_t += delta
	if _flying:
		_vel.y += 700.0 * delta
		position += _vel * delta
		if _t > 3.0 or global_position.y > 600.0:
			_dissolve()
	elif _t >= 3.0:
		_dissolve()
	queue_redraw()


## A finisher kicked the body across the room.
func launch(dir: Vector2) -> void:
	if _flying:
		return
	_flying = true
	_t = 0.0
	_vel = dir.normalized() * 320.0
	get_child(0).set_deferred("monitoring", true)
	AudioManager.play_at("land", global_position, -8.0)


func _on_area(area: Area2D) -> void:
	if not _flying:
		return
	var b := area.get_parent()
	if b and b.is_in_group("enemy") and b.has_method("take_damage"):
		b.take_damage(2, global_position)
		if b.has_method("stagger"):
			b.stagger(global_position, 260.0, 1.4)
		VFXManager.dust(global_position, 0.6)
		_dissolve()


func _dissolve() -> void:
	set_process(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)


func _draw() -> void:
	# A crumpled shape in the dead thing's colours.
	var c := Color(tint.r * 0.6, tint.g * 0.6, tint.b * 0.6)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, 0), Vector2(-7, -8), Vector2(0, -5), Vector2(6, -9), Vector2(12, 0)]), c)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7, -8), Vector2(0, -5), Vector2(-2, 0)]), c.darkened(0.3))
