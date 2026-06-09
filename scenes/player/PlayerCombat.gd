extends Node
class_name PlayerCombat
## Cairn — Player combat (GDD Section 5).
##
## Melee with a 3-step combo chain: attacks pressed within combo_window chain
## (step 0 -> 1 -> 2 finisher), each with a varied slash (the middle hit reverses
## the arc, the finisher is bigger + hits harder). On connect: a hit spark,
## screen-shake, and a brief hit-stop for impact. (Parry / ranged are later M3.)

signal attacked(combo_step: int)

@export var attack_cooldown: float = 0.28  ## min seconds between swings
@export var damage: int = 1
@export var combo_window: float = 0.55     ## chain if you re-press within this
@export var slash_offset: float = 12.0
@export var slash_height: float = -3.0

const SLASH := preload("res://scenes/fx/Slash.tscn")
const HIT_SPARK := preload("res://scenes/fx/HitSpark.tscn")

var _cooldown := 0.0
var _combo := 0
var _combo_timer := 0.0
var _controller
var _hitbox: Area2D
var _camera


func _ready() -> void:
	_controller = get_parent()
	_hitbox = get_node_or_null("../Hitbox")
	_camera = get_node_or_null("../Camera")
	# Hitbox stays live so overlaps are always tracked; damage only on input.
	if _hitbox:
		_hitbox.monitoring = true
	if _controller.has_signal("parried"):
		_controller.parried.connect(_on_parried)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo = 0
	if _hitbox and _controller:
		_hitbox.position.x = absf(_hitbox.position.x) * _controller.get_facing()

	if Input.is_action_just_pressed("attack") and _cooldown <= 0.0:
		_do_attack()


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
	var flip_v := _combo == 1   # middle hit reverses the arc direction

	var slash_pos: Vector2 = _controller.global_position + Vector2(facing * slash_offset, slash_height)
	_spawn_vfx(SLASH, parent, slash_pos, facing > 0, flip_v, slash_scale)

	if not _hitbox:
		return
	var already := {}
	var connected := false
	var dmg := damage + (1 if is_finisher else 0)
	for area in _hitbox.get_overlapping_areas():
		var body := area.get_parent()
		if body and body.has_method("take_damage") and not already.has(body):
			already[body] = true
			body.take_damage(dmg, _controller.global_position)
			_spawn_vfx(HIT_SPARK, parent, body.global_position, false)
			connected = true

	if connected:
		if _camera and _camera.has_method("add_trauma"):
			_camera.add_trauma(0.5 if is_finisher else 0.32)
		GameManager.hitstop(0.07 if is_finisher else 0.045)


## A successful parry: a bright burst + extra shake (the rest — slow-mo, shadow
## refill, enemy stagger — is handled in PlayerController._do_parry).
func _on_parried(_attacker: Node) -> void:
	var parent: Node = _controller.get_parent()
	_spawn_vfx(HIT_SPARK, parent, _controller.global_position + Vector2(0, -8), false, false, 1.6)
	if _camera and _camera.has_method("add_trauma"):
		_camera.add_trauma(0.4)


# Inlined (not a static on OneShotVFX) to avoid a parse-time dependency on that
# global class name not being registered yet.
func _spawn_vfx(packed: PackedScene, parent: Node, at: Vector2, flip_h: bool,
		flip_v := false, scale_mult := 1.0) -> void:
	var fx: AnimatedSprite2D = packed.instantiate()
	parent.add_child(fx)
	fx.global_position = at
	fx.flip_h = flip_h
	fx.flip_v = flip_v
	fx.scale *= scale_mult
