extends Node2D
## Cairn — a Shrine (GDD Section 9). Step in, interact, and it offers three random
## run-only boons to choose from. One use per shrine per run. A bowl of pale fire
## on a short plinth, drawn procedurally.

const Boons = preload("res://scenes/systems/RunBoons.gd")

var _player_in := false
var _used := false
var _t := 0.0

@onready var _zone: Area2D = $Zone
@onready var _prompt: Control = $Prompt
@onready var _prompt_text: Label = $Prompt/Text


func _ready() -> void:
	add_to_group("shrine")   # for the map overlay
	AudioManager.attach_loop(self, "shrine_loop", -20.0)
	_zone.area_entered.connect(_on_enter)
	_zone.area_exited.connect(_on_exit)
	_prompt.modulate.a = 0.0


func _on_enter(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		_player_in = true
		create_tween().tween_property(_prompt, "modulate:a", 1.0, 0.2)


func _on_exit(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		_player_in = false
		create_tween().tween_property(_prompt, "modulate:a", 0.0, 0.2)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _player_in and not _used and Input.is_action_just_pressed("interact"):
		var ui := get_tree().get_first_node_in_group("boon_choice")
		if ui and ui.has_method("open") and not ui.is_open():
			ui.open(Boons.roll_three())
			_used = true
			_prompt_text.text = "(the fire dims)"


func _draw() -> void:
	var lit := not _used
	var flick := 0.6 + sin(_t * 6.0) * 0.2 + sin(_t * 11.0) * 0.1
	# Plinth.
	draw_rect(Rect2(-10, -16, 20, 16), Color(0.14, 0.13, 0.18))
	draw_rect(Rect2(-12, -4, 24, 4), Color(0.1, 0.09, 0.13))
	# Bowl.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -16), Vector2(12, -16), Vector2(8, -22), Vector2(-8, -22)]), Color(0.2, 0.19, 0.26))
	if lit:
		# Pale flame.
		var c := Color(0.6, 0.74, 1.0, 0.9)
		for i in range(5):
			var h := (14.0 + i * 3.0) * flick
			var w := 7.0 - i * 1.2
			draw_colored_polygon(PackedVector2Array([
				Vector2(-w, -20), Vector2(w, -20), Vector2(0, -20 - h)]),
				Color(c.r, c.g, c.b, 0.5 - i * 0.08))
		draw_circle(Vector2(0, -22), 4.0 * flick, Color(0.85, 0.92, 1.0, 0.8))
	else:
		draw_circle(Vector2(0, -20), 2.0, Color(0.3, 0.3, 0.36))
