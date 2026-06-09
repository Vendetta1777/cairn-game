extends Camera2D
class_name CameraController
## Cairn — camera with trauma-based screen shake (combat juice, GDD Section 5:
## light on hit, heavy on boss hits). Call add_trauma(0..1); shake = trauma^2 so
## small hits barely nudge and big hits kick hard, then it decays out smoothly.

@export var max_offset := Vector2(7.0, 5.0)
@export var max_roll: float = 0.04   ## radians
@export var decay: float = 2.4       ## trauma lost per second

var _trauma: float = 0.0


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		offset = Vector2.ZERO
		rotation = 0.0
		return
	_trauma = maxf(_trauma - decay * delta, 0.0)
	var amt := _trauma * _trauma
	offset = Vector2(
		randf_range(-1.0, 1.0) * max_offset.x,
		randf_range(-1.0, 1.0) * max_offset.y) * amt
	rotation = randf_range(-1.0, 1.0) * max_roll * amt
