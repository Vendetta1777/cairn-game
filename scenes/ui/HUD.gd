extends Control
class_name HUD
## Cairn — HUD (GDD Section 10): a row of heart masks (each heart = 2 half-heart
## units, shown full/half/empty) and a thin shadow-energy bar beneath. Drawn
## procedurally for now (no heart art needed); binds to the player's PlayerStats.

@export var heart_size: float = 16.0
@export var heart_spacing: float = 19.0
@export var origin := Vector2(12.0, 12.0)
@export var heart_full := Color(0.82, 0.17, 0.22)
@export var heart_empty := Color(0.2, 0.09, 0.12)
@export var shadow_fill := Color(0.42, 0.84, 0.88)
@export var shadow_bg := Color(0.12, 0.14, 0.2)

var _cur_halves := 8
var _max_halves := 8
var _shadow := 50.0
var _shadow_max := 50.0


func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var stats := player.get_node_or_null("Stats")
	if stats:
		stats.health_changed.connect(_on_health)
		stats.shadow_changed.connect(_on_shadow)
		_on_health(stats.health, stats.max_health)
		_on_shadow(stats.shadow, stats.max_shadow)


func _on_health(current: int, maximum: int) -> void:
	_cur_halves = current
	_max_halves = maximum
	queue_redraw()


func _on_shadow(current: float, maximum: float) -> void:
	_shadow = current
	_shadow_max = maximum
	queue_redraw()


func _draw() -> void:
	var hearts := _max_halves / 2
	for i in hearts:
		var halves := clampi(_cur_halves - i * 2, 0, 2)
		_draw_heart(origin + Vector2(i * heart_spacing, 0.0), heart_size, halves)

	# Shadow bar under the hearts.
	var bar_y := origin.y + heart_size * 0.75 + 6.0
	var bar_w := maxf(64.0, hearts * heart_spacing - 4.0)
	draw_rect(Rect2(origin.x, bar_y, bar_w, 4.0), shadow_bg)
	var frac := (_shadow / _shadow_max) if _shadow_max > 0.0 else 0.0
	draw_rect(Rect2(origin.x, bar_y, bar_w * frac, 4.0), shadow_fill)


func _draw_heart(c: Vector2, s: float, halves: int) -> void:
	_heart_shape(c, s, heart_empty)            # empty base
	if halves >= 2:
		_heart_shape(c, s, heart_full)         # full
	elif halves == 1:
		_heart_left_half(c, s, heart_full)     # half


func _heart_shape(c: Vector2, s: float, col: Color) -> void:
	draw_circle(c + Vector2(-s * 0.22, -s * 0.08), s * 0.27, col)
	draw_circle(c + Vector2(s * 0.22, -s * 0.08), s * 0.27, col)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 0.46, 0.02 * s),
		c + Vector2(s * 0.46, 0.02 * s),
		c + Vector2(0.0, s * 0.55)]), col)


func _heart_left_half(c: Vector2, s: float, col: Color) -> void:
	draw_circle(c + Vector2(-s * 0.22, -s * 0.08), s * 0.27, col)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 0.46, 0.02 * s),
		c + Vector2(0.0, 0.02 * s),
		c + Vector2(0.0, s * 0.55)]), col)
