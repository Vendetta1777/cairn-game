extends EnemyBase
## Cairn — Brute (GDD "Brute"): a slow, armored ogre. Stands its ground until the
## player is in range, rears up (telegraph), then CHARGES in a straight line —
## heavy contact damage. Tanky (high HP). Parry still staggers it (EnemyBase).

enum { IDLE, TELEGRAPH, CHARGE, RECOVER }

@export var aggro_range: float = 210.0
@export var vertical_tol: float = 52.0
@export var charge_speed: float = 215.0
@export var telegraph_time: float = 0.5
@export var charge_max_time: float = 1.2
@export var recover_time: float = 0.9
@export var contact_damage: int = 2     ## half-hearts (a full heart)
@export var gravity: float = 1100.0

var _state := IDLE
var _dir := 1.0
var _t := 0.0
var _hit_player := false


func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)

	if is_staggered():
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player")
	match _state:
		IDLE:
			_do_idle(player)
		TELEGRAPH:
			_do_telegraph(delta)
		CHARGE:
			_do_charge(delta, player)
		RECOVER:
			_do_recover(delta)

	if _sprite:
		_sprite.flip_h = _dir < 0.0
	move_and_slide()


func _do_idle(player: Node2D) -> void:
	velocity.x = 0.0
	_play(&"idle")
	if player and absf(player.global_position.x - global_position.x) < aggro_range \
			and absf(player.global_position.y - global_position.y) < vertical_tol:
		_dir = signf(player.global_position.x - global_position.x)
		_state = TELEGRAPH
		_t = telegraph_time


func _do_telegraph(delta: float) -> void:
	velocity.x = 0.0
	_play(&"attack")   # rear-up
	_t -= delta
	if _t <= 0.0:
		_state = CHARGE
		_t = charge_max_time
		_hit_player = false


func _do_charge(delta: float, player: Node2D) -> void:
	velocity.x = charge_speed * _dir
	_play(&"walk")
	_t -= delta
	if player and not _hit_player \
			and absf(player.global_position.x - global_position.x) < 30.0 \
			and absf(player.global_position.y - global_position.y) < vertical_tol \
			and player.has_method("receive_attack"):
		_hit_player = true
		player.receive_attack(self, contact_damage)
	if _t <= 0.0 or is_on_wall():
		_state = RECOVER
		_t = recover_time


func _do_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	_play(&"idle")
	_t -= delta
	if _t <= 0.0:
		_state = IDLE
