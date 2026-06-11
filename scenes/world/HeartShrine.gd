extends Node2D
## Cairn — a HEART SHRINE. The only source of max-health: every 5 levels one of
## these grants +½ a heart, permanently (3 hearts at the start, up to the cap of
## 5). One use ever per shrine — consumed state is persisted by shrine_id, so a
## return trip can't farm it. Drawn as a heart-red crystal on a small altar.

@export var shrine_id: String = "heart_shrine_1"

var _player_in := false
var _used := false
var _t := 0.0

@onready var _zone: Area2D = $Zone
@onready var _prompt: Control = $Prompt
@onready var _prompt_text: Label = $Prompt/Text
@onready var _light: PointLight2D = $Light


func _ready() -> void:
	_zone.area_entered.connect(_on_enter)
	_zone.area_exited.connect(_on_exit)
	_prompt.modulate.a = 0.0
	if PlayerProgress.has_flag("used_%s" % shrine_id):
		_used = true
		_light.energy = 0.15
		_prompt_text.text = "(spent)"


func _on_enter(area: Area2D) -> void:
	if area.get_parent() and area.get_parent().is_in_group("player"):
		_player_in = true
		create_tween().tween_property(_prompt, "modulate:a", 1.0, 0.2)


func _on_exit(area: Area2D) -> void:
	if area.get_parent() and area.get_parent().is_in_group("player"):
		_player_in = false
		create_tween().tween_property(_prompt, "modulate:a", 0.0, 0.2)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _player_in and not _used and Input.is_action_just_pressed("interact"):
		_claim()


func _claim() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var stats = player.get_node_or_null("Stats")
	if stats == null or not stats.has_method("grant_half_heart"):
		return
	if stats.grant_half_heart():
		_used = true
		PlayerProgress.set_flag("used_%s" % shrine_id)
		_prompt_text.text = "(spent)"
		create_tween().tween_property(_prompt, "modulate:a", 0.0, 0.4)
		# Bright pulse + fade as the heart's gift passes into you.
		var tw := create_tween()
		tw.tween_property(_light, "energy", 3.0, 0.2)
		tw.tween_property(_light, "energy", 0.15, 0.8)
		var banner := get_tree().get_first_node_in_group("location_title")
		if banner and banner.has_method("reveal"):
			banner.reveal("A HEART REMEMBERS", "+½ MAX HEART")


func _draw() -> void:
	var lit := not _used
	var glow := 0.6 + sin(_t * 1.8) * 0.3
	# Altar plinth.
	draw_rect(Rect2(-12, -10, 24, 10), Color(0.16, 0.14, 0.18))
	draw_rect(Rect2(-14, -2, 28, 3), Color(0.1, 0.09, 0.12))
	# Floating heart-crystal.
	var c := Vector2(0, -28 - sin(_t * 1.6) * 2.0)
	var s := 8.0
	var body := Color(0.85, 0.2, 0.3) if lit else Color(0.3, 0.18, 0.22)
	var hi := Color(1.0, 0.5, 0.55, glow) if lit else Color(0.4, 0.3, 0.32)
	if lit:
		draw_circle(c, 16.0, Color(0.85, 0.2, 0.3, 0.12 * glow))
	# heart shape from two lobes + a point
	draw_circle(c + Vector2(-s * 0.4, -s * 0.2), s * 0.5, body)
	draw_circle(c + Vector2(s * 0.4, -s * 0.2), s * 0.5, body)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 0.8, 0), c + Vector2(s * 0.8, 0), c + Vector2(0, s)]), body)
	draw_circle(c + Vector2(-s * 0.3, -s * 0.3), 1.6, hi)
