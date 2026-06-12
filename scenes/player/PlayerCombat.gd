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
signal streak_changed(streak: int)
signal streak_broken

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
var _streak := 0          ## consecutive hits without taking damage (flow state)
var _attack_buffer := 0.0 ## input buffering: a press just before ready still fires
var _range_mult := 1.0    ## charm reach (Long Nail / Mark of Pride)
var _soul_gain_mult := 1.0
var _bases_captured := false
var _base_damage := 1
var _base_cooldown := 0.28
var _base_daggers := 3
var _base_bolt_cost := 20.0
var _streak_hooked := false
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
	if _controller.has_signal("parried") and not _controller.parried.is_connected(_on_parried):
		_controller.parried.connect(_on_parried)
	# Flow state breaks the moment you bleed.
	if _controller.has_signal("hurt") and not _streak_hooked:
		_streak_hooked = true
		_controller.hurt.connect(func(_amt):
			if _streak > 0:
				_streak = 0
				streak_broken.emit()
				AudioManager.play("parry_fail", -6.0, 0.0, &"SFX", 0.6))
	# Bonuses recompute from captured bases so re-attuning never stacks.
	if not _bases_captured:
		_bases_captured = true
		_base_damage = damage
		_base_cooldown = attack_cooldown
		_base_daggers = max_daggers
		_base_bolt_cost = shadow_bolt_cost
	# Skill tree first (additive), then the blade's temper, then charms on top.
	damage = _base_damage + int(PlayerProgress.bonus("damage")) + PlayerProgress.blade_tier
	_finisher_bonus = int(PlayerProgress.bonus("finisher_damage"))
	max_daggers = _base_daggers + int(PlayerProgress.bonus("dagger_charges"))
	shadow_bolt_cost = maxf(5.0, _base_bolt_cost - PlayerProgress.bonus("bolt_discount"))
	_bolt_pierce_bonus = int(PlayerProgress.bonus("bolt_pierce"))
	damage = maxi(1, int(round(damage * (1.0 + PlayerProgress.charm_bonus("damage_mult")))))
	attack_cooldown = _base_cooldown / (1.0 + PlayerProgress.charm_bonus("atk_speed"))
	_range_mult = 1.0 + PlayerProgress.charm_bonus("range_mult")
	if _hitbox:
		_hitbox.scale = Vector2(_range_mult, _range_mult)
	_soul_gain_mult = 1.0 + PlayerProgress.charm_bonus("soul_gain")
	shadow_bolt_cost = maxf(4.0, shadow_bolt_cost * (1.0 + PlayerProgress.charm_bonus("bolt_cost_mult")))
	_daggers = max_daggers
	call_deferred("emit_signal", "daggers_changed", _daggers)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo = 0
	# 8-DIRECTIONAL AIM: any held combination of W/S + A/D resolves to one of
	# eight strike directions; nothing held = forward.
	if _hitbox and _controller:
		var aim := _aim_dir()
		_hitbox.position = Vector2(aim.x * 22.0, -12.0 + aim.y * 26.0)

	# INPUT BUFFER: an attack pressed up to 0.1s early fires the moment the
	# cooldown ends — mashing never eats inputs.
	_attack_buffer = maxf(0.0, _attack_buffer - delta)
	if Input.is_action_just_pressed("attack"):
		if _cooldown <= 0.0:
			_do_attack()
		elif _cooldown <= 0.1:
			_attack_buffer = _cooldown + 0.02
	elif _attack_buffer > 0.0 and _cooldown <= 0.0:
		_attack_buffer = 0.0
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

	# 8-directional slash: the crescent rotates to the aim vector. Up-strikes
	# lift the player half a jump (aerial juggling); down-airs are the POGO.
	var aim := _aim_dir()
	var rot := 0.0
	var fh := facing > 0
	var fv := false
	var pos: Vector2 = _controller.global_position + Vector2(aim.x * slash_offset * 1.4 * _range_mult, slash_height + aim.y * 56.0 * _range_mult)
	slash_scale *= _range_mult
	if aim.y != 0.0:
		rot = aim.angle() - (0.0 if aim.x >= 0.0 else PI)
		if aim.x == 0.0:
			rot = -PI / 2.0 if aim.y < 0.0 else PI / 2.0
			fh = false
	else:
		fv = _combo == 1   # ground combo: middle hit reverses the arc
	# The blade's temper shows in every arc: worn grey -> clean white ->
	# gold-edged finishers -> the Void Nail's lingering dark tears.
	var tier := PlayerProgress.blade_tier
	var slash_tint := Color.WHITE
	match tier:
		0: slash_tint = Color(0.82, 0.84, 0.88)
		1: slash_tint = Color(1.0, 1.0, 1.0)
		2: slash_tint = Color(1.0, 0.92, 0.6) if is_finisher else Color(0.95, 0.95, 1.0)
		3: slash_tint = Color(0.55, 0.35, 0.8)
	var fx_slash: AnimatedSprite2D = SLASH.instantiate()
	parent.add_child(fx_slash)
	fx_slash.global_position = pos
	fx_slash.flip_h = fh
	fx_slash.flip_v = fv
	fx_slash.scale *= slash_scale
	fx_slash.rotation = rot
	fx_slash.modulate = slash_tint
	if tier >= 3:
		# A tear in space, briefly: a frozen dark copy that bleeds out.
		var tear: AnimatedSprite2D = SLASH.instantiate()
		parent.add_child(tear)
		tear.global_position = pos
		tear.flip_h = fh
		tear.scale *= slash_scale * 1.15
		tear.rotation = rot
		tear.modulate = Color(0.25, 0.1, 0.4, 0.8)
		tear.speed_scale = 0.25
		var tw := tear.create_tween()
		tw.tween_property(tear, "modulate:a", 0.0, 0.5)
		tw.tween_callback(tear.queue_free)
	# The upward strike lifts you into the air you just claimed.
	if aim.y < -0.5 and aim.x == 0.0:
		_controller.velocity.y = minf(_controller.velocity.y, _controller.jump_velocity * 0.5)

	if not _hitbox:
		return
	var already := {}
	var connected := false
	var pogoed := false
	var heaviest := ""
	var dmg := damage + ((1 + _finisher_bonus) if is_finisher else 0)
	var is_down_air: bool = aim.y > 0.5 and not _controller.is_on_floor()
	for area in _hitbox.get_overlapping_areas():
		var body := area.get_parent()
		# PROJECTILE DEFLECT: catch a shot mid-flight and send it back at 1.5x.
		if area.is_in_group("boss_projectile") and area.has_method("deflect"):
			area.deflect(Vector2(facing, aim.y * 0.3).normalized())
			_spawn_vfx(HIT_SPARK, parent, area.global_position, false, false, 1.3)
			AudioManager.play("parry", -8.0, 0.05, &"SFX", 1.3)
			connected = true
			if is_down_air:
				pogoed = true
			continue
		if body == null or already.has(body):
			continue
		# Corpses: pogo platforms; a finisher LAUNCHES them across the room.
		if body.is_in_group("corpse"):
			already[body] = true
			connected = true
			if is_down_air:
				pogoed = true
			elif is_finisher and body.has_method("launch"):
				body.launch(Vector2(facing, -0.25).normalized())
			continue
		if body.has_method("take_damage"):
			already[body] = true
			body.take_damage(dmg, _controller.global_position)
			_spawn_vfx(HIT_SPARK, parent, body.global_position, false)
			connected = true
			if is_down_air:
				pogoed = true
			# Track the heaviest thing we hit for the hit-stop scale.
			var w: String = str(body.get("weight")) if body.get("weight") != null else "medium"
			if _weight_rank(w) > _weight_rank(heaviest):
				heaviest = w

	if pogoed and _controller.has_method("pogo_bounce"):
		_controller.pogo_bounce()
	if connected:
		_on_hit_connected(is_finisher, heaviest)


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
	# Shaman Stone: a bigger, harder bolt. Catcher+Stone synergy: it SEARS.
	var bd := int(PlayerProgress.charm_bonus("bolt_damage"))
	if bd > 0 and bolt.get("damage") != null:
		bolt.damage += bd
	bolt.scale *= (1.0 + PlayerProgress.charm_bonus("bolt_size"))
	if PlayerProgress.charm_bonus("bolt_burn") > 0.0:
		bolt.modulate = Color(1.0, 0.7, 0.45)
		if bolt.get("damage") != null:
			bolt.damage += 1
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


## Held W/S + A/D resolve to one of eight unit-ish aim vectors; default forward.
func _aim_dir() -> Vector2:
	var f := float(_controller.get_facing()) if _controller else 1.0
	var y := 0.0
	if Input.is_action_pressed("move_up"):
		y = -1.0
	elif Input.is_action_pressed("move_down"):
		y = 1.0
	var x := 0.0
	if Input.is_action_pressed("move_left"):
		x = -1.0
	elif Input.is_action_pressed("move_right"):
		x = 1.0
	if y == 0.0:
		return Vector2(f if x == 0.0 else x, 0.0)
	if x == 0.0:
		return Vector2(0.0, y)
	return Vector2(x * 0.707, y * 0.707)   # the diagonals


func _weight_rank(w: String) -> int:
	match w:
		"light": return 1
		"medium": return 2
		"heavy": return 3
		"boss": return 4
	return 0


## Everything that happens when steel meets something: weight-scaled hit-stop
## (light things barely pause the world; bosses bend time), flow-state streak,
## soul-on-hit, and the usual spark and shake.
func _on_hit_connected(is_finisher: bool, heaviest: String) -> void:
	AudioManager.combat_ping()
	AudioManager.play("impact", -4.0 if is_finisher else -8.0, 0.08)
	if _camera and _camera.has_method("add_trauma"):
		_camera.add_trauma(0.5 if is_finisher else 0.32)
	# Hit-stop by weight: 2 / 3 / 5 / 7 frames — bosses add a beat of slow-mo.
	match heaviest:
		"light": GameManager.hitstop(0.033)
		"heavy": GameManager.hitstop(0.083)
		"boss":
			GameManager.hitstop(0.117)
			GameManager.slowmo(0.3, 0.08)
		_: GameManager.hitstop(0.05)
	# FLOW STATE: the streak climbs; at 20+, soul flows half again as fast.
	_streak += 1
	streak_changed.emit(_streak)
	if _stats:
		var gain := 2.5 * (1.5 if _streak >= 20 else 1.0) * _soul_gain_mult
		_stats.refill_shadow(gain)


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
