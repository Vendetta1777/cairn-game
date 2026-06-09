extends Node
class_name PlayerCombat
## Cairn — Player combat (GDD Section 5).
##
## MINIMAL melee for testing the hit loop (the full 4-hit combo / parry / ranged
## land in M3). On the "attack" input it flicks a Hitbox Area2D in front of the
## player for a short active window and damages any enemy hurtboxes inside it.
##
## NOTE: the current hooded sheet has no attack frame, so there's no swing
## animation yet — feedback comes from the enemy's hurt flash + death. A real
## attack animation / slash VFX comes with M3 (or a character sheet that has one).

signal attacked

@export var attack_cooldown: float = 0.32  ## min seconds between swings
@export var damage: int = 1

var _cooldown := 0.0
var _controller
var _hitbox: Area2D


func _ready() -> void:
	_controller = get_parent()
	_hitbox = get_node_or_null("../Hitbox")
	# Hitbox stays live so overlaps are always tracked; we only deal damage on
	# the attack input. (Toggling monitoring per-swing misses already-overlapping
	# enemies until physics catches up.)
	if _hitbox:
		_hitbox.monitoring = true


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	# Keep the hitbox in front of the facing direction.
	if _hitbox and _controller:
		_hitbox.position.x = absf(_hitbox.position.x) * _controller.get_facing()

	if Input.is_action_just_pressed("attack") and _cooldown <= 0.0:
		_do_attack()


func _do_attack() -> void:
	_cooldown = attack_cooldown
	attacked.emit()
	if not _hitbox:
		return
	var already := {}
	for area in _hitbox.get_overlapping_areas():
		var body := area.get_parent()
		if body and body.has_method("take_damage") and not already.has(body):
			already[body] = true
			body.take_damage(damage, _controller.global_position)
