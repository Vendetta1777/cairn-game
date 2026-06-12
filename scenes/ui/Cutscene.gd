extends CanvasLayer
## Cairn — the CUTSCENE PLAYER: full-screen pixel-art story panels with a
## typewriter caption, dark-souls-item-description energy. Each panel is drawn
## procedurally (a painter keyed by name) so cutscenes are pure data:
##   play([{ "art": "kingdom", "text": "..." , "hold": 12.0 }, ...])
## E advances a panel; holding E skips the whole scene. Pauses the game.
## Emits `finished` when done.

signal finished

const FONT := preload("res://assets/fonts/silkscreen.ttf")

var _panels: Array = []
var _idx := -1
var _t := 0.0          ## time in current panel
var _chars := 0.0      ## typewriter progress
var _hold_skip := 0.0
var _active := false
var _fade := 0.0       ## panel fade-in

@onready var _canvas: Control = $Canvas


func _ready() -> void:
	add_to_group("cutscene")
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_canvas.draw.connect(_paint)


func play(panels: Array) -> void:
	if _active or panels.is_empty():
		return
	_panels = panels
	_idx = 0
	_t = 0.0
	_chars = 0.0
	_fade = 0.0
	_active = true
	visible = true
	get_tree().paused = true
	GameManager.letterbox(true)
	AudioManager.duck(-6.0, 1.0)


func _finish() -> void:
	_active = false
	visible = false
	get_tree().paused = false
	GameManager.letterbox(false)
	finished.emit()


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	_fade = minf(1.0, _fade + delta * 1.4)
	_chars += delta * 26.0
	# Hold E to skip everything.
	if Input.is_action_pressed("interact"):
		_hold_skip += delta
		if _hold_skip > 1.1:
			_finish()
			return
	else:
		_hold_skip = 0.0
	if Input.is_action_just_pressed("interact"):
		var p: Dictionary = _panels[_idx]
		if _chars < str(p.get("text", "")).length():
			_chars = 9999.0   # first press: reveal all text
		else:
			_advance()
	elif _t > float(_panels[_idx].get("hold", 12.0)):
		_advance()
	_canvas.queue_redraw()


func _advance() -> void:
	_idx += 1
	if _idx >= _panels.size():
		_finish()
		return
	_t = 0.0
	_chars = 0.0
	_fade = 0.0


func _paint() -> void:
	if not _active or _idx >= _panels.size():
		return
	var s := _canvas.size
	_canvas.draw_rect(Rect2(0, 0, s.x, s.y), Color(0.01, 0.01, 0.018))
	var p: Dictionary = _panels[_idx]
	# The panel art region: a wide letterboxed frame.
	var art := Rect2(s.x * 0.5 - 330, 60, 660, 300)
	_canvas.draw_rect(art.grow(3), Color(0.16, 0.155, 0.19))
	var prev_a := _fade
	_paint_art(str(p.get("art", "dark")), art, prev_a)
	# Caption with typewriter.
	var text := str(p.get("text", ""))
	var shown := text.substr(0, int(_chars))
	_canvas.draw_string(FONT, Vector2(s.x * 0.5 - 320, art.end.y + 50), shown,
		HORIZONTAL_ALIGNMENT_CENTER, 640, 12, Color(0.78, 0.78, 0.85, prev_a))
	_canvas.draw_string(FONT, Vector2(0, s.y - 22),
		"E  next      hold E  skip", HORIZONTAL_ALIGNMENT_CENTER, s.x, 9, Color(0.35, 0.36, 0.45))
	# Panel dots.
	for i in _panels.size():
		var c := Color(0.7, 0.7, 0.85) if i == _idx else Color(0.25, 0.25, 0.33)
		_canvas.draw_circle(Vector2(s.x * 0.5 + (i - _panels.size() * 0.5) * 14.0 + 7.0, s.y - 44), 2.0, c)


# --- the painters: each draws one pixel-art tableau into `r` -------------------

func _paint_art(key: String, r: Rect2, a: float) -> void:
	match key:
		"kingdom": _art_kingdom(r, a)
		"sinking": _art_sinking(r, a)
		"king": _art_king(r, a)
		"sealing": _art_sealing(r, a)
		"hollow": _art_hollow(r, a)
		"crown": _art_crown(r, a)
		"collapse": _art_collapse(r, a)
		"warden": _art_warden(r, a)
		"surface": _art_surface(r, a)
		_: _canvas.draw_rect(r, Color(0.03, 0.03, 0.05, a))


func _sky(r: Rect2, top: Color, bottom: Color, a: float) -> void:
	for i in 12:
		var f := i / 12.0
		var c := top.lerp(bottom, f)
		c.a = a
		_canvas.draw_rect(Rect2(r.position.x, r.position.y + r.size.y * f, r.size.x, r.size.y / 12.0 + 1), c)


func _art_kingdom(r: Rect2, a: float) -> void:
	# The kingdom in its glory: towers under a golden cavern roof.
	_sky(r, Color(0.16, 0.12, 0.06), Color(0.32, 0.22, 0.1), a)
	var base := r.end.y - 40
	for i in 9:
		var x := r.position.x + 40 + i * 65.0
		var h := 60.0 + sin(i * 2.0) * 35.0 + (50 if i == 4 else 0)
		var col := Color(0.1, 0.08, 0.06, a)
		_canvas.draw_rect(Rect2(x, base - h, 36, h + 40), col)
		_canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(x - 4, base - h), Vector2(x + 18, base - h - 22), Vector2(x + 40, base - h)]), col)
		for w in 3:
			_canvas.draw_rect(Rect2(x + 8 + w * 9, base - h + 14, 4, 6), Color(1.0, 0.75, 0.4, 0.8 * a))
	_canvas.draw_rect(Rect2(r.position.x, base + 26, r.size.x, 14), Color(0.06, 0.05, 0.04, a))


func _art_sinking(r: Rect2, a: float) -> void:
	# The sinking: the same towers, tilted, water rising, lights dying.
	_sky(r, Color(0.04, 0.05, 0.09), Color(0.08, 0.12, 0.16), a)
	var base := r.end.y - 60
	for i in 8:
		var x := r.position.x + 50 + i * 70.0
		var h := 50.0 + sin(i * 2.0) * 30.0
		var tilt := sin(i * 1.7) * 10.0
		var col := Color(0.07, 0.07, 0.1, a)
		_canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(x, base), Vector2(x + tilt, base - h), Vector2(x + 30 + tilt, base - h - 6),
			Vector2(x + 34, base)]), col)
		if i % 3 == 0:
			_canvas.draw_rect(Rect2(x + 12 + tilt, base - h + 12, 4, 5), Color(1.0, 0.6, 0.3, 0.35 * a))
	# Black water with a pale sheen.
	_canvas.draw_rect(Rect2(r.position.x, base + 10, r.size.x, r.end.y - base - 10), Color(0.02, 0.05, 0.07, a))
	for k in 14:
		var wx := r.position.x + k * r.size.x / 14.0
		_canvas.draw_line(Vector2(wx, base + 12 + sin(k * 2.0) * 2.0), Vector2(wx + 18, base + 12 + sin(k * 2.0 + 1.0) * 2.0),
			Color(0.3, 0.5, 0.55, 0.4 * a), 1.0)


func _art_king(r: Rect2, a: float) -> void:
	# The king on the throne, crown of stone, hall in candlelight.
	_sky(r, Color(0.05, 0.03, 0.07), Color(0.1, 0.07, 0.1), a)
	var cx := r.position.x + r.size.x * 0.5
	var base := r.end.y - 36
	for px in [-180.0, -120.0, 120.0, 180.0]:
		_canvas.draw_rect(Rect2(cx + px - 9, r.position.y + 30, 18, base - r.position.y - 30), Color(0.09, 0.07, 0.1, a))
	_canvas.draw_rect(Rect2(cx - 56, base - 120, 112, 120), Color(0.12, 0.1, 0.13, a))
	_canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 56, base - 120), Vector2(cx, base - 150), Vector2(cx + 56, base - 120)]), Color(0.12, 0.1, 0.13, a))
	# The seated figure.
	var king := Color(0.2, 0.17, 0.2, a)
	_canvas.draw_rect(Rect2(cx - 20, base - 84, 40, 50), king)
	_canvas.draw_circle(Vector2(cx, base - 94), 12.0, king)
	for spike in [-8.0, 0.0, 8.0]:
		_canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(cx + spike - 3, base - 104), Vector2(cx + spike, base - 114), Vector2(cx + spike + 3, base - 104)]),
			Color(0.75, 0.62, 0.3, a))
	for tx in [-150.0, 150.0]:
		_canvas.draw_circle(Vector2(cx + tx, base - 60), 8.0, Color(1.0, 0.65, 0.3, 0.25 * a))
		_canvas.draw_rect(Rect2(cx + tx - 1.5, base - 60, 3, 24), Color(0.15, 0.12, 0.1, a))


func _art_sealing(r: Rect2, a: float) -> void:
	# Hands of the court sealing the deep — a great slab lowered over a stairway.
	_sky(r, Color(0.06, 0.06, 0.1), Color(0.03, 0.03, 0.05), a)
	var cx := r.position.x + r.size.x * 0.5
	var base := r.end.y - 40
	for i in 6:
		_canvas.draw_rect(Rect2(cx - 90 + i * 14, base - i * 12, 180 - i * 28, 12), Color(0.1, 0.09, 0.12, a))
	_canvas.draw_rect(Rect2(cx - 70, r.position.y + 50, 140, 34), Color(0.16, 0.15, 0.18, a))
	_canvas.draw_circle(Vector2(cx, r.position.y + 67), 9.0, Color(0.5, 0.65, 0.9, 0.4 * a))
	for sx in [-110.0, 110.0]:
		var fig := Color(0.08, 0.08, 0.11, a)
		_canvas.draw_rect(Rect2(cx + sx - 8, base - 64, 16, 40), fig)
		_canvas.draw_circle(Vector2(cx + sx, base - 70), 7.0, fig)


func _art_hollow(r: Rect2, a: float) -> void:
	# Centuries later: the hollow dark, one red wanderer with a blade.
	_sky(r, Color(0.02, 0.02, 0.04), Color(0.05, 0.06, 0.09), a)
	var base := r.end.y - 50
	for i in 5:
		var x := r.position.x + 60 + i * 110.0
		_canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(x, r.position.y + 20), Vector2(x + 16, r.position.y + 20), Vector2(x + 8, r.position.y + 90)]),
			Color(0.06, 0.06, 0.09, a))
	_canvas.draw_rect(Rect2(r.position.x, base, r.size.x, 40), Color(0.05, 0.05, 0.07, a))
	var cx := r.position.x + r.size.x * 0.42
	_canvas.draw_rect(Rect2(cx - 6, base - 26, 12, 26), Color(0.6, 0.12, 0.14, a))
	_canvas.draw_circle(Vector2(cx, base - 30), 6.0, Color(0.6, 0.12, 0.14, a))
	_canvas.draw_line(Vector2(cx + 7, base - 16), Vector2(cx + 20, base - 24), Color(0.7, 0.74, 0.85, a), 1.5)
	_canvas.draw_circle(Vector2(cx, base - 24), 22.0, Color(0.5, 0.7, 0.9, 0.06 * a))


func _art_crown(r: Rect2, a: float) -> void:
	# The crown alone in the dark, on the broken arena floor.
	_sky(r, Color(0.03, 0.02, 0.04), Color(0.06, 0.04, 0.07), a)
	var cx := r.position.x + r.size.x * 0.5
	var base := r.end.y - 70
	_canvas.draw_rect(Rect2(r.position.x + 60, base + 8, r.size.x - 120, 10), Color(0.08, 0.07, 0.09, a))
	var gold := Color(0.78, 0.64, 0.3, a)
	_canvas.draw_rect(Rect2(cx - 26, base - 14, 52, 16), gold)
	for k in 4:
		_canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 24 + k * 16, base - 14), Vector2(cx - 18 + k * 16, base - 30), Vector2(cx - 12 + k * 16, base - 14)]), gold)
	_canvas.draw_circle(Vector2(cx, base - 6), 40.0, Color(1.0, 0.8, 0.4, 0.05 * a))


func _art_collapse(r: Rect2, a: float) -> void:
	# Ending A: the cairn falls — rubble, dust shafts, a small figure running.
	_sky(r, Color(0.08, 0.06, 0.05), Color(0.13, 0.1, 0.08), a)
	for i in 14:
		var x := r.position.x + (i * 97.0) - 20.0
		var sz := 10.0 + (i % 5) * 8.0
		_canvas.draw_rect(Rect2(fmod(x, r.size.x) + r.position.x * 0.0, r.position.y + 30 + (i % 7) * 30.0, sz, sz), Color(0.1, 0.08, 0.07, a))
	var base := r.end.y - 44
	_canvas.draw_rect(Rect2(r.position.x, base, r.size.x, 44), Color(0.07, 0.05, 0.04, a))
	var cx := r.position.x + r.size.x * 0.7
	_canvas.draw_rect(Rect2(cx - 5, base - 22, 10, 22), Color(0.6, 0.12, 0.14, a))
	_canvas.draw_circle(Vector2(cx, base - 26), 5.0, Color(0.6, 0.12, 0.14, a))


func _art_warden(r: Rect2, a: float) -> void:
	# Ending B: the new warden seated, cyan eyes in the dark.
	_sky(r, Color(0.02, 0.02, 0.045), Color(0.05, 0.04, 0.08), a)
	var cx := r.position.x + r.size.x * 0.5
	var base := r.end.y - 60
	_canvas.draw_rect(Rect2(cx - 46, base - 100, 92, 100), Color(0.08, 0.07, 0.1, a))
	_canvas.draw_rect(Rect2(cx - 16, base - 70, 32, 44), Color(0.32, 0.08, 0.1, a))
	_canvas.draw_circle(Vector2(cx, base - 78), 10.0, Color(0.32, 0.08, 0.1, a))
	for ex in [-4.0, 4.0]:
		_canvas.draw_circle(Vector2(cx + ex, base - 79), 1.6, Color(0.5, 0.95, 1.0, a))
	_canvas.draw_circle(Vector2(cx, base - 60), 50.0, Color(0.3, 0.7, 0.9, 0.04 * a))


func _art_surface(r: Rect2, a: float) -> void:
	# Ending A epilogue: grey daylight, the first sky in the whole game.
	_sky(r, Color(0.5, 0.52, 0.58), Color(0.3, 0.32, 0.38), a)
	var base := r.end.y - 56
	_canvas.draw_rect(Rect2(r.position.x, base, r.size.x, 56), Color(0.16, 0.17, 0.15, a))
	var cx := r.position.x + r.size.x * 0.35
	_canvas.draw_rect(Rect2(cx - 5, base - 22, 10, 22), Color(0.35, 0.08, 0.1, a))
	_canvas.draw_circle(Vector2(cx, base - 26), 5.0, Color(0.35, 0.08, 0.1, a))
	_canvas.draw_circle(Vector2(r.position.x + r.size.x * 0.8, r.position.y + 60), 26.0, Color(0.85, 0.85, 0.8, 0.35 * a))
