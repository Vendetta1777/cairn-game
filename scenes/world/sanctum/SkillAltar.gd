extends Node2D
## Cairn — the Sanctum's skill altar: a standing rune-stone. Step in and press
## interact to open the Skill Tree and spend Shards. Lore: where the Cairn-path
## is carved into the dead's memory.

var _player_in := false
var _t := 0.0

@onready var _zone: Area2D = $Zone
@onready var _prompt: Control = $Prompt


func _ready() -> void:
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
	if _player_in and Input.is_action_just_pressed("interact"):
		var tree := get_tree().get_first_node_in_group("skill_tree")
		if tree and tree.has_method("open") and not tree.is_open():
			tree.open()


func _draw() -> void:
	var glow := 0.6 + sin(_t * 1.6) * 0.3
	# Obelisk body (origin at base).
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, 0), Vector2(9, 0), Vector2(6, -54), Vector2(-6, -54)]), Color(0.16, 0.15, 0.22))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, 0), Vector2(-4, 0), Vector2(-3, -54), Vector2(-6, -54)]), Color(0.24, 0.22, 0.32))
	# Carved glowing rune.
	var rc := Color(0.6, 0.78, 1.0, 0.8 * glow)
	draw_arc(Vector2(0, -34), 6.0, 0, TAU, 16, rc, 1.5)
	draw_line(Vector2(0, -40), Vector2(0, -28), rc, 1.5)
	draw_line(Vector2(-5, -34), Vector2(5, -34), rc, 1.5)
	# Base stones.
	draw_rect(Rect2(-13, -4, 26, 4), Color(0.12, 0.11, 0.16))
