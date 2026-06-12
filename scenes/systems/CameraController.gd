extends Camera2D
class_name CameraController
## Cairn — camera with:
##   - trauma-based screen shake (shake = trauma², so taps nudge, slams kick)
##   - a barely-there procedural sway (0.5px over ~8s — the deep breathes)
##   - combat zoom: eases to 0.97x while blows are landing, back after 3s calm
## Call add_trauma(0..1) on any impact.

@export var max_offset := Vector2(7.0, 5.0)
@export var max_roll: float = 0.04   ## radians
@export var decay: float = 2.4       ## trauma lost per second
@export var sway_amplitude: float = 0.5
@export var sway_period: float = 8.0
@export var combat_zoom: float = 0.97

var _trauma: float = 0.0
var _combat_t: float = 0.0
var _t: float = 0.0
var _base_zoom := Vector2.ONE


func _ready() -> void:
	_base_zoom = zoom


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)
	if amount >= 0.25:
		_combat_t = 3.0   # blows are landing — lean in


func _process(delta: float) -> void:
	_t += delta
	_combat_t = maxf(0.0, _combat_t - delta)
	# Combat zoom eases in and out around the authored zoom.
	var target := _base_zoom * (combat_zoom if _combat_t > 0.0 else 1.0)
	zoom = zoom.lerp(target, 1.0 - exp(-3.0 * delta))
	# The sway: a slow lissajous drift, sub-pixel scale.
	var sway := Vector2(
		sin(_t * TAU / sway_period) * sway_amplitude,
		sin(_t * TAU / (sway_period * 1.37) + 1.3) * sway_amplitude * 0.7)
	if _trauma <= 0.0:
		offset = sway
		rotation = 0.0
		return
	_trauma = maxf(_trauma - decay * delta, 0.0)
	var amt := _trauma * _trauma
	offset = sway + Vector2(
		randf_range(-1.0, 1.0) * max_offset.x,
		randf_range(-1.0, 1.0) * max_offset.y) * amt
	rotation = randf_range(-1.0, 1.0) * max_roll * amt
