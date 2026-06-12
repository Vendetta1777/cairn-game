extends EnemyBase
## Cairn — CINDER WRAITH (The Ashpits): a scrap of burning shade that never
## flies straight. Fast and frail — two hits end it — but it weaves on layered
## sine drift while it stalks, and its dive bends mid-flight to chase you.
##   DRIFT: erratic weave around its haunt; aggro at range.
##   DIVE:  a fast, steering dive at the player (contact = ½ heart).
##   SCATTER: overshoots past you and loops back high before another pass.

enum { DRIFT, DIVE, SCATTER }

@export var aggro_range: float = 150.0
@export var dive_speed: float = 245.0
@export var steer_rate: float = 3.2        ## how hard the dive curves toward you
@export var scatter_speed: float = 130.0
@export var contact_damage: int = 1        ## half-hearts
@export var dive_cooldown: float = 0.9

var _state := DRIFT
var _home := Vector2.ZERO
var _t := 0.0
var _state_time := 0.0
var _cooldown := 0.0
var _dive_dir := Vector2.ZERO

@onready var _touch: Area2D = get_node_or_null("Touch")
@onready var _trail: CPUParticles2D = get_node_or_null("Trail")


func _ready() -> void:
	super()
	_home = global_position
	_t = randf() * TAU
	if _sprite:
		_sprite.modulate = Color(1.0, 0.55, 0.3)
	if _touch:
		_touch.area_entered.connect(_on_touch)


func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		if _trail:
			_trail.emitting = false
		return
	if is_staggered():
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		move_and_slide()
		return
	_t += delta
	_state_time += delta
	if _cooldown > 0.0:
		_cooldown -= delta

	var player := get_tree().get_first_node_in_group("player")
	match _state:
		DRIFT:
			# Layered sines: jittery, unpredictable weave around the haunt.
			var wob := Vector2(
				sin(_t * 2.3) * 46.0 + sin(_t * 5.1 + 1.3) * 18.0,
				cos(_t * 3.1) * 22.0 + sin(_t * 7.3) * 9.0)
			var target := _home + wob
			velocity = (target - global_position) * 3.4
			if player and _cooldown <= 0.0 and _can_sense(player) \
					and global_position.distance_to(player.global_position) < aggro_range:
				_aggro_sound()
				_enter(DIVE)
				_dive_dir = global_position.direction_to(player.global_position)
		DIVE:
			# Steer toward the player mid-dive — it bends, it doesn't track perfectly.
			if player:
				var want := global_position.direction_to(player.global_position)
				_dive_dir = _dive_dir.slerp(want, clampf(steer_rate * delta, 0.0, 1.0))
			velocity = _dive_dir * dive_speed
			if _state_time > 0.85:
				_enter(SCATTER)
		SCATTER:
			# Loop back up and away before the next pass.
			var up_home := _home + Vector2(sin(_t * 2.0) * 30.0, -14.0)
			velocity = global_position.direction_to(up_home) * scatter_speed
			if _state_time > 1.0 or global_position.distance_to(up_home) < 14.0:
				_cooldown = dive_cooldown
				_enter(DRIFT)

	if player and _sprite:
		_sprite.flip_h = player.global_position.x < global_position.x
	move_and_slide()


func _enter(s: int) -> void:
	_state = s
	_state_time = 0.0


func _on_touch(area: Area2D) -> void:
	if _state != DIVE:
		return
	var body := area.get_parent()
	if body and body.is_in_group("player") and body.has_method("receive_attack"):
		body.receive_attack(self, contact_damage)
		_cooldown = dive_cooldown
		_enter(SCATTER)
