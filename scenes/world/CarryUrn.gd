extends CharacterBody2D
## Cairn — a CARRYABLE URN (The Pale Library puzzles): a leaden archive urn
## heavy enough to hold a pressure plate down. Press E beside it to lift it
## overhead; press E again to set it down where you stand. While carried it
## rides above the player. Its Weight area presses plates (group "weight").

const GRAVITY := 1100.0

var _carried := false
var _player: Node2D
var _near := false

@onready var _zone: Area2D = $Zone
@onready var _prompt: Control = $Prompt


func _ready() -> void:
	add_to_group("weight")
	_zone.area_entered.connect(_on_zone)
	_zone.area_exited.connect(_off_zone)
	_prompt.modulate.a = 0.0


func _on_zone(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		_near = true
		create_tween().tween_property(_prompt, "modulate:a", 1.0, 0.15)


func _off_zone(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		_near = false
		create_tween().tween_property(_prompt, "modulate:a", 0.0, 0.15)


func _physics_process(delta: float) -> void:
	if _carried:
		if _player and is_instance_valid(_player):
			global_position = _player.global_position + Vector2(0, -30)
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("interact"):
			_set_down()
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	move_and_slide()
	if _near and Input.is_action_just_pressed("interact"):
		_pick_up()


func _pick_up() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	_carried = true
	collision_layer = 0
	_zone.set_deferred("monitoring", false)
	$WeightTag.set_deferred("monitorable", false)   # carried urns press nothing
	_prompt.modulate.a = 0.0
	AudioManager.play("chest", -16.0)


func _set_down() -> void:
	_carried = false
	collision_layer = 1
	_zone.set_deferred("monitoring", true)
	$WeightTag.set_deferred("monitorable", true)
	if _player:
		global_position = _player.global_position + Vector2(_player.get_facing() * 18.0, -6.0)
	velocity = Vector2.ZERO
	AudioManager.play("land", -12.0)


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	var lead := Color(0.3, 0.32, 0.36)
	var lead_d := Color(0.18, 0.19, 0.23)
	var band := Color(0.5, 0.46, 0.32)
	# A squat urn: body, shoulder, lip, sealing band.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, 0), Vector2(-10, -10), Vector2(-6, -18), Vector2(6, -18),
		Vector2(10, -10), Vector2(8, 0)]), lead)
	draw_rect(Rect2(-7, -21, 14, 4), lead_d)
	draw_rect(Rect2(-5, -23, 10, 2), lead)
	draw_rect(Rect2(-9, -11, 18, 2), band)
	draw_line(Vector2(-6, -16), Vector2(-4, -4), lead_d, 1.0)
