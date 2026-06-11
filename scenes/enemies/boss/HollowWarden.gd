extends EnemyBase
class_name HollowWarden
## Cairn — Area 1 boss: THE HOLLOW WARDEN (GDD M5, "2 bosses" — this is the
## guardian of the gate). A slow, heavy guardian that holds the ward sealing the
## Hollowed Gate. Three escalating phases:
##   P1 (>66% HP): paces in, single CHARGE attacks with long tells.
##   P2 (<=66%):   adds a SLAM that sends a ground shockwave; quicker tells.
##   P3 (<=33%):   enraged — chains CHARGE -> SLAM, short cooldowns.
## Telegraphs are generous so the fight is about reading and punishing, the
## Dark-Souls-paced loop the GDD asks for. Parry still staggers it (EnemyBase).

signal health_changed(cur: int, max: int)
signal engaged
signal defeated

enum { DORMANT, APPROACH, TELEGRAPH_CHARGE, CHARGE, TELEGRAPH_SLAM, SLAM, RECOVER }

@export var boss_id: String = "hollow_warden"
@export var walk_speed: float = 46.0
@export var charge_speed: float = 250.0
@export var aggro_range: float = 230.0
@export var attack_range: float = 150.0
@export var vertical_tol: float = 70.0
@export var contact_damage: int = 2       ## half-hearts dealt by charge body-check
@export var slam_damage: int = 3          ## half-hearts from the shockwave
@export var gravity: float = 1100.0

var _state := DORMANT
var _dir := -1.0
var _t := 0.0
var _cooldown := 0.0
var _hit_player := false
var _engaged := false

@onready var _shockwave: PackedScene = preload("res://scenes/enemies/boss/Shockwave.tscn")


func _ready() -> void:
	super._ready()
	# A boss-sized aura that breathes; brightens when enraged.
	if _sprite:
		_sprite.modulate = Color(0.82, 0.78, 0.95)


func _process(delta: float) -> void:
	super._process(delta)
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)


## Called by the arena trigger (or auto when the player wanders close).
func engage() -> void:
	if _engaged or is_dead():
		return
	_engaged = true
	_state = APPROACH
	engaged.emit()
	health_changed.emit(health, max_health)


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
		DORMANT:
			velocity.x = 0.0
			_play(&"idle")
			if player and absf(player.global_position.x - global_position.x) < aggro_range:
				engage()
		APPROACH:
			_do_approach(delta, player)
		TELEGRAPH_CHARGE:
			_do_telegraph_charge(delta, player)
		CHARGE:
			_do_charge(delta, player)
		TELEGRAPH_SLAM:
			_do_telegraph_slam(delta)
		SLAM:
			_do_slam(delta, player)
		RECOVER:
			_do_recover(delta)

	if _sprite and _state != CHARGE:
		_sprite.flip_h = _dir < 0.0
	move_and_slide()


func _phase() -> int:
	var f := float(health) / float(max_health)
	if f <= 0.34:
		return 3
	elif f <= 0.67:
		return 2
	return 1


func _do_approach(delta: float, player: Node2D) -> void:
	if not player:
		velocity.x = 0.0
		return
	_dir = signf(player.global_position.x - global_position.x)
	var dist := absf(player.global_position.x - global_position.x)
	var dy := absf(player.global_position.y - global_position.y)
	_play(&"walk")
	# Drift in slowly; faster when enraged.
	var sp := walk_speed * (1.0 + 0.5 * (_phase() - 1))
	velocity.x = sp * _dir
	if dist < attack_range and dy < vertical_tol and _cooldown <= 0.0:
		_choose_attack(player)


func _choose_attack(player: Node2D) -> void:
	var dist := absf(player.global_position.x - global_position.x)
	# Phase 1: only charge. P2+: mix in slam, preferring slam when player is close.
	if _phase() == 1:
		_enter_telegraph_charge()
	elif dist < 70.0:
		_enter_telegraph_slam()
	else:
		# Alternate; favour charge at range, slam up close.
		if randf() < 0.55:
			_enter_telegraph_charge()
		else:
			_enter_telegraph_slam()


func _enter_telegraph_charge() -> void:
	_state = TELEGRAPH_CHARGE
	_t = (0.55 if _phase() == 1 else 0.4) if _phase() < 3 else 0.3
	velocity.x = 0.0
	_play(&"attack")
	_flash_tell(Color(1.0, 0.85, 0.55))


func _do_telegraph_charge(delta: float, player: Node2D) -> void:
	velocity.x = 0.0
	if player:
		_dir = signf(player.global_position.x - global_position.x)
	_t -= delta
	if _t <= 0.0:
		_state = CHARGE
		_t = 1.1
		_hit_player = false


func _do_charge(delta: float, player: Node2D) -> void:
	if _sprite:
		_sprite.flip_h = _dir < 0.0
	velocity.x = charge_speed * _dir
	_play(&"walk")
	_t -= delta
	if player and not _hit_player \
			and absf(player.global_position.x - global_position.x) < 34.0 \
			and absf(player.global_position.y - global_position.y) < vertical_tol \
			and player.has_method("receive_attack"):
		_hit_player = true
		player.receive_attack(self, contact_damage)
	if _t <= 0.0 or is_on_wall():
		_state = RECOVER
		_t = 0.7 if _phase() == 3 else 1.0


func _enter_telegraph_slam() -> void:
	_state = TELEGRAPH_SLAM
	_t = 0.5 if _phase() < 3 else 0.36
	velocity.x = 0.0
	_play(&"attack")
	_flash_tell(Color(0.7, 0.6, 1.0))


func _do_telegraph_slam(delta: float) -> void:
	velocity.x = 0.0
	_t -= delta
	if _t <= 0.0:
		_state = SLAM
		_t = 0.18


func _do_slam(delta: float, player: Node2D) -> void:
	velocity.x = 0.0
	_t -= delta
	if _t <= 0.0:
		_emit_shockwave(player)
		# Enraged warden may chain straight into a charge.
		if _phase() == 3 and randf() < 0.5:
			_enter_telegraph_charge()
		else:
			_state = RECOVER
			_t = 0.85 if _phase() == 3 else 1.1


func _emit_shockwave(player: Node2D) -> void:
	var ground_y := global_position.y + 18.0
	for d in [-1.0, 1.0]:
		var wave := _shockwave.instantiate()
		get_parent().add_child(wave)
		wave.global_position = Vector2(global_position.x + d * 12.0, ground_y)
		if wave.has_method("launch"):
			wave.launch(d, slam_damage)
	# Immediate close-range thump so a player hugging the boss still eats it.
	if player and absf(player.global_position.x - global_position.x) < 46.0 \
			and player.has_method("receive_attack") and player.has_method("is_on_floor"):
		if player.is_on_floor():
			player.receive_attack(self, slam_damage)
	if _camera_shake(0.6):
		pass


func _do_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	_play(&"idle")
	_t -= delta
	if _t <= 0.0:
		_state = APPROACH
		_cooldown = [0.0, 1.1, 0.7, 0.35][_phase()]


# --- damage / death overrides -------------------------------------------------

func take_damage(amount: int, from: Vector2 = Vector2.ZERO) -> void:
	if is_dead():
		return
	var was_phase := _phase()
	super.take_damage(amount, from)
	if not _engaged:
		engage()
	health_changed.emit(maxi(health, 0), max_health)
	if not is_dead() and _phase() != was_phase:
		_on_phase_change(_phase())


func _on_phase_change(p: int) -> void:
	# Brief stagger + brighter aura on each phase break — a readable "it's angrier".
	_state = RECOVER
	_t = 0.5
	_cooldown = 0.2
	if _sprite:
		var tint := Color(0.82, 0.78, 0.95)
		if p == 2:
			tint = Color(0.95, 0.8, 0.85)
		elif p == 3:
			tint = Color(1.0, 0.62, 0.6)
		create_tween().tween_property(_sprite, "modulate", tint, 0.4)


func _die() -> void:
	defeated.emit()
	health_changed.emit(0, max_health)
	QuestTracker.report_boss_defeated(boss_id)
	super._die()


# --- helpers ------------------------------------------------------------------

func _flash_tell(c: Color) -> void:
	if not _sprite:
		return
	var prev := _sprite.modulate
	_sprite.modulate = c
	create_tween().tween_property(_sprite, "modulate", prev, 0.28)


func _camera_shake(amount: float) -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(amount)
		return true
	return false
