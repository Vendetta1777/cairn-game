extends EnemyBase
## Cairn — Crawler (GDD "Crawler"): a ground axe-imp. Patrols a stretch, chases
## the player on sight, and swings its axe in melee. Gravity-bound CharacterBody2D
## that collides with terrain (mask 1). Damage/stagger/death come from EnemyBase.

enum { PATROL, CHASE, ATTACK }

@export var patrol_speed: float = 34.0
@export var chase_speed: float = 88.0
@export var patrol_range: float = 70.0
@export var aggro_range: float = 165.0
@export var attack_range: float = 30.0
@export var vertical_tol: float = 42.0
@export var gravity: float = 1100.0
@export var contact_damage: int = 2     ## half-hearts (a full heart)
@export var attack_cooldown: float = 1.0
@export var attack_duration: float = 0.6
@export var attack_hit_time: float = 0.3

var _state := PATROL
var _dir := 1.0
var _spawn_x := 0.0
var _cooldown := 0.0
var _atk_t := 0.0
var _atk_hit := false


func _ready() -> void:
	super()
	_spawn_x = global_position.x
	_dir = -1.0 if randf() < 0.5 else 1.0


func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)

	if is_staggered():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
		return

	if _cooldown > 0.0:
		_cooldown -= delta
	var player := get_tree().get_first_node_in_group("player")

	match _state:
		PATROL:
			_do_patrol(player)
		CHASE:
			_do_chase(player)
		ATTACK:
			_do_attack(delta, player)

	if _sprite:
		_sprite.flip_h = _dir < 0.0
	move_and_slide()


func _do_patrol(player: Node2D) -> void:
	velocity.x = patrol_speed * _dir
	_play(&"walk")
	if global_position.x < _spawn_x - patrol_range:
		_dir = 1.0
	elif global_position.x > _spawn_x + patrol_range:
		_dir = -1.0
	if is_on_wall():
		_dir = -_dir
	if player and _in_aggro(player):
		_state = CHASE


func _do_chase(player: Node2D) -> void:
	if player == null:
		_state = PATROL
		return
	var dx := player.global_position.x - global_position.x
	_dir = signf(dx)
	if absf(dx) < attack_range and _cooldown <= 0.0:
		_state = ATTACK
		_atk_t = attack_duration
		_atk_hit = false
		velocity.x = 0.0
		_play(&"attack")
		return
	velocity.x = chase_speed * _dir
	_play(&"run")
	if not _in_aggro(player, 1.5):
		_state = PATROL


func _do_attack(delta: float, player: Node2D) -> void:
	velocity.x = 0.0
	_atk_t -= delta
	# Land the hit partway through the swing.
	if not _atk_hit and _atk_t <= attack_duration - attack_hit_time:
		_atk_hit = true
		if player and absf(player.global_position.x - global_position.x) < attack_range + 10.0 \
				and absf(player.global_position.y - global_position.y) < vertical_tol \
				and player.has_method("receive_attack"):
			player.receive_attack(self, contact_damage)
	if _atk_t <= 0.0:
		_cooldown = attack_cooldown
		_state = CHASE


func _in_aggro(player: Node2D, mult := 1.0) -> bool:
	return absf(player.global_position.x - global_position.x) < aggro_range * mult \
		and absf(player.global_position.y - global_position.y) < vertical_tol * mult
