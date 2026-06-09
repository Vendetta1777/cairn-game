extends Control
class_name HUD
## Cairn — HUD (GDD Section 10). A row of heart masks (each heart = 2 half-heart
## units: full / half / empty) and a Shadow-Energy bar (the assassin's "mana" —
## powers cloak / shadow bolt / smoke bomb / shadow-step). Drawn procedurally and
## styled to the dark-fantasy palette; binds to the player's PlayerStats.

@export var heart_size: float = 17.0
@export var heart_spacing: float = 20.0
@export var origin := Vector2(13.0, 13.0)

# Heart palette (gothic blood).
@export var heart_bright := Color(0.86, 0.21, 0.25)
@export var heart_shade := Color(0.5, 0.1, 0.13)
@export var heart_outline := Color(0.06, 0.02, 0.03)
@export var heart_empty := Color(0.17, 0.08, 0.1)
@export var heart_glint := Color(0.98, 0.78, 0.78, 0.85)

# Shadow-energy bar palette (cold).
@export var energy_bright := Color(0.55, 0.92, 0.95)
@export var energy_deep := Color(0.18, 0.5, 0.62)
@export var energy_bg := Color(0.07, 0.09, 0.14)
@export var energy_frame := Color(0.02, 0.03, 0.06)
@export var energy_sheen := Color(0.8, 0.98, 1.0, 0.6)

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
	_draw_energy_bar(origin.y + heart_size * 0.78 + 9.0, hearts)


# --- Hearts ---------------------------------------------------------------

func _draw_heart(c: Vector2, s: float, halves: int) -> void:
	# Dark outline (a larger heart behind), then the fill.
	_heart_shape(c + Vector2(0.0, s * 0.05), s * 1.18, heart_outline)
	if halves == 0:
		_heart_shape(c, s, heart_empty)
		return
	if halves >= 2:
		_heart_shape(c, s, heart_bright)
		_heart_lower_shade(c, s)
		draw_circle(c + Vector2(-s * 0.24, -s * 0.16), s * 0.1, heart_glint)
	else:
		_heart_shape(c, s, heart_empty)          # right side reads empty
		_heart_left_half(c, s, heart_bright)
		draw_circle(c + Vector2(-s * 0.24, -s * 0.16), s * 0.09, heart_glint)


func _heart_shape(c: Vector2, s: float, col: Color) -> void:
	draw_circle(c + Vector2(-s * 0.22, -s * 0.08), s * 0.27, col)
	draw_circle(c + Vector2(s * 0.22, -s * 0.08), s * 0.27, col)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 0.46, 0.02 * s),
		c + Vector2(s * 0.46, 0.02 * s),
		c + Vector2(0.0, s * 0.55)]), col)


func _heart_lower_shade(c: Vector2, s: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 0.3, s * 0.16),
		c + Vector2(s * 0.3, s * 0.16),
		c + Vector2(0.0, s * 0.55)]), heart_shade)


func _heart_left_half(c: Vector2, s: float, col: Color) -> void:
	draw_circle(c + Vector2(-s * 0.22, -s * 0.08), s * 0.27, col)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 0.46, 0.02 * s),
		c + Vector2(0.0, 0.02 * s),
		c + Vector2(0.0, s * 0.55)]), col)


# --- Shadow-energy bar ----------------------------------------------------

func _draw_energy_bar(y: float, hearts: int) -> void:
	var frac := clampf(_shadow / _shadow_max, 0.0, 1.0) if _shadow_max > 0.0 else 0.0
	var h := 7.0
	var cy := y + h * 0.5

	# Orb sigil at the left — signals "energy / magic".
	var orb := Vector2(origin.x + 5.0, cy)
	draw_circle(orb, 6.0, energy_frame)
	draw_circle(orb, 4.6, energy_deep)
	draw_circle(orb, 4.6 * frac, energy_bright)  # orb "fills" with the bar
	draw_circle(orb + Vector2(-1.4, -1.4), 1.4, energy_sheen)

	# Bar.
	var bx := origin.x + 15.0
	var bw := maxf(60.0, hearts * heart_spacing - 18.0)
	draw_rect(Rect2(bx - 1.0, y - 1.0, bw + 2.0, h + 2.0), energy_frame)   # frame
	draw_rect(Rect2(bx, y, bw, h), energy_bg)                              # track
	var fw := bw * frac
	if fw > 0.0:
		draw_rect(Rect2(bx, y, fw, h), energy_deep)                       # base fill
		draw_rect(Rect2(bx, y, fw, h * 0.5), energy_bright)               # bright top
		draw_rect(Rect2(bx, y, fw, 1.0), energy_sheen)                    # sheen line
