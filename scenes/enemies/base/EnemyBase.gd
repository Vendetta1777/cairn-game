extends CharacterBody2D
class_name EnemyBase
## Cairn — shared enemy base (GDD Section 6).
##
## M1/test scope: health + damage reaction (hurt flash + anim, death anim then
## free). The full shared AI state machine (idle→patrol→alerted→chase→attack)
## arrives in M4; this gives us a hittable, animated test dummy now.

signal died

@export var max_health: int = 3
@export var idle_anim: StringName = &"idle_fly"

var health: int
var _dead := false
var _stagger_timer := 0.0

@onready var _sprite: AnimatedSprite2D = get_node_or_null("Sprite")
@onready var _hurtbox: Area2D = get_node_or_null("Hurtbox")


func _ready() -> void:
	health = max_health
	_play(idle_anim)


func _process(delta: float) -> void:
	if _stagger_timer > 0.0:
		_stagger_timer = maxf(0.0, _stagger_timer - delta)


## Knocked back and stunned (e.g. by a parry). Subclasses pause their AI while
## is_staggered() is true and let the knockback velocity play out.
func stagger(from_position: Vector2, force: float = 230.0, duration: float = 0.9) -> void:
	if _dead:
		return
	_stagger_timer = duration
	velocity = (global_position - from_position).normalized() * force
	_play(&"hurt")


func is_staggered() -> bool:
	return _stagger_timer > 0.0


## Called by the player's attack hitbox.
func take_damage(amount: int, _from: Vector2 = Vector2.ZERO) -> void:
	if _dead:
		return
	health -= amount
	_flash()
	if health <= 0:
		_die()
	else:
		_play(&"hurt")


func _die() -> void:
	_dead = true
	died.emit()
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", false)
	set_deferred("velocity", Vector2.ZERO)
	if _has_anim(&"die"):
		_sprite.play(&"die")
		await _sprite.animation_finished
	queue_free()


func _flash() -> void:
	if not _sprite:
		return
	_sprite.modulate = Color(1.0, 0.5, 0.5)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.22)


func _play(anim: StringName) -> void:
	if _has_anim(anim):
		_sprite.play(anim)


func _has_anim(anim: StringName) -> bool:
	return _sprite != null and _sprite.sprite_frames != null \
		and _sprite.sprite_frames.has_animation(anim)


func is_dead() -> bool:
	return _dead
