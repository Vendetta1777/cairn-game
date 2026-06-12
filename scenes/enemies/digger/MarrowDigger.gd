extends EnemyBase
## Cairn — MARROW DIGGER (The Iron Warrens): a blind thing that hears through
## stone. It cannot see you at all — it feels VIBRATION. Running, jumping,
## landing or dashing near it triggers a savage lunge along the ground; walk
## (crouch-walk is best) and it lets you pass within arm's reach.
##   DOZE: stand at its dig site, swaying. Listens.
##   ALERT: heard something — rears up, faces the noise (0.4s, your warning).
##   LUNGE: a fast ground rush through where the noise was.
##   SETTLE: snuffles around, then back to dozing.

enum { DOZE, ALERT, LUNGE, SETTLE }

@export var hearing_range: float = 150.0
@export var loud_speed: float = 120.0   ## player speed that counts as "loud"
@export var lunge_speed: float = 330.0
@export var contact_damage: int = 2
@export var gravity: float = 1100.0

var _state := DOZE
var _t := 0.0
var _dir := -1.0
var _hit_player := false


func _ready() -> void:
	super._ready()
	stagger_resist = 0.3
	if _sprite:
		_sprite.modulate = Color(0.75, 0.7, 0.62)


func _hears(player: Node2D) -> bool:
	if player == null:
		return false
	var d := global_position.distance_to(player.global_position)
	if d > hearing_range:
		return false
	# Loud = fast horizontal movement, or any landing/dash burst.
	return absf(player.velocity.x) > loud_speed or absf(player.velocity.y) > 240.0


func _physics_process(delta: float) -> void:
	if is_dead():
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
	_t -= delta
	var player := get_tree().get_first_node_in_group("player")
	match _state:
		DOZE:
			velocity.x = 0.0
			_play(&"idle")
			if _hears(player):
				_state = ALERT
				_t = 0.4
				_dir = signf(player.global_position.x - global_position.x)
				_aggro_sound()
				_flash_tint(Color(1.0, 0.8, 0.6))
		ALERT:
			velocity.x = 0.0
			if _t <= 0.0:
				_state = LUNGE
				_t = 0.8
				_hit_player = false
				_play(&"walk")
		LUNGE:
			velocity.x = lunge_speed * _dir
			if player and not _hit_player \
					and absf(player.global_position.x - global_position.x) < 26.0 \
					and absf(player.global_position.y - global_position.y) < 40.0 \
					and player.has_method("receive_attack"):
				_hit_player = true
				player.receive_attack(self, contact_damage)
			if _t <= 0.0 or is_on_wall():
				_state = SETTLE
				_t = 1.4
		SETTLE:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			_play(&"idle")
			# Still listening — a noise mid-settle re-triggers instantly.
			if _hears(player):
				_state = ALERT
				_t = 0.35
				_dir = signf(player.global_position.x - global_position.x)
				_flash_tint(Color(1.0, 0.8, 0.6))
			elif _t <= 0.0:
				_state = DOZE
	if _sprite:
		_sprite.flip_h = _dir < 0.0
		# Blind: a slow searching sway while dozing.
		if _state == DOZE:
			_sprite.rotation = sin(Time.get_ticks_msec() / 600.0) * 0.06
		else:
			_sprite.rotation = 0.0
	move_and_slide()


func _flash_tint(c: Color) -> void:
	if not _sprite:
		return
	var prev := _sprite.modulate
	_sprite.modulate = c
	create_tween().tween_property(_sprite, "modulate", prev, 0.3)
