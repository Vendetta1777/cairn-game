extends EnemyBase
## Cairn — DROWNED FAITHFUL (The Sunken Nave): a waterlogged congregant still
## walking its procession, censer in hand. Slow and tanky; everything it does
## is telegraphed — a long censer wind-up you can read across the room — but
## the swing hits like a flooded bell.
##   IDLE -> WALK (processes toward you when you intrude) -> TELL (0.8s raise)
##   -> SWING (short arc, heavy damage) -> RECOVER (long, punishable).

enum { IDLE, WALK, TELL, SWING, RECOVER }

@export var aggro_range: float = 190.0
@export var walk_speed: float = 26.0
@export var swing_reach: float = 44.0
@export var swing_damage: int = 2      ## half-hearts — a full heart
@export var gravity: float = 1100.0

var _state := IDLE
var _t := 0.0
var _dir := -1.0
var _swung := false


func _ready() -> void:
	super._ready()
	stagger_resist = 0.22   # heavy with water
	if _sprite:
		_sprite.modulate = Color(0.5, 0.74, 0.7)


func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = maxf(velocity.y, 0.0)
	if is_staggered():
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player")
	match _state:
		IDLE:
			velocity.x = 0.0
			_play(&"idle")
			if player and _can_sense(player) and absf(player.global_position.x - global_position.x) < aggro_range \
					and absf(player.global_position.y - global_position.y) < 60.0:
				_aggro_sound()
				_state = WALK
		WALK:
			if player == null:
				_state = IDLE
				return
			_dir = signf(player.global_position.x - global_position.x)
			velocity.x = walk_speed * _dir
			_play(&"walk")
			var dist := absf(player.global_position.x - global_position.x)
			if dist > aggro_range * 1.3:
				_state = IDLE
			elif dist < swing_reach and absf(player.global_position.y - global_position.y) < 46.0:
				_state = TELL
				_t = 0.8
				_swung = false
				velocity.x = 0.0
				_play(&"attack")
				_flash_tell(Color(0.6, 0.95, 0.9))
		TELL:
			velocity.x = 0.0
			_t -= delta
			if _t <= 0.0:
				_state = SWING
				_t = 0.22
		SWING:
			velocity.x = 0.0
			if not _swung and player and player.has_method("receive_attack") \
					and absf(player.global_position.x - global_position.x) < swing_reach + 8.0 \
					and absf(player.global_position.y - global_position.y) < 46.0 \
					and signf(player.global_position.x - global_position.x) == _dir:
				_swung = true
				player.receive_attack(self, swing_damage)
			_t -= delta
			if _t <= 0.0:
				_state = RECOVER
				_t = 1.3
		RECOVER:
			velocity.x = 0.0
			_play(&"idle")
			_t -= delta
			if _t <= 0.0:
				_state = WALK

	if _sprite and _state != TELL and _state != SWING:
		_sprite.flip_h = _dir < 0.0
	move_and_slide()


func _flash_tell(c: Color) -> void:
	if not _sprite:
		return
	var prev := _sprite.modulate
	_sprite.modulate = c
	create_tween().tween_property(_sprite, "modulate", prev, 0.35)
