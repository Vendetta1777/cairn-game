extends Control
class_name HUD
## Cairn — HUD (GDD Section 10). Health hearts + Shadow-Energy ("mana") bar,
## drawn procedurally and fully animated:
##   - hearts beat (faster + redder when health is low), with 3-layer gradient
##     shading, a soft outer glow, a dark rim and a gloss glint
##   - the energy bar glows, has a beveled frame, a gradient fill with an
##     undulating surface, a sweeping shimmer, and an orb sigil that pulses and
##     fills with a little orbiting spark
## Binds to the player's PlayerStats.

@export var heart_size: float = 18.0
@export var heart_spacing: float = 21.0
@export var origin := Vector2(14.0, 14.0)

# Heart palette (gothic blood, dark -> bright for the gradient).
@export var heart_dark := Color(0.42, 0.07, 0.1)
@export var heart_mid := Color(0.7, 0.14, 0.18)
@export var heart_bright := Color(0.92, 0.28, 0.32)
@export var heart_rim := Color(0.05, 0.01, 0.02)
@export var heart_empty := Color(0.16, 0.07, 0.09)
@export var heart_glint := Color(1.0, 0.85, 0.85, 0.9)
@export var heart_glow := Color(0.8, 0.12, 0.18, 0.16)

# Shadow-energy palette (cold).
@export var energy_bright := Color(0.62, 0.95, 0.98)
@export var energy_mid := Color(0.3, 0.7, 0.82)
@export var energy_deep := Color(0.13, 0.42, 0.56)
@export var energy_bg := Color(0.06, 0.08, 0.13)
@export var energy_frame := Color(0.02, 0.03, 0.06)
@export var energy_sheen := Color(0.9, 1.0, 1.0, 0.7)
@export var energy_glow := Color(0.4, 0.85, 0.95, 0.16)

@export var dagger_steel := Color(0.72, 0.77, 0.84)
@export var dagger_handle := Color(0.4, 0.72, 0.86)
@export var dagger_used := Color(0.22, 0.24, 0.3)

var _cur_halves := 8
var _max_halves := 8
var _shadow := 50.0
var _shadow_max := 50.0
var _daggers := 3
var _dagger_max := 3
var _shards := 0
var _echoes := 0
var _time := 0.0
var _streak := 0
var _streak_t := 0.0       ## fades after 2s of no hits
var _streak_shatter := 0.0 ## broken-counter burst timer


func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var stats := player.get_node_or_null("Stats")
	if stats:
		stats.health_changed.connect(_on_health)
		stats.shadow_changed.connect(_on_shadow)
		stats.shards_changed.connect(_on_shards)
		_on_health(stats.health, stats.max_health)
		_on_shadow(stats.shadow, stats.max_shadow)
		_shards = stats.shards
	# Currency (Shards + Echoes) is owned by PlayerProgress — track it there so
	# it stays correct when spent in the Sanctum or dropped on death.
	PlayerProgress.currency_changed.connect(_on_currency)
	_shards = PlayerProgress.shards
	_echoes = PlayerProgress.echoes
	var combat := player.get_node_or_null("Combat")
	if combat and combat.has_signal("daggers_changed"):
		combat.daggers_changed.connect(_on_daggers)
		_dagger_max = combat.max_daggers
		_daggers = combat.get_dagger_count()
	# Flow state: the streak tally climbs; taking a hit shatters it.
	if combat and combat.has_signal("streak_changed"):
		combat.streak_changed.connect(func(n):
			_streak = n
			_streak_t = 2.0)
		combat.streak_broken.connect(func():
			_streak_shatter = 0.5
			_streak = 0)


func _on_daggers(count: int) -> void:
	_daggers = count


func _on_shards(total: int) -> void:
	_shards = total


func _on_currency(shards: int, echoes: int) -> void:
	_shards = shards
	_echoes = echoes


func _process(delta: float) -> void:
	_time += delta
	_streak_t = maxf(0.0, _streak_t - delta)
	_streak_shatter = maxf(0.0, _streak_shatter - delta)
	if _streak_t <= 0.0 and _streak > 0 and _streak < 5:
		_streak = 0   # small streaks fade quietly; flows of 5+ persist till broken
	queue_redraw()  # continuous, for the animation


func _on_health(current: int, maximum: int) -> void:
	_cur_halves = current
	_max_halves = maximum


func _on_shadow(current: float, maximum: float) -> void:
	_shadow = current
	_shadow_max = maximum


func _draw() -> void:
	var hearts := (_max_halves + 1) / 2   # round up: a half-max heart still gets a container
	var low := _cur_halves <= 2   # one heart or less left
	for i in hearts:
		var capacity := mini(2, _max_halves - i * 2)   # last container may hold only a half
		var halves := clampi(_cur_halves - i * 2, 0, capacity)
		# Only the last filled heart beats hard; low health makes all of them race.
		var is_last_filled := (halves > 0) and (_cur_halves - i * 2 <= 2)
		var beat := _heartbeat(low) if (is_last_filled or low) else 1.0
		_draw_heart(origin + Vector2(i * heart_spacing, 0.0), heart_size * beat, halves, low, capacity)
	_draw_energy_bar(origin.y + heart_size * 0.82 + 11.0, hearts)

	# Throwable-dagger pips, to the right of the hearts.
	var dx := origin.x + hearts * heart_spacing + 4.0
	for i in _dagger_max:
		_draw_dagger(Vector2(dx + i * 9.0, origin.y - 1.0), i < _daggers)

	# FLOW STATE tally: small strokes stack under the daggers; glows at 10+,
	# burns gold at 20+ (soul surge), shatters outward when you get hit.
	if _streak >= 2:
		var sx := dx
		var sy := origin.y + 16.0
		var col := Color(0.7, 0.74, 0.85, 0.8)
		if _streak >= 20:
			col = Color(1.0, 0.85, 0.45)
		elif _streak >= 10:
			col = Color(0.85, 0.9, 1.0)
		var pulse := 1.0 + (0.15 * sin(_time * 8.0) if _streak >= 10 else 0.0)
		for i in mini(_streak, 24):
			var h := 5.0 * pulse
			draw_line(Vector2(sx + i * 3.5, sy), Vector2(sx + i * 3.5 + 1.5, sy - h), col, 1.4)
		if _streak >= 10:
			draw_circle(Vector2(sx - 6, sy - 3), 2.0 * pulse, col)
	elif _streak_shatter > 0.0:
		# The broken tally bursts apart.
		var p := 1.0 - _streak_shatter / 0.5
		var sx := dx
		var sy := origin.y + 16.0
		for i in 8:
			var ang := TAU * i / 8.0
			var d := p * 14.0
			draw_line(Vector2(sx, sy - 3) + Vector2.from_angle(ang) * d,
				Vector2(sx, sy - 3) + Vector2.from_angle(ang) * (d + 3.0),
				Color(0.85, 0.4, 0.4, 1.0 - p), 1.4)

	# Shards (currency) — a small crystal + count, under the energy bar.
	var sd := Vector2(origin.x + 4.0, origin.y + heart_size * 0.82 + 26.0)
	draw_colored_polygon(PackedVector2Array([
		sd + Vector2(0, -5), sd + Vector2(4, -1), sd + Vector2(0, 5), sd + Vector2(-4, -1)]),
		Color(0.55, 0.85, 0.95))
	draw_colored_polygon(PackedVector2Array([
		sd + Vector2(0, -5), sd + Vector2(0, 5), sd + Vector2(-4, -1)]),
		Color(0.35, 0.62, 0.78))
	draw_string(ThemeDB.fallback_font, sd + Vector2(9, 4), "x%d" % _shards,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.78, 0.86, 0.95))

	# Echoes (soft currency, lost on death) — a faint violet wisp + count, below.
	var ed := sd + Vector2(0.0, 15.0)
	var flick := 0.7 + 0.3 * sin(_time * 4.0 + 1.0)
	draw_circle(ed, 4.2, Color(0.5, 0.42, 0.78, 0.25 * flick))
	draw_circle(ed, 2.6, Color(0.66, 0.56, 0.95, 0.9))
	draw_circle(ed + Vector2(-0.8, -0.8), 1.0, Color(0.85, 0.8, 1.0, flick))
	draw_string(ThemeDB.fallback_font, ed + Vector2(9, 4), "x%d" % _echoes,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.74, 0.7, 0.92))


# --- Hearts ---------------------------------------------------------------

## A lub-dub heartbeat curve in [~0.97, ~1.08], faster when low on health.
func _heartbeat(low: bool) -> float:
	var period := 0.62 if low else 1.05
	var p := fmod(_time, period) / period
	var lub := exp(-pow((p - 0.04) * 9.0, 2.0))
	var dub := 0.6 * exp(-pow((p - 0.2) * 10.0, 2.0))
	return 1.0 + clampf(lub + dub, 0.0, 1.0) * 0.1


func _draw_heart(c: Vector2, s: float, halves: int, low: bool, capacity: int = 2) -> void:
	var hc := capacity == 1   # half-capacity container: only the left lobe exists
	# Soft outer glow (stronger/red when low) + dark rim for depth.
	var glow := heart_glow
	if low and halves > 0:
		glow.a = 0.16 + 0.14 * (0.5 + 0.5 * sin(_time * 9.0))
	if halves > 0:
		_heart_shape(c + Vector2(0, s * 0.04), s * 1.4, glow, hc)
	_heart_shape(c + Vector2(0.0, s * 0.05), s * 1.16, heart_rim, hc)

	if halves == 0:
		_heart_shape(c, s, heart_empty, hc)
		return

	var left_only := hc or halves == 1
	if halves == 1 and not hc:
		_heart_shape(c, s, heart_empty)   # empty right side shows through
	# 3 stacked layers = bottom-dark -> top-bright gradient.
	_heart_fill(c, s, heart_dark, 1.0, 0.0, left_only)
	_heart_fill(c, s, heart_mid, 0.9, -0.06, left_only)
	_heart_fill(c, s, heart_bright, 0.66, -0.15, left_only)
	# Gloss glint (drifts a touch with the beat).
	var gx := -0.24 + 0.02 * sin(_time * 2.0)
	draw_circle(c + Vector2(s * gx, -s * 0.18), s * 0.1, heart_glint)


func _heart_fill(c: Vector2, s: float, col: Color, scl: float, oy: float, left_only: bool) -> void:
	var sc := s * scl
	var cc := c + Vector2(0.0, s * oy)
	draw_circle(cc + Vector2(-sc * 0.22, -sc * 0.08), sc * 0.27, col)
	if not left_only:
		draw_circle(cc + Vector2(sc * 0.22, -sc * 0.08), sc * 0.27, col)
	var rx := 0.0 if left_only else sc * 0.46
	draw_colored_polygon(PackedVector2Array([
		cc + Vector2(-sc * 0.46, 0.02 * sc),
		cc + Vector2(rx, 0.02 * sc),
		cc + Vector2(0.0, sc * 0.55)]), col)


func _heart_shape(c: Vector2, s: float, col: Color, left_only: bool = false) -> void:
	draw_circle(c + Vector2(-s * 0.22, -s * 0.08), s * 0.27, col)
	if not left_only:
		draw_circle(c + Vector2(s * 0.22, -s * 0.08), s * 0.27, col)
	var rx := 0.0 if left_only else s * 0.46
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-s * 0.46, 0.02 * s),
		c + Vector2(rx, 0.02 * s),
		c + Vector2(0.0, s * 0.55)]), col)


func _draw_dagger(c: Vector2, available: bool) -> void:
	var blade := dagger_steel if available else dagger_used
	var grip := dagger_handle if available else dagger_used
	draw_colored_polygon(PackedVector2Array([   # tip
		c + Vector2(-1.5, -6.0), c + Vector2(1.5, -6.0), c + Vector2(0.0, -9.0)]), blade)
	draw_rect(Rect2(c.x - 1.5, c.y - 6.0, 3.0, 9.0), blade)   # blade
	draw_rect(Rect2(c.x - 3.5, c.y + 3.0, 7.0, 1.6), blade)   # guard
	draw_rect(Rect2(c.x - 1.0, c.y + 4.6, 2.0, 3.2), grip)    # handle


# --- Shadow-energy bar ----------------------------------------------------

func _draw_energy_bar(y: float, hearts: int) -> void:
	var frac := clampf(_shadow / _shadow_max, 0.0, 1.0) if _shadow_max > 0.0 else 0.0
	var h := 8.0

	var bx := origin.x + 17.0
	var bw := maxf(64.0, hearts * heart_spacing - 20.0)
	var fw := bw * frac

	# Outer glow + beveled frame (light top, dark bottom) + inset track.
	draw_rect(Rect2(bx - 3.0, y - 3.0, bw + 6.0, h + 6.0), energy_glow)
	draw_rect(Rect2(bx - 1.0, y - 1.0, bw + 2.0, h + 2.0), energy_frame)
	draw_rect(Rect2(bx, y, bw, 1.0), Color(0.2, 0.26, 0.34))   # top bevel highlight
	draw_rect(Rect2(bx, y, bw, h), energy_bg)

	if fw > 1.0:
		# Gradient fill (deep -> mid -> bright bands).
		draw_rect(Rect2(bx, y, fw, h), energy_deep)
		draw_rect(Rect2(bx, y, fw, h * 0.62), energy_mid)
		# Undulating bright surface line (liquid energy).
		var steps := int(maxf(fw / 4.0, 2.0))
		for j in steps:
			var px := bx + fw * (float(j) / steps)
			var wy := y + 1.0 + sin(px * 0.5 + _time * 6.0) * 0.8
			draw_rect(Rect2(px, wy, fw / steps + 1.0, 2.2), energy_bright)
		# Sweeping shimmer highlight.
		var sweep := fmod(_time * 0.5, 1.6) - 0.3
		var shimmer_x := bx + fw * sweep
		for k in range(-3, 4):
			var a: float = energy_sheen.a * (1.0 - absf(k) / 4.0) * 0.5
			var col := Color(energy_sheen.r, energy_sheen.g, energy_sheen.b, a)
			var xx := shimmer_x + k * 1.5
			if xx >= bx and xx <= bx + fw:
				draw_rect(Rect2(xx, y, 1.5, h), col)

	_draw_energy_orb(Vector2(origin.x + 6.0, y + h * 0.5), frac)


func _draw_energy_orb(o: Vector2, frac: float) -> void:
	# Pulsing glow ring.
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	draw_circle(o, 8.0 + pulse * 1.5, Color(energy_glow.r, energy_glow.g, energy_glow.b, 0.2 + 0.15 * pulse))
	draw_circle(o, 6.2, energy_frame)
	draw_circle(o, 5.2, energy_deep)
	draw_circle(o, 5.2 * frac, energy_mid)            # orb fills with the meter
	draw_circle(o, maxf(5.2 * frac - 1.4, 0.0), energy_bright)
	draw_circle(o + Vector2(-1.6, -1.6), 1.4, energy_sheen)   # static sheen
	# Orbiting spark.
	var ang := _time * 2.4
	draw_circle(o + Vector2(cos(ang), sin(ang)) * 4.2, 1.0, energy_sheen)
