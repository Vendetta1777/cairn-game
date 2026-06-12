extends EnemyBase
class_name MotherBat
## Cairn — Area 1 boss: THE BROOD MOTHER, a giant bat (keeps Area 1's bat-only
## rule). She hangs above the arena and escalates over three phases:
##   P1 (>66% HP): SWOOPS — telegraphs, then dives along the player's line.
##   P2 (<=66%):   adds a SCREECH — a fanned volley of three sonic shots.
##   P3 (<=33%):   enraged — faster, and SUMMONS a pair of bats between attacks.
## She flies (ignores terrain), is heavy (barely knocked), and her tells are
## generous so the fight rewards reading and dodging.

signal health_changed(cur: int, max: int)
signal engaged
signal defeated

enum { DORMANT, HOVER, SWOOP_TELL, SWOOP, RETURN, SCREECH_TELL, SCREECH, SUMMON, RECOVER }

const BAT := preload("res://scenes/enemies/fly/Bat.tscn")

@export var boss_id: String = "mother_bat"
@export var home_y: float = 110.0
@export var arena_left: float = 2820.0
@export var arena_right: float = 3380.0
@export var drift_speed: float = 60.0
@export var swoop_speed: float = 360.0
@export var return_speed: float = 150.0
@export var contact_damage: int = 1     ## half-hearts on a swoop body-check
@export var aggro_range: float = 360.0

var _state := DORMANT
var _t := 0.0
var _cooldown := 0.0
var _bob := 0.0
var _target := Vector2.ZERO
var _hit_player := false
var _engaged := false

@onready var _shot: PackedScene = preload("res://scenes/enemies/boss/BatShot.tscn")


func _ready() -> void:
	super._ready()
	stagger_resist = 0.12   # very heavy
	_bob = randf() * TAU
	if _sprite:
		_sprite.modulate = Color(0.7, 0.62, 0.8)


func _process(delta: float) -> void:
	super._process(delta)
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)


func engage() -> void:
	if _engaged or is_dead():
		return
	_engaged = true
	_state = HOVER
	AudioManager.boss_music(true)
	engaged.emit()
	health_changed.emit(health, max_health)


func _phase() -> int:
	var f := float(health) / float(max_health)
	if f <= 0.34:
		return 3
	elif f <= 0.67:
		return 2
	return 1


func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		return
	_bob += delta * 2.4

	if is_staggered():
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player")
	match _state:
		DORMANT:
			# Hang still over the arena until the BossTrigger wakes her (or she's
			# struck). No early aggro through the walls before you arrive.
			var ty := home_y + sin(_bob) * 8.0
			velocity = Vector2(0.0, (ty - global_position.y) * 2.0)
		HOVER:
			_do_hover(delta, player)
		SWOOP_TELL:
			_do_swoop_tell(delta, player)
		SWOOP:
			_do_swoop(delta, player)
		RETURN:
			_do_return(delta)
		SCREECH_TELL:
			_do_screech_tell(delta)
		SCREECH:
			_do_screech(player)
		SUMMON:
			_do_summon()
		RECOVER:
			_do_recover(delta)

	# Face the player.
	if _sprite and player:
		_sprite.flip_h = player.global_position.x < global_position.x
	move_and_slide()


func _hover_drift(delta: float, player: Node2D, _attacking: bool) -> void:
	var tx := global_position.x
	if player:
		tx = clampf(player.global_position.x, arena_left, arena_right)
	var vx := signf(tx - global_position.x) * drift_speed
	if absf(tx - global_position.x) < 6.0:
		vx = 0.0
	var ty := home_y + sin(_bob) * 10.0
	velocity = Vector2(vx, (ty - global_position.y) * 3.0)


func _do_hover(delta: float, player: Node2D) -> void:
	_play(&"idle_fly")
	_hover_drift(delta, player, false)
	if _cooldown <= 0.0 and player:
		_choose_attack()


func _choose_attack() -> void:
	var p := _phase()
	var r := randf()
	if p == 1:
		_enter_swoop_tell()
	elif p == 2:
		if r < 0.5: _enter_swoop_tell()
		else: _enter_screech_tell()
	else:
		if r < 0.4: _enter_swoop_tell()
		elif r < 0.75: _enter_screech_tell()
		else: _state = SUMMON


func _enter_swoop_tell() -> void:
	_state = SWOOP_TELL
	_t = (0.55 if _phase() == 1 else 0.42) if _phase() < 3 else 0.3
	_flash_tell(Color(1.0, 0.8, 0.5))


func _do_swoop_tell(delta: float, player: Node2D) -> void:
	# Rear up slightly and lock onto the player's position.
	velocity = Vector2(0, -30)
	if player:
		_target = player.global_position
	_t -= delta
	if _t <= 0.0:
		_state = SWOOP
		_hit_player = false
		var dir := (_target - global_position).normalized()
		velocity = dir * swoop_speed
		_t = 0.7


func _do_swoop(delta: float, player: Node2D) -> void:
	_play(&"idle_fly")
	_t -= delta
	if player and not _hit_player and global_position.distance_to(player.global_position) < 38.0 \
			and player.has_method("receive_attack"):
		_hit_player = true
		player.receive_attack(self, contact_damage)
	# End the dive at the bottom of the arc or after the timeout.
	if _t <= 0.0 or global_position.y > home_y + 130.0:
		_state = RETURN


func _do_return(delta: float) -> void:
	velocity = Vector2(0, -return_speed)
	if global_position.y <= home_y + 6.0:
		_state = RECOVER
		_t = 0.5 if _phase() == 3 else 0.8


func _enter_screech_tell() -> void:
	_state = SCREECH_TELL
	_t = 0.55 if _phase() < 3 else 0.4
	_flash_tell(Color(0.7, 0.6, 1.0))


func _do_screech_tell(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
	_t -= delta
	if _t <= 0.0:
		_state = SCREECH


func _do_screech(player: Node2D) -> void:
	if player:
		var base := (player.global_position - global_position).normalized()
		var base_ang := base.angle()
		# A fan of three sonic shots.
		for off in [-0.28, 0.0, 0.28]:
			var shot := _shot.instantiate()
			get_parent().add_child(shot)
			shot.global_position = global_position + Vector2(0, 10)
			if shot.has_method("launch"):
				shot.launch(Vector2.from_angle(base_ang + off))
		_camera_shake(0.35)
	_state = RECOVER
	_t = 0.7 if _phase() == 3 else 1.0


func _do_summon() -> void:
	for i in range(2):
		var bat := BAT.instantiate()
		bat.add_to_group("summoned_bat")
		get_parent().add_child(bat)
		bat.global_position = global_position + Vector2(-30 + i * 60, 16)
	_flash_tell(Color(0.8, 0.7, 1.0))
	_state = RECOVER
	_t = 0.9


func _do_recover(delta: float) -> void:
	_hover_drift(delta, get_tree().get_first_node_in_group("player"), false)
	_t -= delta
	if _t <= 0.0:
		_state = HOVER
		_cooldown = [0.0, 1.2, 0.8, 0.4][_phase()]


# --- damage / death -----------------------------------------------------------

func take_damage(amount: int, from: Vector2 = Vector2.ZERO) -> void:
	if is_dead():
		return
	var was := _phase()
	super.take_damage(amount, from)
	if not _engaged:
		engage()
	health_changed.emit(maxi(health, 0), max_health)
	if not is_dead() and _phase() != was and _sprite:
		var tint := Color(0.8, 0.55, 0.7) if _phase() == 2 else Color(1.0, 0.5, 0.55)
		create_tween().tween_property(_sprite, "modulate", tint, 0.4)


## Player died mid-fight: reset to full HP (and clear the arena) so it's a clean
## retry — both of you start over, the way the player asked.
func reset_fight() -> void:
	if is_dead():
		return
	health = max_health
	_cooldown = 1.0
	velocity = Vector2.ZERO
	global_position = Vector2(global_position.x, home_y)
	if _sprite:
		_sprite.modulate = Color(0.7, 0.62, 0.8)
	for n in get_tree().get_nodes_in_group("boss_projectile"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("summoned_bat"):
		n.queue_free()
	_state = HOVER if _engaged else DORMANT
	health_changed.emit(health, max_health)


func _die() -> void:
	defeated.emit()
	health_changed.emit(0, max_health)
	QuestTracker.report_boss_defeated(boss_id)
	super._die()


func _flash_tell(c: Color) -> void:
	if not _sprite:
		return
	var prev := _sprite.modulate
	_sprite.modulate = c
	create_tween().tween_property(_sprite, "modulate", prev, 0.28)


func _camera_shake(amount: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(amount)
