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
@export var shard_drop: int = 1   ## Shards (kept on death) awarded on kill
@export var echo_drop: int = 3    ## Echoes (lost on death) awarded on kill
@export var stagger_resist: float = 0.45  ## <1 = heavy: shrugs off knockback (1 = light)

var health: int
var _dead := false
var _stagger_timer := 0.0
var _breath_base := Vector2.ONE
var _breath_phase := 0.0

@onready var _sprite: AnimatedSprite2D = get_node_or_null("Sprite")
@onready var _hurtbox: Area2D = get_node_or_null("Hurtbox")


func _ready() -> void:
	add_to_group("enemy")   # the level's respawn registry finds enemies by this
	# New Game+: every cycle hardens the deep by 40%.
	if PlayerProgress.ng_plus > 0:
		max_health = int(ceil(max_health * (1.0 + 0.4 * PlayerProgress.ng_plus)))
	health = max_health
	_play(idle_anim)
	if _sprite:
		_breath_base = _sprite.scale
	_breath_phase = randf() * TAU


func _process(delta: float) -> void:
	if _stagger_timer > 0.0:
		_stagger_timer = maxf(0.0, _stagger_timer - delta)
	# Idle breathing: every living thing pulses, just barely, out of phase.
	if _sprite and not _dead:
		var b := 1.0 + sin(Time.get_ticks_msec() / 600.0 + _breath_phase) * 0.012
		_sprite.scale = Vector2(_breath_base.x, _breath_base.y * b)


## Knocked back and stunned (e.g. by a parry). Subclasses pause their AI while
## is_staggered() is true and let the knockback velocity play out.
func stagger(from_position: Vector2, force: float = 150.0, duration: float = 0.7) -> void:
	if _dead:
		return
	_stagger_timer = duration
	# Heavy enemies barely budge — the knockback is scaled by their resist.
	velocity = (global_position - from_position).normalized() * force * stagger_resist
	_play(&"hurt")


func is_staggered() -> bool:
	return _stagger_timer > 0.0


## Called by the player's attack hitbox.
func take_damage(amount: int, _from: Vector2 = Vector2.ZERO) -> void:
	if _dead:
		return
	health -= amount
	_flash()
	AudioManager.play_at("enemy_hurt", global_position, -10.0)
	# Dark ichor arcs away from the blow.
	var dir := (global_position - _from).normalized() if _from != Vector2.ZERO else Vector2.UP
	VFXManager.splatter(global_position + Vector2(0, -8), dir)
	if health <= 0:
		_die()
	else:
		_play(&"hurt")


## Subclasses chirp this when they first commit to attacking the player.
## Also heats the dynamic-music combat layer.
func _aggro_sound() -> void:
	AudioManager.play_at("aggro", global_position, -12.0, 500.0)
	AudioManager.combat_ping()


func _die() -> void:
	_dead = true
	died.emit()
	# Award currency to the player: Shards (kept) + Echoes (lost on death).
	if shard_drop > 0 or echo_drop > 0:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			var stats = player.get_node_or_null("Stats")
			if stats:
				if shard_drop > 0 and stats.has_method("add_shards"):
					stats.add_shards(shard_drop)
				if echo_drop > 0 and stats.has_method("add_echoes"):
					stats.add_echoes(echo_drop)
	AudioManager.play_at("enemy_death", global_position, -8.0)
	VFXManager.death_burst(global_position, _sprite.modulate if _sprite else Color(0.6, 0.8, 0.95))
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", false)
	set_deferred("velocity", Vector2.ZERO)
	if _has_anim(&"die"):
		_sprite.play(&"die")
		await _sprite.animation_finished
	elif _sprite:
		# No authored death anim: a per-type procedural exit — grounded things
		# CRUMPLE into the floor, flyers DISSIPATE upward.
		var tw := create_tween()
		if collision_mask & 1:
			tw.set_parallel(true)
			tw.tween_property(_sprite, "scale:y", _sprite.scale.y * 0.15, 0.3).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(_sprite, "position:y", _sprite.position.y + 10.0, 0.3)
			tw.tween_property(_sprite, "modulate:a", 0.0, 0.34)
		else:
			tw.set_parallel(true)
			tw.tween_property(_sprite, "position:y", _sprite.position.y - 16.0, 0.4)
			tw.tween_property(_sprite, "modulate:a", 0.0, 0.4)
		await tw.finished
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
