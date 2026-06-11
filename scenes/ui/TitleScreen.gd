extends Control
## Cairn — title screen + save-slot select (GDD Section 15: 3 slots). Boots first.
## An empty slot starts a New Game (resets PlayerProgress, drops you into Area 1);
## a used slot Continues (loads it, drops you into the Sanctum hub to regroup).
## Up/Down pick a slot, attack/jump/interact confirm, crouch deletes.
##
## Fully procedural, animated backdrop: a buried-city skyline with flickering
## remnant lights, drifting fog, rising embers and fireflies, a glowing cairn
## (balanced stones) logo, a breathing title, and a vignette — no art needed.

const FONT := preload("res://assets/fonts/silkscreen.ttf")
const AREA_SCENE := "res://scenes/world/area_01_hollowed_gate/Area1.tscn"
const HUB_SCENE := "res://scenes/world/sanctum/Sanctum.tscn"

var _sel := 0
var _time := 0.0
var _confirm_delete := -1
var _entering := false       ## guards against double-trigger during scene change


func _ready() -> void:
	# Fresh progression until a slot is chosen.
	PlayerProgress.reset()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	if _entering:
		return
	if event.is_action_pressed("move_up"):
		_sel = wrapi(_sel - 1, 0, SaveManager.SLOTS); _confirm_delete = -1
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_sel = wrapi(_sel + 1, 0, SaveManager.SLOTS); _confirm_delete = -1
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack") or event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		# Mark handled and flip the guard BEFORE we change scenes — once the
		# scene swaps, this node is freed and get_viewport() would be null.
		get_viewport().set_input_as_handled()
		_entering = true
		_enter_slot(_sel)
	elif event.is_action_pressed("crouch"):
		get_viewport().set_input_as_handled()
		_delete_slot(_sel)


func _enter_slot(slot: int) -> void:
	SaveManager.current_slot = slot
	var target := HUB_SCENE
	if SaveManager.has_slot(slot):
		SaveManager.load_slot(slot)
	else:
		PlayerProgress.reset()
		SaveManager.save_slot(slot)   # stake the slot
		target = AREA_SCENE
	# Defer the swap so we leave _input cleanly before this node is freed.
	get_tree().call_deferred("change_scene_to_file", target)


func _delete_slot(slot: int) -> void:
	if not SaveManager.has_slot(slot):
		return
	if _confirm_delete != slot:
		_confirm_delete = slot   # arm; a second press confirms
		return
	SaveManager.delete_slot(slot)
	_confirm_delete = -1


# --- drawing -----------------------------------------------------------------

func _draw() -> void:
	_draw_sky()
	_draw_skyline()
	_draw_fog()
	_draw_embers()
	_draw_fireflies()
	_draw_cairn_logo()
	_draw_title()
	_draw_slots()
	_draw_vignette()


func _draw_sky() -> void:
	# Vertical gradient, dark indigo top -> faint warmth near the horizon.
	var h := size.y
	var bands := 24
	for i in range(bands):
		var f := float(i) / bands
		var col := Color(0.04, 0.04, 0.09).lerp(Color(0.10, 0.07, 0.14), f)
		draw_rect(Rect2(0, h * f, size.x, h / bands + 1.0), col)


func _draw_skyline() -> void:
	# Two depth bands of buried-city silhouettes with flickering remnant lights.
	var base_y := size.y * 0.78
	_skyline_band(base_y + 26.0, 64.0, 120.0, Color(0.06, 0.06, 0.11), 0.0, 0.9)
	_skyline_band(base_y, 96.0, 150.0, Color(0.08, 0.08, 0.14), 700.0, 1.0)


func _skyline_band(y: float, min_h: float, max_h: float, col: Color, seed_off: float, light: float) -> void:
	var x := -20.0
	var i := 0
	while x < size.x + 20.0:
		var s := sin((x + seed_off) * 0.07) * 0.5 + 0.5
		var bw := 42.0 + s * 46.0
		var bh := min_h + s * (max_h - min_h)
		draw_rect(Rect2(x, y - bh, bw - 6.0, bh), col)
		# Roofline notch.
		draw_rect(Rect2(x, y - bh - 4.0, (bw - 6.0) * 0.5, 4.0), col)
		# Window lights (slow flicker).
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
		i += 1
	# Ground line.
	draw_rect(Rect2(0, y, size.x, size.y - y), Color(0.03, 0.03, 0.06))


func _draw_fog() -> void:
	# Three drifting translucent fog bands across the lower third.
	for b in range(3):
		var y := size.y * (0.62 + b * 0.1)
		var drift := fmod(_time * (6.0 + b * 4.0), size.x)
		var col := Color(0.3, 0.32, 0.46, 0.05 + b * 0.015)
		for k in range(-1, 8):
			var cxp := fmod(k * 150.0 + drift, size.x + 300.0) - 150.0
			draw_circle(Vector2(cxp, y + sin(_time * 0.5 + k) * 6.0), 90.0 - b * 14.0, col)


func _draw_embers() -> void:
	# Slow rising motes of pale ash/ember.
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
	# A small stack of balanced stones above the title, faintly lit — the motif.
	var cx := size.x * 0.5
	var top := 44.0
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
	# A rune light at the top stone.
	draw_circle(Vector2(cx, top + 1.0), 2.2 + glow, Color(0.7, 0.82, 1.0, 0.9))


func _oval(c: Vector2, rw: float, rh: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(seg):
		var a := TAU * i / seg
		pts.append(c + Vector2(cos(a) * rw, sin(a) * rh))
	return pts


func _draw_title() -> void:
	var bob := sin(_time * 1.2) * 2.0
	var y := 130.0 + bob
	var glow := 0.5 + 0.5 * sin(_time * 1.6)
	# Layered glow behind the wordmark.
	for r in range(4, 0, -1):
		var a := 0.05 * glow * r
		draw_string(FONT, Vector2(0, y + 1.0), "CAIRN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 56 + r, Color(0.5, 0.6, 1.0, a))
	draw_string(FONT, Vector2(0, y + 2.0), "CAIRN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 56, Color(0.05, 0.05, 0.1))  # shadow
	draw_string(FONT, Vector2(0, y), "CAIRN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 56, Color(0.9, 0.92, 1.0))
	draw_string(FONT, Vector2(0, y + 28.0), "DESCEND INTO THE HOLLOW", HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color(0.5, 0.55, 0.72, 0.7 + 0.3 * glow))


func _draw_slots() -> void:
	var rw := 420.0
	var rh := 56.0
	var x0 := size.x * 0.5 - rw * 0.5
	var y0 := 232.0
	for i in range(SaveManager.SLOTS):
		var ry := y0 + i * (rh + 14.0)
		var rect := Rect2(x0, ry, rw, rh)
		var selected := i == _sel
		draw_rect(rect, Color(0.08, 0.08, 0.13, 0.85) if not selected else Color(0.15, 0.14, 0.22, 0.92))
		var border := Color(0.32, 0.34, 0.44) if not selected else Color(0.7, 0.66, 1.0)
		draw_rect(rect, border, false, 2.0 if selected else 1.0)
		if selected:
			# Pulsing outer glow + a sweeping sheen.
			var glow := 0.5 + 0.5 * sin(_time * 5.0)
			draw_rect(rect.grow(3.0), Color(0.6, 0.55, 1.0, 0.12 + 0.12 * glow), false, 2.0)
			var sweep := fmod(_time * 0.4, 1.4) - 0.2
			var sxp := x0 + rw * sweep
			if sxp >= x0 and sxp <= x0 + rw:
				draw_rect(Rect2(sxp, ry + 1.0, 24.0, rh - 2.0), Color(0.8, 0.8, 1.0, 0.06))
			# Selection caret.
			var caret := x0 - 18.0 + sin(_time * 6.0) * 2.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(caret, ry + rh * 0.5 - 5.0), Vector2(caret + 8.0, ry + rh * 0.5), Vector2(caret, ry + rh * 0.5 + 5.0)]),
				Color(0.8, 0.78, 1.0))

		var s := SaveManager.slot_summary(i)
		draw_string(FONT, Vector2(x0 + 16.0, ry + 24.0), "SLOT %d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, rw, 14, Color(0.85, 0.88, 0.98))
		if s.is_empty():
			draw_string(FONT, Vector2(x0 + 16.0, ry + 44.0), "— empty —   [enter] new game", HORIZONTAL_ALIGNMENT_LEFT, rw - 32.0, 10, Color(0.55, 0.58, 0.7))
		else:
			var info := "Shards %d   ·   %d skills   ·   %s" % [s.get("shards", 0), s.get("nodes", 0), str(s.get("area", "?")).capitalize()]
			draw_string(FONT, Vector2(x0 + 16.0, ry + 44.0), info, HORIZONTAL_ALIGNMENT_LEFT, rw - 32.0, 10, Color(0.6, 0.78, 0.72))
			if _confirm_delete == i:
				draw_string(FONT, Vector2(x0 + rw - 150.0, ry + 44.0), "delete? Ctrl again", HORIZONTAL_ALIGNMENT_LEFT, 150.0, 9, Color(0.88, 0.45, 0.45))

	var hint_a := 0.55 + 0.25 * sin(_time * 2.0)
	draw_string(FONT, Vector2(0, size.y - 30.0), "↑ ↓  select      J / Space  confirm      Ctrl  delete", HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0.5, 0.53, 0.64, hint_a))


func _draw_vignette() -> void:
	# Cheap vignette: darken the four edges with translucent bands.
	var d := Color(0, 0, 0, 0.0)
	var steps := 14
	for i in range(steps):
		var a := 0.5 * pow(1.0 - float(i) / steps, 2.0)
		var col := Color(0.0, 0.0, 0.02, a * 0.18)
		var inset := i * 4.0
		draw_rect(Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0), col, false, 4.0)
