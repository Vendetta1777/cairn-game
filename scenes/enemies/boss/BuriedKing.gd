extends EnemyBase
class_name BuriedKing
## Cairn — BOSS: THE BURIED KING (end of Area 5). The ancient ruler of Cairn,
## entombed so long the stone grew through him. A mountain that walks. His
## armour is impervious — ONLY THE GLOWING CRACKS take damage, and they only
## burn open in the recovery after each attack (read, dodge, punish).
##
## PHASE 1 (100–50%): GROUND SLAM (shockwaves both directions) ·
##   BOULDER HURL (tears stone from the wall, arcs it at you).
## PHASE 2 (50–0%): wakes the ceiling — STALACTITES drop (lure them onto him:
##   a direct hit bypasses the armour entirely) · ENRAGED CHARGES end-to-end ·
##   CROWN THROW (his own crown, bouncing across the arena 3 times).
## Death: a slow shatter; the crown falls and stays in the arena forever.

signal health_changed(cur: int, max: int)
signal engaged
signal defeated

enum { DORMANT, APPROACH, TELL_SLAM, SLAM, TELL_HURL, HURL, TELL_CHARGE, CHARGE, CROWN, CEILING, RECOVER }

const WAVE := preload("res://scenes/enemies/boss/AshWave.tscn")
const BOULDER := preload("res://scenes/enemies/boss/EmberFall.tscn")
const STALACTITE := preload("res://scenes/enemies/boss/FallingStalactite.tscn")
const CROWN_SCN := preload("res://scenes/enemies/boss/BouncingCrown.tscn")

@export var boss_id: String = "buried_king"
@export var walk_speed: float = 30.0
@export var charge_speed: float = 290.0
@export var attack_range: float = 150.0
@export var contact_damage: int = 2
@export var gravity: float = 1100.0
@export var arena_left: float = 0.0
@export var arena_right: float = 600.0
@export var floor_y: float = 252.0
@export var ceiling_y_pos: float = 60.0

var bar_phases := {
	"marks": [0.5],
	"colors": [Color(0.6, 0.55, 0.45), Color(0.85, 0.4, 0.3)],
}

var _state := DORMANT
var _t := 0.0
var _dir := -1.0
var _cooldown := 0.0
var _engaged := false
var _collapsing := false
var _hit_player := false
var _vulnerable := false     ## cracks open — the only time normal hits land
var _threw_crown := false
var _home := Vector2.ZERO

@onready var _aura: PointLight2D = get_node_or_null("Aura")


func _ready() -> void:
	super._ready()
	stagger_resist = 0.04
	_home = global_position
	if _sprite:
		_sprite.modulate = Color(0.6, 0.6, 0.62)


func _phase() -> int:
	return 2 if float(health) / float(max_health) <= 0.5 else 1


func engage() -> void:
	if _engaged or is_dead():
		return
	_engaged = true
	_state = APPROACH
	AudioManager.boss_music(true)
	engaged.emit()
	health_changed.emit(health, max_health)


func _process(delta: float) -> void:
	super._process(delta)
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if _aura:
		_aura.energy = (1.2 if _vulnerable else 0.45) + sin(Time.get_ticks_msec() / 200.0) * 0.1
		_aura.color = Color(1.0, 0.55, 0.25) if _vulnerable else Color(0.6, 0.62, 0.7)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if is_dead() or _collapsing:
		velocity = Vector2.ZERO
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)
	if is_staggered():
		velocity.x = move_toward(velocity.x, 0.0, 450.0 * delta)
		move_and_slide()
		return
	var player := get_tree().get_first_node_in_group("player")
	match _state:
		DORMANT:
			velocity.x = 0.0
			_play(&"idle")
		APPROACH:
			_do_approach(player)
		TELL_SLAM, TELL_HURL, TELL_CHARGE:
			velocity.x = 0.0
			if player and _state != TELL_CHARGE:
				_dir = signf(player.global_position.x - global_position.x)
			_t -= delta
			if _t <= 0.0:
				match _state:
					TELL_SLAM: _do_slam(player)
					TELL_HURL: _do_hurl(player)
					TELL_CHARGE:
						_state = CHARGE
						_t = 1.4
						_hit_player = false
		SLAM, HURL, CROWN, CEILING:
			velocity.x = 0.0   # resolved instantly by their entry calls
			_enter_recover()
		CHARGE:
			velocity.x = charge_speed * _dir
			_play(&"walk")
			if player and not _hit_player \
					and absf(player.global_position.x - global_position.x) < 38.0 \
					and absf(player.global_position.y - global_position.y) < 60.0 \
					and player.has_method("receive_attack"):
				_hit_player = true
				player.receive_attack(self, contact_damage)
			_t -= delta
			if _t <= 0.0 or is_on_wall() \
					or global_position.x < arena_left + 30.0 or global_position.x > arena_right - 30.0:
				_camera_shake(0.5)
				AudioManager.play_at("boss_slam", global_position, -6.0)
				_enter_recover()
		RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			_play(&"idle")
			_t -= delta
			if _t <= 0.0:
				_vulnerable = false
				_state = APPROACH
				_cooldown = 1.0 if _phase() == 1 else 0.5
	if _sprite and _state != CHARGE:
		_sprite.flip_h = _dir < 0.0
	move_and_slide()


func _do_approach(player: Node2D) -> void:
	if player == null:
		velocity.x = 0.0
		return
	_dir = signf(player.global_position.x - global_position.x)
	_play(&"walk")
	velocity.x = walk_speed * (1.6 if _phase() == 2 else 1.0) * _dir
	if absf(player.global_position.x - global_position.x) < attack_range and _cooldown <= 0.0:
		_choose_attack()


func _choose_attack() -> void:
	velocity.x = 0.0
	if _phase() == 1:
		if randf() < 0.55:
			_enter(TELL_SLAM, 1.2, Color(1.0, 0.8, 0.5))
		else:
			_enter(TELL_HURL, 0.9, Color(0.8, 0.85, 1.0))
	else:
		var r := randf()
		if not _threw_crown and float(health) / float(max_health) < 0.42:
			_threw_crown = true
			_do_crown()
		elif r < 0.3:
			_do_ceiling()
		elif r < 0.6:
			_enter(TELL_CHARGE, 0.7, Color(1.0, 0.5, 0.4))
		elif r < 0.85:
			_enter(TELL_SLAM, 0.9, Color(1.0, 0.8, 0.5))
		else:
			_enter(TELL_HURL, 0.7, Color(0.8, 0.85, 1.0))


func _enter(s: int, t: float, tell: Color) -> void:
	_state = s
	_t = t
	_play(&"attack")
	_flash_tell(tell)


func _do_slam(player: Node2D) -> void:
	AudioManager.play_at("boss_slam", global_position, 0.0)
	GameManager.hitstop(0.06)
	_camera_shake(0.85)
	for d in [-1.0, 1.0]:
		var wave := WAVE.instantiate()
		get_parent().add_child(wave)
		wave.global_position = Vector2(global_position.x + d * 22.0, floor_y)
		wave.launch(d, 2)
	if player and player.has_method("receive_attack") and player.has_method("is_on_floor") \
			and player.is_on_floor() and absf(player.global_position.x - global_position.x) < 70.0:
		player.receive_attack(self, contact_damage)
	_enter_recover()


func _do_hurl(player: Node2D) -> void:
	# Tear a boulder from the wall and arc it at the player's position.
	AudioManager.play_at("enemy_hurt", global_position, -4.0)
	var rock := BOULDER.instantiate()
	get_parent().add_child(rock)
	rock.global_position = global_position + Vector2(_dir * 20.0, -50.0)
	rock.setup(2, floor_y)
	if player:
		# EmberFall falls straight; give it a sideways start toward the player.
		rock.set("_vel", Vector2(signf(player.global_position.x - global_position.x) \
			* clampf(absf(player.global_position.x - global_position.x) * 1.1, 60.0, 240.0), -120.0))
	_enter_recover()


func _do_crown() -> void:
	_flash_tell(Color(1.0, 0.9, 0.5))
	AudioManager.play_at("door", global_position, -8.0)
	var crown := CROWN_SCN.instantiate()
	get_parent().add_child(crown)
	crown.global_position = global_position + Vector2(0, -52)
	crown.floor_y = floor_y
	crown.launch(_dir)
	_enter_recover()


func _do_ceiling() -> void:
	# He pounds the walls — the ceiling lets go.
	_flash_tell(Color(0.8, 0.8, 0.9))
	_camera_shake(0.6)
	AudioManager.play_at("boss_slam", global_position, -4.0)
	var player := get_tree().get_first_node_in_group("player")
	for i in 4:
		var st := STALACTITE.instantiate()
		get_parent().add_child(st)
		var x := randf_range(arena_left + 40.0, arena_right - 40.0)
		if i == 0 and player:
			x = clampf(player.global_position.x + randf_range(-30, 30), arena_left + 40.0, arena_right - 40.0)
		if i == 1:
			x = clampf(global_position.x + randf_range(-40, 40), arena_left + 40.0, arena_right - 40.0)
		st.global_position = Vector2(x, ceiling_y_pos)
		st.floor_y = floor_y
	_enter_recover()


## After every attack the cracks burn open — the punish window.
func _enter_recover() -> void:
	_state = RECOVER
	_t = 2.0 if _phase() == 1 else 1.3
	_vulnerable = true


# --- damage: armour and cracks --------------------------------------------------

func take_damage(amount: int, from: Vector2 = Vector2.ZERO) -> void:
	if is_dead() or _collapsing:
		return
	if not _engaged:
		engage()
	# from == ZERO marks a stalactite crush — always pierces the armour.
	if not _vulnerable and from != Vector2.ZERO:
		AudioManager.play_at("parry", global_position, -8.0)
		_flash_tell(Color(0.8, 0.82, 0.9))
		return
	var was := _phase()
	super.take_damage(amount, from)
	health_changed.emit(maxi(health, 0), max_health)
	if not is_dead() and _phase() != was:
		_flash_tell(Color(1.0, 0.4, 0.3))
		_camera_shake(0.7)
		if _sprite:
			create_tween().tween_property(_sprite, "modulate", Color(0.7, 0.55, 0.5), 0.5)
		_state = RECOVER
		_t = 1.0


func reset_fight() -> void:
	if is_dead():
		return
	health = max_health
	velocity = Vector2.ZERO
	global_position = _home
	_state = DORMANT
	_engaged = false
	_vulnerable = false
	_threw_crown = false
	_cooldown = 1.0
	if _sprite:
		_sprite.modulate = Color(0.6, 0.6, 0.62)
	for n in get_tree().get_nodes_in_group("boss_projectile"):
		n.queue_free()
	health_changed.emit(health, max_health)


func _die() -> void:
	if _collapsing:
		return
	_collapsing = true
	defeated.emit()
	health_changed.emit(0, max_health)
	QuestTracker.report_boss_defeated(boss_id)
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", false)
	for n in get_tree().get_nodes_in_group("boss_projectile"):
		n.queue_free()
	# The slow shatter: cracks race across him, pieces drop, then he goes.
	var tw := create_tween()
	for i in 4:
		tw.tween_callback(func():
			_burst_stone(6)
			_camera_shake(0.3))
		tw.tween_interval(0.45)
	tw.tween_callback(func():
		_burst_stone(26)
		GameManager.hitstop(0.12)
		_camera_shake(1.0)
		# The crown falls where he stood — and stays.
		var crown := Node2D.new()
		crown.set_script(preload("res://scenes/enemies/boss/CrownProp.gd"))
		get_parent().add_child(crown)
		crown.global_position = Vector2(global_position.x, floor_y)
		super._die())


func _burst_stone(n: int) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = n
	p.lifetime = 0.9
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 180.0
	p.gravity = Vector2(0, 360)
	p.scale_amount_min = 1.4
	p.scale_amount_max = 3.0
	p.color = Color(0.5, 0.48, 0.46)
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0, -24)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _flash_tell(c: Color) -> void:
	if not _sprite:
		return
	var prev := _sprite.modulate
	_sprite.modulate = c
	create_tween().tween_property(_sprite, "modulate", prev, 0.3)


func _camera_shake(amount: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(amount)


## The glowing cracks, drawn over the sprite while vulnerable.
func _draw() -> void:
	if is_dead() or _collapsing or not _vulnerable:
		return
	var glow := Color(1.0, 0.6, 0.25, 0.7 + sin(Time.get_ticks_msec() / 90.0) * 0.3)
	for seg in [[Vector2(-8, -52), Vector2(-2, -36)], [Vector2(-2, -36), Vector2(-10, -20)],
			[Vector2(6, -46), Vector2(10, -30)], [Vector2(10, -30), Vector2(4, -16)],
			[Vector2(-4, -14), Vector2(2, -4)]]:
		draw_line(seg[0], seg[1], glow, 2.0)
	draw_circle(Vector2(0, -32), 26.0, Color(1.0, 0.5, 0.2, 0.05))
