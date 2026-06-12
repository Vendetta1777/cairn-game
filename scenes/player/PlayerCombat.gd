extends Node
class_name PlayerCombat
## Cairn — Player combat (GDD Section 5).
##
## Melee with a 3-step combo chain: attacks pressed within combo_window chain
## (step 0 -> 1 -> 2 finisher), each with a varied slash (the middle hit reverses
## the arc, the finisher is bigger + hits harder). On connect: a hit spark,
## screen-shake, and a brief hit-stop for impact. (Parry / ranged are later M3.)

signal attacked(combo_step: int)
signal daggers_changed(count: int)

@export var attack_cooldown: float = 0.28  ## min seconds between swings
@export var damage: int = 1
@export var combo_window: float = 0.55     ## chain if you re-press within this
@export var slash_offset: float = 12.0
@export var slash_height: float = -3.0
@export var max_daggers: int = 3           ## GDD: 3 throwable charges
@export var shadow_bolt_cost: float = 20.0 ## GDD: shadow bolt costs 20 energy

const SLASH := preload("res://scenes/fx/Slash.tscn")
const HIT_SPARK := preload("res://scenes/fx/HitSpark.tscn")
const DAGGER := preload("res://scenes/fx/Dagger.tscn")
const SHADOW_BOLT := preload("res://scenes/fx/ShadowBolt.tscn")

var _cooldown := 0.0
var _combo := 0
var _combo_timer := 0.0
var _daggers := 3
var _finisher_bonus := 0      ## extra finisher damage from the Blade tree
var _bolt_pierce_bonus := 0   ## extra shadow-bolt pierce from the Shadow tree
var _controller
var _hitbox: Area2D
var _camera
var _stats


func _ready() -> void:
	_controller = get_parent()
	_hitbox = get_node_or_null("../Hitbox")
	_camera = get_node_or_null("../Camera")
	_stats = get_node_or_null("../Stats")
	# Hitbox stays live so overlaps are always tracked; damage only on input.
	if _hitbox:
		_hitbox.monitoring = true
	if _controller.has_signal("parried"):
		_controller.parried.connect(_on_parried)
	# Fold in permanent skill-tree bonuses (Blade / Shadow branches).
	damage += int(PlayerProgress.bonus("damage"))
	_finisher_bonus = int(PlayerProgress.bonus("finisher_damage"))
	max_daggers += int(PlayerProgress.bonus("dagger_charges"))
	shadow_bolt_cost = maxf(5.0, shadow_bolt_cost - PlayerProgress.bonus("bolt_discount"))
	_bolt_pierce_bonus = int(PlayerProgress.bonus("bolt_pierce"))
	_daggers = max_daggers
	call_deferred("emit_signal", "daggers_changed", _daggers)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo = 0
	# Aim the hitbox by held direction: W=up, S=down, else forward (A/D facing).
	if _hitbox and _controller:
		var f: int = _controller.get_facing()
		if Input.is_action_pressed("move_up"):
			_hitbox.position = Vector2(f * 4.0, -24.0)
		elif Input.is_action_pressed("move_down"):
			_hitbox.position = Vector2(f * 4.0, 24.0)
		else:
			# Reach forward to match the slash crescent's visual length.
			_hitbox.position = Vector2(f * 22.0, -12.0)

	if Input.is_action_just_pressed("attack") and _cooldown <= 0.0:
		_do_attack()
	if Input.is_action_just_pressed("throw"):
		_throw_dagger()
	if Input.is_action_just_pressed("ability"):
		_cast_shadow_bolt()


func _do_attack() -> void:
	_cooldown = attack_cooldown
	# Pressing attack also opens the parry window (GDD: parry = attack on the
	# enemy's strike). If an enemy hits you in the next few frames, it's parried.
	if _controller.has_method("open_parry_window"):
		_controller.open_parry_window()
	# Advance the combo if still within the window, else restart at 0.
	_combo = (_combo + 1) % 3 if _combo_timer > 0.0 else 0
	_combo_timer = combo_window
	attacked.emit(_combo)

	var facing: int = _controller.get_facing()
	var parent: Node = _controller.get_parent()
	var is_finisher := _combo == 2
	var slash_scale := 1.3 if is_finisher else 1.0
	AudioManager.play("swipe", -12.0, 0.1)

	# Directional slash by held input (rotate the flat crescent): W = up,
	# S = down, otherwise a forward sweep — independent of movement state.
	var pos: Vector2
	var fh := facing > 0
	var fv := false
	var rot := 0.0
	if Input.is_action_pressed("move_up"):
		rot = -PI / 2.0
		pos = _controller.global_position + Vector2(facing * 4.0, -66.0)
		fh = false
	elif Input.is_action_pressed("move_down"):
		rot = PI / 2.0
		pos = _controller.global_position + Vector2(facing * 4.0, 60.0)
		fh = false
	else:
		fv = _combo == 1   # ground combo: middle hit reverses the arc
		pos = _controller.global_position + Vector2(facing * slash_offset, slash_height)
	_spawn_vfx(SLASH, parent, pos, fh, fv, slash_scale, rot)

	if not _hitbox:
		return
	var already := {}
	var connected := false
	var dmg := damage + ((1 + _finisher_bonus) if is_finisher else 0)
	for area in _hitbox.get_overlapping_areas():
		var body := area.get_parent()
		if body and body.has_method("take_damage") and not already.has(body):
			already[body] = true
			body.take_damage(dmg, _controller.global_position)
			_spawn_vfx(HIT_SPARK, parent, body.global_position, false)
			connected = true

	if connected:
		AudioManager.combat_ping()
		AudioManager.play("impact", -4.0 if is_finisher else -8.0, 0.08)
		if _camera and _camera.has_method("add_trauma"):
			_camera.add_trauma(0.5 if is_finisher else 0.32)
		GameManager.hitstop(0.07 if is_finisher else 0.045)


## A successful parry: a bright burst + extra shake + refilled daggers (the rest
## — slow-mo, shadow refill, enemy stagger — is in PlayerController._do_parry).
func _on_parried(_attacker: Node) -> void:
	var parent: Node = _controller.get_parent()
	VFXManager.parry_ring(_controller.global_position + Vector2(0, -10))
	_spawn_vfx(HIT_SPARK, parent, _controller.global_position + Vector2(0, -8), false, false, 1.6)
	if _camera and _camera.has_method("add_trauma"):
		_camera.add_trauma(0.4)
	_daggers = max_daggers
	daggers_changed.emit(_daggers)


func _throw_dagger() -> void:
	if _daggers <= 0:
		return
	_daggers -= 1
	daggers_changed.emit(_daggers)
	_launch(DAGGER)


func _cast_shadow_bolt() -> void:
	if _stats == null or not _stats.spend_shadow(shadow_bolt_cost):
		return   # not enough shadow energy
	AudioManager.play("bolt", -6.0)
	var bolt := SHADOW_BOLT.instantiate()
	if bolt.has_method("setup"):
		bolt.setup(_controller.get_facing())
	bolt.pierce += _bolt_pierce_bonus
	_controller.get_parent().add_child(bolt)
	var f: int = _controller.get_facing()
	bolt.global_position = _controller.global_position + Vector2(f * 12.0, -8.0)


## Spawn a projectile scene at the player's front, aimed at the facing direction.
func _launch(packed: PackedScene) -> void:
	var facing: int = _controller.get_facing()
	var proj := packed.instantiate()
	if proj.has_method("setup"):
		proj.setup(facing)
	_controller.get_parent().add_child(proj)
	proj.global_position = _controller.global_position + Vector2(facing * 12.0, -8.0)


func get_dagger_count() -> int:
	return _daggers


# Inlined (not a static on OneShotVFX) to avoid a parse-time dependency on that
# global class name not being registered yet.
func _spawn_vfx(packed: PackedScene, parent: Node, at: Vector2, flip_h: bool,
		flip_v := false, scale_mult := 1.0, rot := 0.0) -> void:
	var fx: AnimatedSprite2D = packed.instantiate()
	parent.add_child(fx)
	fx.global_position = at
	fx.flip_h = flip_h
	fx.flip_v = flip_v
	fx.scale *= scale_mult
	fx.rotation = rot
