extends EnemyBase
## Cairn — Bat (the GDD "Fly"). Deliberately easy (the real threat is later
## creatures/bosses): 1 HP, and on a successful dive it does just a half-heart.
##
## AI: hovers and bobs; when the player comes within aggro_range it snapshots
## their position and DIVE-bombs; then RECOVERs back up and cools down before
## diving again. Contact during the dive damages the player (their i-frames stop
## multi-hits). A simplified take on the shared M4 state machine.

enum { HOVER, DIVE, RECOVER }

@export var aggro_range: float = 115.0
@export var dive_speed: float = 165.0
@export var return_speed: float = 95.0
@export var bob_amplitude: float = 6.0
@export var bob_speed: float = 2.2
@export var dive_cooldown: float = 1.5
@export var contact_damage: int = 1   ## half-hearts (½ heart)

var _state := HOVER
var _home_y := 0.0
var _t := 0.0
var _target := Vector2.ZERO
var _cooldown := 0.0
var _state_time := 0.0

@onready var _touch: Area2D = get_node_or_null("Touch")


func _ready() -> void:
	super()
	_home_y = position.y
	_t = randf() * TAU
	if _touch:
		_touch.area_entered.connect(_on_touch)


func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		return
	# Staggered (e.g. parried): let the knockback play out, no AI.
	if is_staggered():
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
		move_and_slide()
		return
	if _cooldown > 0.0:
		_cooldown -= delta
	_state_time += delta

	var player := get_tree().get_first_node_in_group("player")
	match _state:
		HOVER:
			_t += delta * bob_speed
			velocity = Vector2(0.0, cos(_t) * bob_amplitude)
			if player and _cooldown <= 0.0 and _can_sense(player) \
					and global_position.distance_to(player.global_position) < aggro_range:
				_target = player.global_position
				_aggro_sound()
				_enter(DIVE)
		DIVE:
			velocity = global_position.direction_to(_target) * dive_speed
			if global_position.distance_to(_target) < 12.0 or _state_time > 1.0:
				_enter(RECOVER)
		RECOVER:
			var home := Vector2(global_position.x, _home_y)
			velocity = global_position.direction_to(home) * return_speed
			if absf(global_position.y - _home_y) < 6.0 or _state_time > 1.3:
				_cooldown = dive_cooldown
				_enter(HOVER)

	if player and _sprite:
		_sprite.flip_h = player.global_position.x < global_position.x
	move_and_slide()


func _enter(state: int) -> void:
	_state = state
	_state_time = 0.0


func _on_touch(area: Area2D) -> void:
	if _state != DIVE:
		return
	var body := area.get_parent()
	if body and body.is_in_group("player") and body.has_method("receive_attack"):
		# Routes through the player's parry/iframe handling.
		body.receive_attack(self, contact_damage)
		_cooldown = dive_cooldown
		_enter(RECOVER)
