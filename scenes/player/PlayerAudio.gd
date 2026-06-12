extends Node
## Cairn — player sound hookup. Listens to the controller's signals for the
## one-shots (jump, land, dash, hurt, parry, death) and runs a cadence timer for
## footsteps while running. Footstep surface switches by context: water while a
## WaterZone is dragging us, ash anywhere in The Ashpits, stone otherwise.

@export var step_interval: float = 0.3

var _controller
var _step_t := 0.0


func _ready() -> void:
	_controller = get_parent()
	_controller.jumped.connect(func(): AudioManager.play("jump", -10.0))
	_controller.landed.connect(func(): AudioManager.play("land", -8.0))
	_controller.dashed.connect(func(): AudioManager.play("dash", -8.0))
	_controller.hurt.connect(func(_amt): AudioManager.play("hurt", -4.0))
	_controller.parried.connect(func(_a): AudioManager.play("parry", -4.0))
	var stats := get_node_or_null("../Stats")
	if stats:
		stats.died.connect(func(): AudioManager.play("death_player", -2.0))


func _process(delta: float) -> void:
	if _controller.get_current_state() == "run" and _controller.is_on_floor():
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = step_interval
			AudioManager.play(_surface_step(), -14.0, 0.12)
	else:
		_step_t = 0.05


func _surface_step() -> String:
	if _controller.speed_zone_mult < 1.0:
		return "step_water"
	if GameManager.current_area_name == "THE ASHPITS":
		return "step_ash"
	return "step_stone"
