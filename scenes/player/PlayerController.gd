extends CharacterBody2D
class_name PlayerController
## Cairn — Player movement controller (Milestone 1).
##
## Implements the full M1 movement spec from the GDD (Section 4):
## run with deceleration, variable-height jump, coyote time, jump buffer,
## dash with i-frames, and crouch / silent crouch-walk.
##
## Abilities unlocked later in the game (double jump, wall-slide, wall-run,
## swim, grapple) are stubbed as locked flags so the structure is ready for
## M2+ without rework.
##
## Timings expressed "in frames" assume a 60 Hz physics tick
## (see project.godot -> physics/common/physics_ticks_per_second=60).

# --- Tunables (exported so they can be tuned live in the Godot inspector) ---
@export_group("Run")
@export var run_speed: float = 200.0          ## GDD: 200px/s base (260 upgrade later)
@export var ground_accel: float = 1600.0      ## px/s^2 — how fast we reach run_speed
@export var ground_decel: float = 2200.0      ## px/s^2 — snappy stop when input released
@export var air_accel: float = 1000.0         ## looser control in the air
@export var air_decel: float = 800.0

@export_group("Jump")
@export var jump_velocity: float = -360.0     ## upward impulse (negative = up)
@export var jump_cut_factor: float = 0.45     ## velocity kept when jump released early (variable height)
@export var gravity: float = 1100.0
@export var max_fall_speed: float = 700.0
@export var coyote_frames: int = 6            ## GDD: 6 frames of grace after leaving a ledge
@export var jump_buffer_frames: int = 8       ## GDD: 8 frames — early press still fires on landing

@export_group("Dash")
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.15       ## GDD: 0.15s
@export var dash_cooldown: float = 0.5        ## GDD: 0.5s
# i-frames last the whole dash; see is_invincible().

@export_group("Crouch")
@export var crouch_speed_mult: float = 0.5    ## crouch-walk is slower
@export var crouch_detection_mult: float = 0.4 ## GDD: -60% detection radius => 40% remains

# --- Ability gates: movement powers are found as Ability Relics in the world
# and persist in PlayerProgress. require_unlocks=false (e.g. TestLevel) keeps
# the exported values as-is for isolated testing.
@export_group("Unlocked Abilities")
@export var require_unlocks: bool = true      ## read dash/wall/double from PlayerProgress
@export var can_dash: bool = true             ## found in Area 1 (The Hollowed Gate)
@export var can_double_jump: bool = false     ## found in Area 3 (The Sunken Nave)
@export var can_wall_slide: bool = true       ## wall-slide + wall-jump — found in Area 2 (The Ashpits)
@export var can_swim: bool = false            ## Area 3
@export var can_grapple: bool = false         ## Area 5

@export_group("Wall")
@export var wall_slide_speed: float = 90.0    ## capped fall speed while hugging a wall
@export var wall_jump_velocity: float = -340.0
@export var wall_jump_push: float = 270.0     ## horizontal kick away from the wall
@export var wall_jump_lock_time: float = 0.16 ## air-control is muted briefly after a wall jump

@export_group("Damage")
@export var hurt_invuln_time: float = 0.8     ## i-frames after taking a hit
@export var hurt_stun_time: float = 0.22      ## brief loss of control (knockback)
@export var knockback_force: float = 200.0
@export var parry_window_time: float = 0.14   ## GDD: tight window — press attack on the enemy's strike

# --- Signals (the animator and stealth systems listen to these) ---
signal state_changed(new_state: String)
signal jumped
signal dashed
signal landed
signal hurt(amount: int)
signal parried(attacker: Node)

# --- Internal state ---
var _facing: int = 1                          ## 1 = right, -1 = left (for attacks/animation flip)
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _is_dashing: bool = false
var _is_crouching: bool = false
var _was_on_floor: bool = false
var _current_state: String = "idle"
var _hurt_iframes: float = 0.0
var _hurt_stun: float = 0.0
var _parry_window: float = 0.0
var _wall_jump_lock: float = 0.0
var _is_wall_sliding: bool = false
var _air_jumps: int = 0                       ## double-jump charges left this airtime
var speed_zone_mult: float = 1.0              ## set by WaterZones (wading drag)

# Cached frame->seconds conversions (computed in _ready from the physics tick).
var _coyote_time: float
var _jump_buffer_time: float


func _ready() -> void:
	var tick := float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60))
	_coyote_time = coyote_frames / tick
	_jump_buffer_time = jump_buffer_frames / tick
	# Permanent Body / Blade skill-tree bonuses.
	run_speed += PlayerProgress.bonus("run_speed")
	parry_window_time += PlayerProgress.bonus("parry_window")
	hurt_invuln_time += PlayerProgress.bonus("dash_iframes")
	# Movement powers come from found Ability Relics (persisted), and switch on
	# live the moment one is claimed mid-level.
	if require_unlocks:
		_apply_ability_unlocks()
		PlayerProgress.ability_unlocked.connect(func(_id): _apply_ability_unlocks())


func _apply_ability_unlocks() -> void:
	can_dash = PlayerProgress.has_ability("dash")
	can_wall_slide = PlayerProgress.has_ability("wall_jump")
	can_double_jump = PlayerProgress.has_ability("double_jump")


func _physics_process(delta: float) -> void:
	_update_timers(delta)

	# Dash overrides normal movement for its (short) duration.
	if _is_dashing:
		_process_dash(delta)
		move_and_slide()
		_update_state()
		return

	_apply_gravity(delta)

	# During hurt-stun the player has no control — the knockback plays out.
	if _hurt_stun > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, ground_decel * 0.5 * delta)
		move_and_slide()
		_post_move()
		_update_state()
		return

	_handle_buffered_jump_input()
	_handle_wall_slide(delta)
	_handle_jump()
	_handle_dash_start()
	_handle_crouch()
	_apply_horizontal_movement(delta)

	move_and_slide()
	_post_move()
	_update_state()


# --- Timers ----------------------------------------------------------------

func _update_timers(delta: float) -> void:
	# Coyote time: refresh while grounded, count down once airborne.
	if is_on_floor():
		_coyote_timer = _coyote_time
		_air_jumps = 1 if can_double_jump else 0
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)

	# Jump buffer: started on press, counts down so a slightly-early press still lands.
	_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer = maxf(0.0, _dash_cooldown_timer - delta)

	_hurt_iframes = maxf(0.0, _hurt_iframes - delta)
	_hurt_stun = maxf(0.0, _hurt_stun - delta)
	_parry_window = maxf(0.0, _parry_window - delta)
	_wall_jump_lock = maxf(0.0, _wall_jump_lock - delta)


func _handle_buffered_jump_input() -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = _jump_buffer_time


# --- Vertical movement -----------------------------------------------------

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


## Slow the slide while pressing into a wall in mid-air. Sets the flag wall-jump
## and the animator read.
func _handle_wall_slide(_delta: float) -> void:
	_is_wall_sliding = false
	if not can_wall_slide or is_on_floor() or not is_on_wall_only():
		return
	var wall_normal := get_wall_normal().x        # points away from the wall
	var pressing := Input.get_axis("move_left", "move_right")
	# Only slide if actively holding toward the wall and falling.
	if pressing != 0.0 and signf(pressing) == -signf(wall_normal) and velocity.y > 0.0:
		_is_wall_sliding = true
		velocity.y = minf(velocity.y, wall_slide_speed)


func _handle_jump() -> void:
	# A jump fires when a buffered press meets ground OR coyote grace.
	var grounded_or_coyote := is_on_floor() or _coyote_timer > 0.0
	if _jump_buffer_timer > 0.0 and grounded_or_coyote:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		jumped.emit()
	# Wall jump: airborne, hugging a wall — kick up and away.
	elif _jump_buffer_timer > 0.0 and can_wall_slide and is_on_wall_only():
		var wall_normal := get_wall_normal().x
		velocity.y = wall_jump_velocity
		velocity.x = wall_normal * wall_jump_push
		_facing = int(signf(wall_normal))
		_wall_jump_lock = wall_jump_lock_time
		_jump_buffer_timer = 0.0
		_air_jumps = 1 if can_double_jump else 0   # a wall kick refreshes the air jump
		jumped.emit()
	# Double jump: airborne with a charge left — a second, slightly softer leap.
	elif _jump_buffer_timer > 0.0 and can_double_jump and _air_jumps > 0:
		_air_jumps -= 1
		velocity.y = jump_velocity * 0.92
		_jump_buffer_timer = 0.0
		jumped.emit()

	# Variable height: releasing jump while still rising cuts the ascent short.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_factor


# --- Dash ------------------------------------------------------------------

func _handle_dash_start() -> void:
	if not can_dash:
		return
	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0:
		_is_dashing = true
		_dash_timer = dash_duration
		_dash_cooldown_timer = dash_cooldown
		# Dash in facing direction (or input direction if one is held).
		var dir := Input.get_axis("move_left", "move_right")
		var dash_dir := signf(dir) if dir != 0.0 else float(_facing)
		velocity.x = dash_dir * dash_speed
		velocity.y = 0.0  # flat dash — no gravity influence during the burst
		dashed.emit()


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_is_dashing = false
		# Bleed horizontal speed back toward run cap so the dash doesn't fling us.
		velocity.x = clampf(velocity.x, -run_speed, run_speed)


# --- Horizontal movement & crouch -----------------------------------------

func _handle_crouch() -> void:
	# Crouch only on the ground; holding crouch enables silent crouch-walk.
	_is_crouching = is_on_floor() and Input.is_action_pressed("crouch")


func _apply_horizontal_movement(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")

	if dir != 0.0:
		_facing = int(signf(dir))

	var target_speed := run_speed * speed_zone_mult
	if _is_crouching:
		target_speed *= crouch_speed_mult

	# Just after a wall jump, mute air control so the kick away actually carries.
	if _wall_jump_lock > 0.0:
		return

	var accel := ground_accel if is_on_floor() else air_accel
	var decel := ground_decel if is_on_floor() else air_decel

	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * target_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)


func _post_move() -> void:
	# Landing detection for sfx/animation/squash later.
	if is_on_floor() and not _was_on_floor:
		landed.emit()
	_was_on_floor = is_on_floor()


# --- State (drives PlayerAnimator) ----------------------------------------

func _update_state() -> void:
	var new_state := _resolve_state()
	if new_state != _current_state:
		_current_state = new_state
		state_changed.emit(new_state)


func _resolve_state() -> String:
	if _hurt_stun > 0.0:
		return "hurt"
	if _is_dashing:
		return "dash"
	if _is_wall_sliding:
		return "wall_slide"
	if not is_on_floor():
		return "fall" if velocity.y > 0.0 else "jump"
	if _is_crouching:
		return "crawl" if absf(velocity.x) > 1.0 else "crouch"
	if absf(velocity.x) > 1.0:
		return "run"
	return "idle"


# --- Public API (used by stealth / combat / animator) ---------------------

## True while dashing (GDD i-frames) or during post-hit invulnerability.
func is_invincible() -> bool:
	return _is_dashing or _hurt_iframes > 0.0

## Take a hit (amount in half-hearts). Ignored while invincible. Enemies call this.
func take_damage(amount: int = 1, from_position: Vector2 = Vector2.ZERO) -> void:
	if is_invincible():
		return
	var stats := get_node_or_null("Stats")
	if stats:
		stats.take_damage(amount)
	_hurt_iframes = hurt_invuln_time
	_hurt_stun = hurt_stun_time
	# Knock back away from the damage source.
	var dir := signf(global_position.x - from_position.x)
	if dir == 0.0:
		dir = -float(_facing)
	velocity.x = dir * knockback_force
	velocity.y = -110.0
	hurt.emit(amount)
	# Juice: a solid shake + brief freeze when YOU get hit.
	var cam := get_node_or_null("Camera")
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.6)
	GameManager.hitstop(0.09)


## Enemies call this when an attack connects with the player. If the parry window
## is open it becomes a parry; otherwise it's normal damage (or ignored in iframes).
func receive_attack(attacker: Node = null, amount: int = 1) -> void:
	if _parry_window > 0.0:
		_do_parry(attacker)
		return
	var from := global_position
	if attacker and is_instance_valid(attacker):
		from = attacker.global_position
	take_damage(amount, from)

## Opens the parry window — PlayerCombat calls this on every attack press.
func open_parry_window() -> void:
	_parry_window = parry_window_time

func _do_parry(attacker: Node) -> void:
	_parry_window = 0.0
	# GDD: full shadow-energy refill, brief slow-mo, enemy staggered.
	var stats := get_node_or_null("Stats")
	if stats:
		stats.refill_shadow()
	GameManager.slowmo(0.25, 0.18)
	var cam := get_node_or_null("Camera")
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.45)
	var anim := get_node_or_null("Animator")
	if anim and anim.has_method("flash"):
		anim.flash(Color(1.0, 1.0, 1.0))   # white parry flash
	if attacker and is_instance_valid(attacker) and attacker.has_method("stagger"):
		attacker.stagger(global_position)
	parried.emit(attacker)

## Apply a run boon (from a Shrine) live to the current run. Routes each stat
## key to the component that owns it. Not persisted — a fresh player has none.
func grant_boon(effect: Dictionary) -> void:
	if effect.has("run_speed"):
		run_speed += float(effect["run_speed"])
	if effect.has("parry_window"):
		parry_window_time += float(effect["parry_window"])
	var combat := get_node_or_null("Combat")
	if combat and effect.has("damage"):
		combat.damage += int(effect["damage"])
	var stats := get_node_or_null("Stats")
	if stats and effect.has("max_shadow"):
		stats.max_shadow += float(effect["max_shadow"])
		stats.refill_shadow()


## 1 = facing right, -1 = facing left.
func get_facing() -> int:
	return _facing

func get_current_state() -> String:
	return _current_state

## Detection-radius multiplier the stealth system reads. Crouch-walk = quieter.
func get_detection_multiplier() -> float:
	return crouch_detection_mult if _is_crouching else 1.0
