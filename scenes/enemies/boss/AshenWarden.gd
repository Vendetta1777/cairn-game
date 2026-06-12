extends EnemyBase
class_name AshenWarden
## Cairn — THE ASHEN WARDEN, end of Area 2 (The Ashpits): a colossal
## forge-guardian fused with the furnace machinery, still stoking a fire that
## consumed its kingdom. Dark-Souls paced: huge telegraphs, hard punishes,
## an explicit 2s vulnerable window after every attack.
##   PHASE 1 (100–50%):  SLAM — 1.5s windup, heavy shake, close-range quake.
##                       ASH SWEEP — ember waves rake the floor both ways.
##   PHASE 2 (50–0%):    enraged — faster tells, SLAMS TWICE in succession,
##                       CINDER RAIN — 4s of embers from the ceiling, and the
##                       arena's ash vents roar alive (group "arena_vent").
## engage() opens with a 2s intro: the camera pans across the arena, the
## furnace eyes kindle, then the fight begins.

signal health_changed(cur: int, max: int)
signal engaged
signal defeated

enum { DORMANT, INTRO, APPROACH, TELL_SLAM, SLAM, TELL_SWEEP, RAIN, RECOVER }

@export var boss_id: String = "ashen_warden"
@export var walk_speed: float = 38.0
@export var slam_range: float = 95.0       ## quake radius (grounded player only)
@export var attack_range: float = 130.0
@export var contact_damage: int = 2        ## half-hearts: brushing the quake
@export var sweep_damage: int = 2
@export var rain_damage: int = 1
@export var gravity: float = 1100.0
@export var arena_left: float = 2760.0
@export var arena_right: float = 3360.0
@export var floor_y: float = 252.0

const WAVE := preload("res://scenes/enemies/boss/AshWave.tscn")
const EMBER := preload("res://scenes/enemies/boss/EmberFall.tscn")

var _state := DORMANT
var _dir := -1.0
var _t := 0.0
var _cooldown := 0.0
var _engaged := false
var _collapsing := false
var _slam_chain := 0          ## phase 2: how many slams remain in this string
var _rain_timer := 0.0
var _did_rain_this_phase := false
var _home := Vector2.ZERO

@onready var _aura: PointLight2D = get_node_or_null("Aura")


func _ready() -> void:
	super._ready()
	stagger_resist = 0.08   # a furnace does not flinch
	_home = global_position
	if _sprite:
		_sprite.modulate = Color(0.85, 0.62, 0.45)


func _process(delta: float) -> void:
	super._process(delta)
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if _aura:
		var base := 1.0 if _phase() == 2 else 0.7
		_aura.energy = base + sin(Time.get_ticks_msec() / 180.0) * 0.18


func _phase() -> int:
	return 2 if float(health) / float(max_health) <= 0.5 else 1


## The arena trigger calls this. Runs the 2s intro pan, then starts the fight.
func engage() -> void:
	if _engaged or is_dead():
		return
	_engaged = true
	_state = INTRO
	_run_intro()


func _run_intro() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var pcam: Camera2D = player.get_node_or_null("Camera") if player else null
	if player == null or pcam == null:
		_begin_fight()
		return
	player.set_physics_process(false)
	# A free camera glides from the player across the arena to the Warden as its
	# furnace-heart kindles, holds on it, then returns.
	var cine := Camera2D.new()
	cine.zoom = pcam.zoom
	get_parent().add_child(cine)
	cine.global_position = pcam.get_screen_center_position()
	cine.make_current()
	var tw := create_tween()
	tw.tween_property(cine, "global_position", global_position + Vector2(0, -40), 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		if _aura:
			create_tween().tween_property(_aura, "energy", 1.8, 0.4)
		_flash_tell(Color(1.0, 0.6, 0.3))
		_camera_shake(0.5))
	tw.tween_interval(0.5)
	tw.tween_property(cine, "global_position", player.global_position + Vector2(0, -20), 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		pcam.make_current()
		cine.queue_free()
		if is_instance_valid(player):
			player.set_physics_process(true)
		_begin_fight())


func _begin_fight() -> void:
	_state = APPROACH
	engaged.emit()
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if is_dead() or _collapsing:
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
		DORMANT, INTRO:
			velocity.x = 0.0
			_play(&"idle")
		APPROACH:
			_do_approach(player)
		TELL_SLAM:
			_do_tell(delta, player, SLAM, 0.18)
		SLAM:
			_do_slam(delta, player)
		TELL_SWEEP:
			_do_tell(delta, player, -1, 0.0)   # -1: resolved in _do_tell as sweep
		RAIN:
			_do_rain(delta)
		RECOVER:
			_do_recover(delta)

	if _sprite:
		_sprite.flip_h = _dir < 0.0
	move_and_slide()


func _do_approach(player: Node2D) -> void:
	if player == null:
		velocity.x = 0.0
		return
	_dir = signf(player.global_position.x - global_position.x)
	_play(&"walk")
	velocity.x = walk_speed * (1.45 if _phase() == 2 else 1.0) * _dir
	var dist := absf(player.global_position.x - global_position.x)
	if dist < attack_range and _cooldown <= 0.0:
		_choose_attack(dist)


func _choose_attack(dist: float) -> void:
	velocity.x = 0.0
	if _phase() == 2:
		# Open every phase-2 storm with one Cinder Rain, then mix.
		if not _did_rain_this_phase:
			_did_rain_this_phase = true
			_enter_rain()
			return
		var r := randf()
		if r < 0.45:
			_slam_chain = 2          # enraged: slams twice in succession
			_enter_tell_slam()
		elif r < 0.8:
			_enter_tell_sweep()
		else:
			_enter_rain()
	else:
		_slam_chain = 1
		if dist < slam_range * 0.9:
			_enter_tell_slam()
		else:
			_enter_tell_sweep()


func _enter_tell_slam() -> void:
	_state = TELL_SLAM
	_t = 1.5 if _phase() == 1 else 1.0   # the spec'd slow, readable windup
	_play(&"attack")
	_flash_tell(Color(1.0, 0.75, 0.4))


func _enter_tell_sweep() -> void:
	_state = TELL_SWEEP
	_t = 0.9 if _phase() == 1 else 0.65
	_play(&"attack")
	_flash_tell(Color(1.0, 0.45, 0.2))


func _enter_rain() -> void:
	_state = RAIN
	_t = 4.0
	_rain_timer = 0.0
	_flash_tell(Color(1.0, 0.3, 0.15))
	_camera_shake(0.4)


## Shared windup: shiver in place, building shake, then resolve the attack.
func _do_tell(delta: float, player: Node2D, next: int, _pad: float) -> void:
	velocity.x = 0.0
	if player:
		_dir = signf(player.global_position.x - global_position.x)
	# The ground itself trembles as the windup peaks.
	if _state == TELL_SLAM and _t < 0.5:
		_camera_shake(0.06)
	_t -= delta
	if _t > 0.0:
		return
	if next == SLAM:
		_state = SLAM
		_t = 0.12
	else:
		_fire_sweep()


func _do_slam(delta: float, player: Node2D) -> void:
	velocity.x = 0.0
	_t -= delta
	if _t > 0.0:
		return
	# IMPACT: heavy shake, dust, and a grounded-player quake in slam_range.
	_camera_shake(0.85)
	GameManager.hitstop(0.05)
	_spawn_slam_dust()
	if player and player.has_method("receive_attack") and player.has_method("is_on_floor"):
		if player.is_on_floor() and absf(player.global_position.x - global_position.x) < slam_range:
			player.receive_attack(self, contact_damage)
	_slam_chain -= 1
	if _slam_chain > 0:
		# Enraged double slam: a short re-lift, then down again.
		_state = TELL_SLAM
		_t = 0.55
		_flash_tell(Color(1.0, 0.6, 0.3))
	else:
		_enter_recover()


func _fire_sweep() -> void:
	for d in [-1.0, 1.0]:
		var wave := WAVE.instantiate()
		get_parent().add_child(wave)
		wave.global_position = Vector2(global_position.x + d * 18.0, floor_y)
		wave.launch(d, sweep_damage)
	_camera_shake(0.45)
	_enter_recover()


func _do_rain(delta: float) -> void:
	velocity.x = 0.0
	_play(&"idle")
	_t -= delta
	_rain_timer -= delta
	if _rain_timer <= 0.0:
		_rain_timer = 0.16
		var ember := EMBER.instantiate()
		get_parent().add_child(ember)
		ember.global_position = Vector2(randf_range(arena_left, arena_right), 38.0)
		ember.setup(rain_damage, floor_y)
	if _t <= 0.0:
		_enter_recover()


## The spec'd vulnerable window: long, still, punishable.
func _enter_recover() -> void:
	_state = RECOVER
	_t = 2.0 if _phase() == 1 else 1.2
	_play(&"idle")


func _do_recover(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	_t -= delta
	if _t <= 0.0:
		_state = APPROACH
		_cooldown = 0.9 if _phase() == 1 else 0.45


# --- damage / phases / death ---------------------------------------------------

func take_damage(amount: int, from: Vector2 = Vector2.ZERO) -> void:
	if is_dead() or _collapsing:
		return
	var was := _phase()
	super.take_damage(amount, from)
	if not _engaged:
		engage()
	health_changed.emit(maxi(health, 0), max_health)
	if not is_dead() and _phase() == 2 and was == 1:
		_enrage()


## 50%: the Warden stokes itself — vents roar on, tint goes molten, tells quicken.
func _enrage() -> void:
	_flash_tell(Color(1.0, 0.35, 0.2))
	_camera_shake(0.7)
	_did_rain_this_phase = false
	if _sprite:
		create_tween().tween_property(_sprite, "modulate", Color(1.0, 0.5, 0.35), 0.5)
	for vent in get_tree().get_nodes_in_group("arena_vent"):
		if vent.has_method("set_active"):
			vent.set_active(true)
	_state = RECOVER
	_t = 0.8


## Player died mid-fight: clean retry. Back to the furnace, full health, calm vents.
func reset_fight() -> void:
	if is_dead():
		return
	health = max_health
	_cooldown = 1.0
	_slam_chain = 0
	_did_rain_this_phase = false
	velocity = Vector2.ZERO
	global_position = _home
	_state = DORMANT
	_engaged = false
	if _sprite:
		_sprite.modulate = Color(0.85, 0.62, 0.45)
	for n in get_tree().get_nodes_in_group("boss_projectile"):
		n.queue_free()
	for vent in get_tree().get_nodes_in_group("arena_vent"):
		if vent.has_method("set_active"):
			vent.set_active(false)
	health_changed.emit(health, max_health)


## Death: a slow collapse, then the furnace detonates and the room goes dark
## (the area root listens to `defeated` and kills the lights).
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
	for vent in get_tree().get_nodes_in_group("arena_vent"):
		if vent.has_method("set_active"):
			vent.set_active(false)
	# The slow collapse: it sinks, dims, shudders...
	var tw := create_tween()
	if _sprite:
		tw.parallel().tween_property(_sprite, "modulate", Color(0.3, 0.2, 0.18), 1.4)
		tw.parallel().tween_property(_sprite, "position:y", _sprite.position.y + 10.0, 1.4)
		tw.parallel().tween_property(_sprite, "scale:y", _sprite.scale.y * 0.8, 1.4)
	if _aura:
		tw.parallel().tween_property(_aura, "energy", 0.0, 1.2)
	tw.tween_callback(_explode)


## ...then the furnace goes up.
func _explode() -> void:
	_camera_shake(1.0)
	GameManager.hitstop(0.1)
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 60
	p.lifetime = 1.1
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 220.0
	p.gravity = Vector2(0, 240)
	p.scale_amount_min = 1.0
	p.scale_amount_max = 3.0
	p.color = Color(1.0, 0.55, 0.2)
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0, -16)
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)
	super._die()


func _flash_tell(c: Color) -> void:
	if not _sprite:
		return
	var prev := _sprite.modulate
	_sprite.modulate = c
	create_tween().tween_property(_sprite, "modulate", prev, 0.3)


func _spawn_slam_dust() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 22
	p.lifetime = 0.55
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 150.0
	p.gravity = Vector2(0, 320)
	p.color = Color(0.55, 0.45, 0.4, 0.85)
	get_parent().add_child(p)
	p.global_position = Vector2(global_position.x, floor_y)
	get_tree().create_timer(0.9).timeout.connect(p.queue_free)


func _camera_shake(amount: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(amount)
