extends EnemyBase
## Cairn — ARCHIVIST SHADE (The Pale Library): what's left of a librarian,
## still shelving. It will not chase — it BLINKS between its perch points
## (authored markers, or auto-spread around its spawn), reads you, and throws
## bladed pages. Kill it between blinks.
##   PERCH: hover at the current perch; aim when the player is in range.
##   AIM (tell, 0.6s) -> THROW (1–2 pages) -> BLINK to another perch.

enum { PERCH, AIM, THROW, BLINK_OUT, BLINK_IN }

const PAGE := preload("res://scenes/enemies/archivist/BladedPage.tscn")

@export var perch_offsets: Array[Vector2] = []   ## relative perch spots
@export var aggro_range: float = 240.0
@export var pages_per_throw: int = 2

var _state := PERCH
var _t := 0.0
var _home := Vector2.ZERO
var _perch := 0
var _bob := 0.0


func _ready() -> void:
	super._ready()
	_home = global_position
	_bob = randf() * TAU
	if perch_offsets.is_empty():
		perch_offsets = [Vector2.ZERO, Vector2(-90, -30), Vector2(80, -50), Vector2(-40, 20)]
	if _sprite:
		_sprite.modulate = Color(0.8, 0.82, 0.95, 0.9)


func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		return
	if is_staggered():
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
		move_and_slide()
		return
	_bob += delta * 2.0
	_t -= delta
	var player := get_tree().get_first_node_in_group("player")
	var target := _home + perch_offsets[_perch]
	match _state:
		PERCH:
			velocity = (target + Vector2(0, sin(_bob) * 5.0) - global_position) * 4.0
			if player and global_position.distance_to(player.global_position) < aggro_range and _t <= 0.0:
				_state = AIM
				_t = 0.6
				_aggro_sound()
				_flash_tint(Color(1.0, 0.95, 0.7))
		AIM:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if _t <= 0.0:
				_state = THROW
				_throw(player)
		THROW:
			pass   # resolved instantly in _throw
		BLINK_OUT:
			velocity = Vector2.ZERO
			if _t <= 0.0:
				_perch = (_perch + 1 + randi() % (perch_offsets.size() - 1)) % perch_offsets.size()
				global_position = _home + perch_offsets[_perch]
				_state = BLINK_IN
				_t = 0.25
				if _sprite:
					_sprite.modulate.a = 0.0
		BLINK_IN:
			if _sprite:
				_sprite.modulate.a = minf(0.9, _sprite.modulate.a + delta * 4.0)
			if _t <= 0.0:
				_state = PERCH
				_t = 0.7
	if player and _sprite:
		_sprite.flip_h = player.global_position.x < global_position.x
	move_and_slide()


func _throw(player: Node2D) -> void:
	if player:
		for i in pages_per_throw:
			var page := PAGE.instantiate()
			get_parent().add_child(page)
			page.global_position = global_position + Vector2(0, -4)
			var dir := global_position.direction_to(player.global_position + Vector2(0, -8))
			page.launch(dir.rotated(randf_range(-0.1, 0.1)), 190.0 + i * 25.0)
		AudioManager.play_at("swipe", global_position, -10.0)
	# Blink away after the throw.
	_state = BLINK_OUT
	_t = 0.18
	if _sprite:
		var tw := create_tween()
		tw.tween_property(_sprite, "modulate:a", 0.0, 0.18)


func _flash_tint(c: Color) -> void:
	if not _sprite:
		return
	var prev := _sprite.modulate
	_sprite.modulate = c
	create_tween().tween_property(_sprite, "modulate", prev, 0.3)
