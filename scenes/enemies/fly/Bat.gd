extends EnemyBase
## Cairn — Bat (the GDD "Fly" enemy). Test-dummy behaviour for now:
## hovers in place with a gentle bob and faces the player. Dive-bomb +
## projectile attack (GDD Section 6) come with the AI pass in M4.

@export var bob_amplitude: float = 7.0
@export var bob_speed: float = 2.2

var _base_y: float
var _t := 0.0


func _ready() -> void:
	super()
	_base_y = position.y
	_t = randf() * TAU  # desync multiple bats


func _physics_process(delta: float) -> void:
	if is_dead():
		return
	# Gentle hover bob (flying enemy — no gravity).
	_t += delta * bob_speed
	position.y = _base_y + sin(_t) * bob_amplitude

	# Face the player if one is nearby.
	var player := get_tree().get_first_node_in_group("player")
	if player and _sprite:
		_sprite.flip_h = player.global_position.x < global_position.x
