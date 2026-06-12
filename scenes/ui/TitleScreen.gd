extends Control
## Cairn — the main menu. Boots first. Three screens in one Control, all drawn
## procedurally over the animated buried-city backdrop:
##   MAIN     — NEW GAME / CONTINUE / SETTINGS / QUIT, under the carved logo.
##   SLOTS    — the 3 save slots (NEW GAME confirms before overwriting a used
##              slot; CONTINUE only enters used ones).
##   SETTINGS — master/music/sfx volume sliders + fullscreen toggle, persisted
##              by AudioManager to user://settings.json.
## A single distant ambient track plays; dust and embers drift past the logo.

const FONT := preload("res://assets/fonts/silkscreen.ttf")
const AREA_SCENE := "res://scenes/world/area_01_hollowed_gate/Area1.tscn"
const HUB_SCENE := "res://scenes/world/sanctum/Sanctum.tscn"

enum Screen { MAIN, SLOTS, SETTINGS }

const MAIN_ITEMS := ["NEW GAME", "CONTINUE", "SETTINGS", "QUIT"]
const SETTING_ITEMS := ["MASTER", "MUSIC", "SFX", "FULLSCREEN", "BACK"]

var _screen := Screen.MAIN
var _sel := 0
var _slots_for_new := false   ## SLOTS opened via NEW GAME (true) or CONTINUE
var _time := 0.0
var _confirm_overwrite := -1
var _confirm_delete := -1
var _entering := false


func _ready() -> void:
	PlayerProgress.reset()
	AudioManager.play_music("menu")


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	if _entering:
		return
	match _screen:
		Screen.MAIN:
			_input_main(event)
		Screen.SLOTS:
			_input_slots(event)
		Screen.SETTINGS:
			_input_settings(event)


func _nav(event: InputEvent, count: int) -> bool:
	if event.is_action_pressed("move_up"):
		_sel = wrapi(_sel - 1, 0, count)
		AudioManager.ui("menu_click", -14.0)
		get_viewport().set_input_as_handled()
		return true
	if event.is_action_pressed("move_down"):
		_sel = wrapi(_sel + 1, 0, count)
		AudioManager.ui("menu_click", -14.0)
		get_viewport().set_input_as_handled()
		return true
	return false


func _confirmed(event: InputEvent) -> bool:
	return event.is_action_pressed("attack") or event.is_action_pressed("jump") \
		or event.is_action_pressed("interact")


func _input_main(event: InputEvent) -> void:
	if _nav(event, MAIN_ITEMS.size()):
		return
	if not _confirmed(event):
		return
	get_viewport().set_input_as_handled()
	AudioManager.ui("menu_select", -10.0)
	match _sel:
		0:
			_slots_for_new = true
			_screen = Screen.SLOTS
			_sel = 0
			_confirm_overwrite = -1
		1:
			_slots_for_new = false
			_screen = Screen.SLOTS
			_sel = 0
		2:
			_screen = Screen.SETTINGS
			_sel = 0
		3:
			get_tree().quit()


func _input_slots(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("dash"):
		_screen = Screen.MAIN
		_sel = 0
		get_viewport().set_input_as_handled()
		return
	if _nav(event, SaveManager.SLOTS):
		_confirm_overwrite = -1
		_confirm_delete = -1
		return
	if event.is_action_pressed("crouch"):
		get_viewport().set_input_as_handled()
		_delete_slot(_sel)
		return
	if not _confirmed(event):
		return
	get_viewport().set_input_as_handled()
	var used := SaveManager.has_slot(_sel)
	if _slots_for_new:
		# Starting over on a used slot needs a second press.
		if used and _confirm_overwrite != _sel:
			_confirm_overwrite = _sel
			return
		_entering = true
		PlayerProgress.reset()
		GameManager.has_checkpoint = false
		GameManager.run_time = 0.0
		SaveManager.start_session(_sel)
		SaveManager.save_slot(_sel)
		SceneFlow.travel(AREA_SCENE, "down")
	else:
		if not used:
			return   # nothing to continue
		_entering = true
		SaveManager.load_slot(_sel)   # arms the session too
		GameManager.has_checkpoint = false
		GameManager.run_time = 0.0
		SceneFlow.travel(HUB_SCENE, "down")


func _delete_slot(slot: int) -> void:
	if not SaveManager.has_slot(slot):
		return
	if _confirm_delete != slot:
		_confirm_delete = slot
		return
	SaveManager.delete_slot(slot)
	_confirm_delete = -1


func _input_settings(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("dash"):
		_screen = Screen.MAIN
		_sel = 0
		get_viewport().set_input_as_handled()
		return
	if _nav(event, SETTING_ITEMS.size()):
		return
	var step := 0.0
	if event.is_action_pressed("move_left"):
		step = -0.1
	elif event.is_action_pressed("move_right"):
		step = 0.1
	if step != 0.0 and _sel <= 2:
		var key: String = ["master", "music", "sfx"][_sel]
		AudioManager.set_volume(key, AudioManager.get_volume(key) + step)
		AudioManager.play("step_stone", -16.0)
		get_viewport().set_input_as_handled()
		return
	if (step != 0.0 or _confirmed(event)) and _sel == 3:
		AudioManager.set_fullscreen(not AudioManager.fullscreen)
		get_viewport().set_input_as_handled()
		return
	if _confirmed(event) and _sel == 4:
		_screen = Screen.MAIN
		_sel = 0
		get_viewport().set_input_as_handled()


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	_draw_sky()
	_draw_skyline()
	_draw_fog()
	_draw_embers()
	_draw_fireflies()
	_draw_cairn_logo()
	_draw_title()
	match _screen:
		Screen.MAIN:
			_draw_main()
		Screen.SLOTS:
			_draw_slots()
		Screen.SETTINGS:
			_draw_settings()
	_draw_vignette()


func _draw_sky() -> void:
	var h := size.y
	var bands := 24
	for i in range(bands):
		var f := float(i) / bands
		var col := Color(0.04, 0.04, 0.09).lerp(Color(0.10, 0.07, 0.14), f)
		draw_rect(Rect2(0, h * f, size.x, h / bands + 1.0), col)


func _draw_skyline() -> void:
	var base_y := size.y * 0.78
	_skyline_band(base_y + 26.0, 64.0, 120.0, Color(0.06, 0.06, 0.11), 0.0, 0.9)
	_skyline_band(base_y, 96.0, 150.0, Color(0.08, 0.08, 0.14), 700.0, 1.0)


func _skyline_band(y: float, min_h: float, max_h: float, col: Color, seed_off: float, light: float) -> void:
	var x := -20.0
	while x < size.x + 20.0:
		var s := sin((x + seed_off) * 0.07) * 0.5 + 0.5
		var bw := 42.0 + s * 46.0
		var bh := min_h + s * (max_h - min_h)
		draw_rect(Rect2(x, y - bh, bw - 6.0, bh), col)
		draw_rect(Rect2(x, y - bh - 4.0, (bw - 6.0) * 0.5, 4.0), col)
		var rng := int(x) * 13 + int(seed_off)
		for wy in range(3):
			for wx in range(3):
				if (rng + wx * 7 + wy * 5) % 4 == 0:
					var flick := 0.5 + 0.5 * sin(_time * 1.5 + rng + wx + wy)
					var lx := x + 8.0 + wx * 12.0
					var ly := y - bh + 12.0 + wy * 16.0
					if lx < x + bw - 12.0 and ly < y - 6.0:
						draw_rect(Rect2(lx, ly, 3.0, 4.0), Color(1.0, 0.72, 0.4, (0.25 + 0.35 * flick) * light))
		x += bw + 6.0
	draw_rect(Rect2(0, y, size.x, size.y - y), Color(0.03, 0.03, 0.06))


func _draw_fog() -> void:
	for b in range(3):
		var y := size.y * (0.62 + b * 0.1)
		var drift := fmod(_time * (6.0 + b * 4.0), size.x)
		var col := Color(0.3, 0.32, 0.46, 0.05 + b * 0.015)
		for k in range(-1, 8):
			var cxp := fmod(k * 150.0 + drift, size.x + 300.0) - 150.0
			draw_circle(Vector2(cxp, y + sin(_time * 0.5 + k) * 6.0), 90.0 - b * 14.0, col)


func _draw_embers() -> void:
	for i in range(46):
		var sx := fmod(i * 167.0, size.x)
		var rise := fmod(_time * (10.0 + (i % 5) * 4.0) + i * 30.0, size.y + 40.0)
		var y := size.y + 20.0 - rise
		var x := sx + sin(_time * 0.7 + i) * 14.0
		var tw := 0.4 + 0.6 * (0.5 + 0.5 * sin(_time * 3.0 + i))
		var warm := i % 4 == 0
		var col := Color(1.0, 0.7, 0.4, 0.5 * tw) if warm else Color(0.6, 0.7, 0.95, 0.4 * tw)
		draw_circle(Vector2(x, y), 1.0 + (1.0 if warm else 0.0) * tw, col)


func _draw_fireflies() -> void:
	for i in range(14):
		var bx := fmod(i * 311.0, size.x)
		var by := size.y * 0.42 + fmod(i * 91.0, size.y * 0.4)
		var p := Vector2(bx + cos(_time * 0.6 + i) * 24.0, by + sin(_time * 0.8 + i * 1.3) * 16.0)
		var glow := 0.4 + 0.6 * (0.5 + 0.5 * sin(_time * 2.5 + i))
		draw_circle(p, 4.0, Color(0.5, 0.7, 1.0, 0.08 * glow))
		draw_circle(p, 1.4, Color(0.75, 0.85, 1.0, 0.8 * glow))


func _draw_cairn_logo() -> void:
	var cx := size.x * 0.5
	var top := 40.0
	var glow := 0.55 + 0.25 * sin(_time * 1.4)
	draw_circle(Vector2(cx, top + 4.0), 26.0, Color(0.4, 0.5, 0.85, 0.10 * glow))
	var stones := [
		[Vector2(cx, top + 30.0), 18.0, 9.0],
		[Vector2(cx + 1.0, top + 18.0), 14.0, 8.0],
		[Vector2(cx - 1.0, top + 8.0), 10.0, 6.0],
		[Vector2(cx, top + 1.0), 6.0, 4.0],
	]
	for s in stones:
		var c: Vector2 = s[0]
		var rw: float = s[1]
		var rh: float = s[2]
		draw_colored_polygon(_oval(c, rw, rh, 14), Color(0.16, 0.16, 0.22))
		draw_colored_polygon(_oval(c + Vector2(0, -rh * 0.4), rw * 0.85, rh * 0.4, 14), Color(0.22, 0.22, 0.3))
	draw_circle(Vector2(cx, top + 1.0), 2.2 + glow, Color(0.7, 0.82, 1.0, 0.9))
	# Dust motes drifting through the logo light.
	for i in range(8):
		var a := _time * 0.35 + i * 0.785
		var p := Vector2(cx + cos(a) * (30.0 + i * 7.0), top + 40.0 + sin(a * 1.4 + i) * 22.0)
		draw_circle(p, 0.9, Color(0.8, 0.82, 1.0, 0.18 + 0.1 * sin(_time * 2.0 + i)))


func _oval(c: Vector2, rw: float, rh: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(seg):
		var a := TAU * i / seg
		pts.append(c + Vector2(cos(a) * rw, sin(a) * rh))
	return pts


## The wordmark, cut into stone: deep inset shadow below-right, chisel light
## above-left, and a hairline crack across the N.
func _draw_title() -> void:
	var bob := sin(_time * 1.2) * 2.0
	var y := 128.0 + bob
	var glow := 0.5 + 0.5 * sin(_time * 1.6)
	for r in range(4, 0, -1):
		var a := 0.05 * glow * r
		draw_string(FONT, Vector2(0, y + 1.0), "CAIRN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 56 + r, Color(0.5, 0.6, 1.0, a))
	# Carved: dark inset (down-right), cold chisel highlight (up-left), face.
	draw_string(FONT, Vector2(2, y + 3.0), "CAIRN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 56, Color(0.02, 0.02, 0.05))
	draw_string(FONT, Vector2(-1, y - 1.0), "CAIRN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 56, Color(0.55, 0.6, 0.78, 0.55))
	draw_string(FONT, Vector2(0, y), "CAIRN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 56, Color(0.78, 0.8, 0.9))
	draw_string(FONT, Vector2(0, y + 28.0), "DESCEND INTO THE HOLLOW", HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color(0.5, 0.55, 0.72, 0.7 + 0.3 * glow))


func _draw_main() -> void:
	var y0 := 250.0
	for i in MAIN_ITEMS.size():
		var iy := y0 + i * 44.0
		var selected := i == _sel
		var label: String = MAIN_ITEMS[i]
		var dim := label == "CONTINUE" and not _any_slot_used()
		var col := Color(0.45, 0.48, 0.6)
		if dim:
			col = Color(0.28, 0.3, 0.38)
		if selected:
			col = Color(0.92, 0.93, 1.0)
			var caret := size.x * 0.5 - 110.0 + sin(_time * 6.0) * 2.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(caret, iy - 11), Vector2(caret + 8, iy - 6), Vector2(caret, iy - 1)]),
				Color(0.8, 0.78, 1.0))
		draw_string(FONT, Vector2(1, iy + 1), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color(0.03, 0.03, 0.06, 0.8))
		draw_string(FONT, Vector2(0, iy), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, col)
	var hint_a := 0.55 + 0.25 * sin(_time * 2.0)
	draw_string(FONT, Vector2(0, size.y - 30.0), "↑ ↓  select      J / Space  confirm", HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0.5, 0.53, 0.64, hint_a))


func _any_slot_used() -> bool:
	for i in SaveManager.SLOTS:
		if SaveManager.has_slot(i):
			return true
	return false


func _draw_slots() -> void:
	var rw := 420.0
	var rh := 56.0
	var x0 := size.x * 0.5 - rw * 0.5
	var y0 := 226.0
	draw_string(FONT, Vector2(0, y0 - 16.0), "NEW GAME — choose a slot" if _slots_for_new else "CONTINUE — choose a slot",
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color(0.6, 0.64, 0.8))
	for i in range(SaveManager.SLOTS):
		var ry := y0 + i * (rh + 14.0)
		var rect := Rect2(x0, ry, rw, rh)
		var selected := i == _sel
		draw_rect(rect, Color(0.08, 0.08, 0.13, 0.85) if not selected else Color(0.15, 0.14, 0.22, 0.92))
		var border := Color(0.32, 0.34, 0.44) if not selected else Color(0.7, 0.66, 1.0)
		draw_rect(rect, border, false, 2.0 if selected else 1.0)
		if selected:
			var glow := 0.5 + 0.5 * sin(_time * 5.0)
			draw_rect(rect.grow(3.0), Color(0.6, 0.55, 1.0, 0.12 + 0.12 * glow), false, 2.0)
			var caret := x0 - 18.0 + sin(_time * 6.0) * 2.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(caret, ry + rh * 0.5 - 5.0), Vector2(caret + 8.0, ry + rh * 0.5), Vector2(caret, ry + rh * 0.5 + 5.0)]),
				Color(0.8, 0.78, 1.0))

		var s := SaveManager.slot_summary(i)
		draw_string(FONT, Vector2(x0 + 16.0, ry + 24.0), "SLOT %d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, rw, 14, Color(0.85, 0.88, 0.98))
		if s.is_empty():
			draw_string(FONT, Vector2(x0 + 16.0, ry + 44.0), "— empty —", HORIZONTAL_ALIGNMENT_LEFT, rw - 32.0, 10, Color(0.55, 0.58, 0.7))
		else:
			var info := "Shards %d   ·   %d skills   ·   %s" % [s.get("shards", 0), s.get("nodes", 0), str(s.get("area", "?")).capitalize()]
			draw_string(FONT, Vector2(x0 + 16.0, ry + 44.0), info, HORIZONTAL_ALIGNMENT_LEFT, rw - 32.0, 10, Color(0.6, 0.78, 0.72))
			if _confirm_overwrite == i:
				draw_string(FONT, Vector2(x0 + rw - 190.0, ry + 24.0), "overwrite? press again", HORIZONTAL_ALIGNMENT_LEFT, 190.0, 9, Color(0.95, 0.7, 0.4))
			if _confirm_delete == i:
				draw_string(FONT, Vector2(x0 + rw - 150.0, ry + 44.0), "delete? Ctrl again", HORIZONTAL_ALIGNMENT_LEFT, 150.0, 9, Color(0.88, 0.45, 0.45))

	var hint_a := 0.55 + 0.25 * sin(_time * 2.0)
	draw_string(FONT, Vector2(0, size.y - 30.0), "↑ ↓  select      J / Space  confirm      Ctrl  delete      Esc  back",
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0.5, 0.53, 0.64, hint_a))


func _draw_settings() -> void:
	var y0 := 240.0
	var rw := 360.0
	var x0 := size.x * 0.5 - rw * 0.5
	draw_string(FONT, Vector2(0, y0 - 18.0), "SETTINGS", HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color(0.7, 0.74, 0.9))
	for i in SETTING_ITEMS.size():
		var iy := y0 + i * 40.0
		var selected := i == _sel
		var col := Color(0.92, 0.93, 1.0) if selected else Color(0.5, 0.53, 0.66)
		if selected:
			var caret := x0 - 22.0 + sin(_time * 6.0) * 2.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(caret, iy - 9), Vector2(caret + 8, iy - 4), Vector2(caret, iy + 1)]),
				Color(0.8, 0.78, 1.0))
		draw_string(FONT, Vector2(x0, iy), SETTING_ITEMS[i], HORIZONTAL_ALIGNMENT_LEFT, rw, 14, col)
		if i <= 2:
			var key: String = ["master", "music", "sfx"][i]
			var v := AudioManager.get_volume(key)
			var bar := Rect2(x0 + 130.0, iy - 12.0, 200.0, 10.0)
			draw_rect(bar, Color(0.1, 0.11, 0.17))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * v, bar.size.y)), Color(0.5, 0.62, 0.85, 0.9 if selected else 0.6))
			draw_rect(bar, Color(0.32, 0.35, 0.46), false, 1.0)
			# Notches.
			for n in range(1, 10):
				var nx := bar.position.x + bar.size.x * n / 10.0
				draw_line(Vector2(nx, bar.position.y), Vector2(nx, bar.end.y), Color(0.05, 0.05, 0.09, 0.5), 1.0)
		elif i == 3:
			var state := "ON" if AudioManager.fullscreen else "OFF"
			draw_string(FONT, Vector2(x0 + 130.0, iy), "< %s >" % state, HORIZONTAL_ALIGNMENT_LEFT, 200.0, 14, col)
	var hint_a := 0.55 + 0.25 * sin(_time * 2.0)
	draw_string(FONT, Vector2(0, size.y - 30.0), "← →  adjust      J / Space  toggle      Esc  back",
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0.5, 0.53, 0.64, hint_a))


func _draw_vignette() -> void:
	var steps := 14
	for i in range(steps):
		var a := 0.5 * pow(1.0 - float(i) / steps, 2.0)
		var col := Color(0.0, 0.0, 0.02, a * 0.18)
		var inset := i * 4.0
		draw_rect(Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0), col, false, 4.0)
