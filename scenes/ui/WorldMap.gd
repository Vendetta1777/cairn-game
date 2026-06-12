extends Control
## Cairn — the WORLD MAP (press M). A carved stone tablet of the whole descent:
## every discovered area is an etched cartouche on the shaft downward; the
## undiscovered deep is rough, uncut rock (fog of war). Your position is a small
## skull; discovered shrines are glowing rune marks; ability gates and locked
## doors are drawn as rune-locks in the colour of the power they demand — so you
## always know what to come back for. A newly discovered area ETCHES itself in,
## line by line, the first time you open the tablet. Pauses the game while open.
##
## (The hold-TAB strip map remains the quick in-level readout; this is the
## tablet you sit with.)

const FONT := preload("res://assets/fonts/silkscreen.ttf")

## The carved world: one entry per area, laid out on the tablet (relative
## coords in a 700x420 design space). Gates list what seals side paths there.
const AREAS := [
	{
		"id": "sanctum", "name": "THE SANCTUM", "depth": "REFUGE",
		"rect": Rect2(60, 160, 150, 56),
		"shrines": 0, "gates": [],
	},
	{
		"id": "hollowed_gate", "name": "THE HOLLOWED GATE", "depth": "I",
		"rect": Rect2(270, 16, 360, 52),
		"shrines": 1, "gates": ["dash", "double_jump"],
	},
	{
		"id": "ashpits", "name": "THE ASHPITS", "depth": "II",
		"rect": Rect2(270, 80, 360, 52),
		"shrines": 1, "gates": ["double_jump"],
	},
	{
		"id": "sunken_nave", "name": "THE SUNKEN NAVE", "depth": "III",
		"rect": Rect2(270, 144, 360, 52),
		"shrines": 1, "gates": ["double_jump"],
	},
	{
		"id": "pale_library", "name": "THE PALE LIBRARY", "depth": "IV",
		"rect": Rect2(270, 208, 360, 52),
		"shrines": 0, "gates": ["grapple", "sealed"],
	},
	{
		"id": "iron_warrens", "name": "THE IRON WARRENS", "depth": "V",
		"rect": Rect2(270, 272, 360, 52),
		"shrines": 2, "gates": ["grapple", "sealed"],
	},
	{
		"id": "throne", "name": "THE SOVEREIGN'S THRONE", "depth": "VI",
		"rect": Rect2(270, 336, 360, 52),
		"shrines": 1, "gates": ["grapple"],
	},
]

const GATE_TINTS := {
	"dash": Color(0.55, 0.9, 1.0),
	"wall_jump": Color(1.0, 0.62, 0.38),
	"double_jump": Color(0.55, 0.95, 0.7),
	"grapple": Color(0.95, 0.85, 0.5),
	"sealed": Color(0.85, 0.4, 0.45),
}

var _open := false
var _t := 0.0
var _etch: Dictionary = {}    ## area id -> etch progress 0..1 (1 = fully drawn)


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("world_map"):
		_toggle()
		get_viewport().set_input_as_handled()
	elif _open and (event.is_action_pressed("pause") or event.is_action_pressed("crouch")):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	_open = not _open
	visible = _open
	get_tree().paused = _open
	if _open:
		# Arm the etch animation for anything seen but not yet drawn on the tablet.
		for a in AREAS:
			var id: String = a.id
			if _seen(id):
				if PlayerProgress.has_flag("etched_%s" % id):
					_etch[id] = 1.0
				else:
					_etch[id] = 0.0
					PlayerProgress.set_flag("etched_%s" % id)
		AudioManager.play("door", -14.0)


func _seen(id: String) -> bool:
	return PlayerProgress.has_flag("seen_%s" % id)


func _process(delta: float) -> void:
	if not _open:
		return
	_t += delta
	for id in _etch:
		if _etch[id] < 1.0:
			_etch[id] = minf(1.0, _etch[id] + delta * 1.1)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.01, 0.012, 0.02, 0.88))
	# The tablet: design space 700x420 centered.
	var ox := (size.x - 700.0) * 0.5
	var oy := (size.y - 420.0) * 0.5
	_draw_tablet(ox, oy)
	# The descending shaft connecting the depths.
	_draw_shaft(ox, oy)
	for a in AREAS:
		_draw_area(a, ox, oy)
	draw_string(FONT, Vector2(0, oy - 14), "THE DESCENT", HORIZONTAL_ALIGNMENT_CENTER,
		size.x, 18, Color(0.75, 0.78, 0.9))
	draw_string(FONT, Vector2(0, oy + 446), "M  close      skull = you      runes = shrines      locks = what you lack",
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, Color(0.45, 0.48, 0.6))


## The slab itself: chiseled edges, cracks, weathering — stone, not UI.
func _draw_tablet(ox: float, oy: float) -> void:
	var slab := Rect2(ox - 26, oy - 26, 752, 472)
	# Jittered outline so the slab reads hand-hewn.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var pts := PackedVector2Array()
	var per := [slab.position, Vector2(slab.end.x, slab.position.y), slab.end, Vector2(slab.position.x, slab.end.y)]
	for i in 4:
		var a: Vector2 = per[i]
		var b: Vector2 = per[(i + 1) % 4]
		for k in 14:
			var p := a.lerp(b, k / 14.0)
			pts.append(p + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4)))
	draw_colored_polygon(pts, Color(0.11, 0.115, 0.15))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.22, 0.23, 0.3), 2.0)
	# Weathering: speckles and cracks.
	for i in 130:
		var p := Vector2(rng.randf_range(slab.position.x, slab.end.x),
			rng.randf_range(slab.position.y, slab.end.y))
		draw_rect(Rect2(p.x, p.y, 1.5, 1.5),
			Color(0.18, 0.19, 0.25) if rng.randf() > 0.5 else Color(0.07, 0.075, 0.1))
	for c in 5:
		var p := Vector2(rng.randf_range(slab.position.x + 40, slab.end.x - 40),
			rng.randf_range(slab.position.y + 30, slab.end.y - 30))
		for s in 4:
			var q := p + Vector2(rng.randf_range(-26, 26), rng.randf_range(8, 22))
			draw_line(p, q, Color(0.06, 0.065, 0.09, 0.8), 1.2)
			p = q


func _draw_shaft(ox: float, oy: float) -> void:
	# A carved channel down the middle of the depths column.
	var x := ox + 450.0
	var prev_seen := _seen("hollowed_gate")
	for i in range(AREAS.size() - 1):
		var a: Dictionary = AREAS[i + 0]
		if a.id == "sanctum":
			continue
		var idx := i + 1
		if idx >= AREAS.size():
			break
		var b: Dictionary = AREAS[idx]
		var y0: float = a.rect.end.y + oy
		var y1: float = b.rect.position.y + oy
		var known := _seen(a.id) and _seen(b.id)
		var col := Color(0.3, 0.33, 0.45, 0.9) if known else Color(0.16, 0.17, 0.22, 0.6)
		draw_line(Vector2(x, y0), Vector2(x, y1), col, 3.0)
		# Chevron pointing down.
		draw_polyline(PackedVector2Array([
			Vector2(x - 5, y0 + (y1 - y0) * 0.5 - 3), Vector2(x, y0 + (y1 - y0) * 0.5 + 3),
			Vector2(x + 5, y0 + (y1 - y0) * 0.5 - 3)]), col, 1.5)
	# Side passage to the Sanctum.
	var s: Dictionary = AREAS[0]
	var g: Dictionary = AREAS[1]
	if _seen("sanctum"):
		var y: float = oy + s.rect.position.y + s.rect.size.y * 0.5
		draw_line(Vector2(ox + s.rect.end.x, y), Vector2(ox + g.rect.position.x, oy + g.rect.end.y - 10),
			Color(0.45, 0.42, 0.65, 0.8), 2.0)


func _draw_area(a: Dictionary, ox: float, oy: float) -> void:
	var r := Rect2(a.rect.position + Vector2(ox, oy), a.rect.size)
	var id: String = a.id
	if not _seen(id):
		# Undiscovered: rough uncut stone, a question of darkness.
		draw_rect(r, Color(0.07, 0.075, 0.105))
		draw_rect(r, Color(0.14, 0.15, 0.2), false, 1.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = id.hash()
		for i in 24:
			var p := Vector2(rng.randf_range(r.position.x + 4, r.end.x - 4),
				rng.randf_range(r.position.y + 4, r.end.y - 4))
			draw_rect(Rect2(p.x, p.y, 2, 2), Color(0.1, 0.11, 0.15))
		draw_string(FONT, Vector2(r.position.x, r.position.y + r.size.y * 0.58),
			"· · ·", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 14, Color(0.25, 0.27, 0.36))
		return

	var etch: float = _etch.get(id, 1.0)
	# The etch reveal: carve the panel in horizontal scratch lines, top to bottom.
	var lines := int(r.size.y / 4.0)
	var shown := int(lines * etch)
	for i in shown:
		var ly := r.position.y + i * 4.0
		var wob := sin(i * 1.7) * 2.0
		draw_rect(Rect2(r.position.x + 2 + wob, ly, r.size.x - 4 - wob * 2.0, 3.0),
			Color(0.16, 0.17, 0.235, 0.92))
	if etch < 1.0:
		# The cutting edge sparks faintly.
		var ey := r.position.y + shown * 4.0
		draw_rect(Rect2(r.position.x, ey, r.size.x, 2.0), Color(0.8, 0.85, 1.0, 0.5))
		return

	# Carved frame + inner shadow.
	draw_rect(r, Color(0.32, 0.35, 0.48), false, 1.5)
	draw_rect(r.grow(-3.0), Color(0.08, 0.085, 0.12), false, 1.0)
	# Depth numeral + name, chisel-shadowed.
	draw_string(FONT, Vector2(r.position.x + 10, r.position.y + 17) + Vector2(1, 1),
		a.depth, HORIZONTAL_ALIGNMENT_LEFT, r.size.x, 9, Color(0.04, 0.045, 0.07))
	draw_string(FONT, Vector2(r.position.x + 10, r.position.y + 17),
		a.depth, HORIZONTAL_ALIGNMENT_LEFT, r.size.x, 9, Color(0.55, 0.6, 0.78))
	draw_string(FONT, Vector2(r.position.x, r.position.y + 33) + Vector2(1, 1),
		a.name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, Color(0.04, 0.045, 0.07))
	draw_string(FONT, Vector2(r.position.x, r.position.y + 33),
		a.name, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, Color(0.85, 0.88, 1.0))

	# Shrine rune marks (discovered areas only — you've walked their halls).
	var gx := r.position.x + 14.0
	var gy := r.end.y - 11.0
	for s in int(a.shrines):
		_draw_rune(Vector2(gx, gy), 0.55 + 0.3 * sin(_t * 2.2))
		gx += 16.0
	# Gate locks: what still seals routes here, in the ability's colour.
	var lx := r.end.x - 16.0
	for g in a.gates:
		var tint: Color = GATE_TINTS.get(g, Color.GRAY)
		var have: bool = g != "sealed" and PlayerProgress.has_ability(g)
		_draw_lock(Vector2(lx, gy), tint, have)
		lx -= 18.0

	# You are here: the skull.
	if GameManager.current_area_id == id:
		_draw_skull(Vector2(r.position.x + r.size.x * 0.5, r.end.y - 15.0))


## A glowing shrine rune: a vertical stave with two cross-cuts.
func _draw_rune(p: Vector2, glow: float) -> void:
	var c := Color(1.0, 0.6, 0.65, 0.5 + glow * 0.5)
	draw_circle(p, 6.0, Color(c.r, c.g, c.b, 0.12 * glow))
	draw_line(p + Vector2(0, -5), p + Vector2(0, 5), c, 1.4)
	draw_line(p + Vector2(-3, -2), p + Vector2(3, 0), c, 1.2)
	draw_line(p + Vector2(-3, 3), p + Vector2(3, 2), c, 1.2)


## A rune-lock: padlock silhouette; dimmed once you hold the power that opens it.
func _draw_lock(p: Vector2, tint: Color, have: bool) -> void:
	var a := 0.32 if have else 0.95
	var c := Color(tint.r, tint.g, tint.b, a)
	draw_rect(Rect2(p.x - 4, p.y - 2, 8, 7), c)
	draw_arc(p + Vector2(0, -2), 3.0, PI, TAU, 8, c, 1.4)
	if have:
		draw_line(p + Vector2(-5, -6), p + Vector2(5, 6), Color(0.7, 0.95, 0.8, 0.8), 1.2)


## A small pixel skull: the player's marker.
func _draw_skull(p: Vector2) -> void:
	var bone := Color(0.92, 0.9, 0.85)
	var dark := Color(0.1, 0.1, 0.14)
	var bob := sin(_t * 3.0) * 1.5
	p.y += bob
	draw_circle(p + Vector2(0, 8), 9.0, Color(0.9, 0.9, 1.0, 0.08 + 0.05 * sin(_t * 3.0)))
	draw_rect(Rect2(p.x - 4, p.y, 8, 7), bone)           # cranium
	draw_rect(Rect2(p.x - 3, p.y + 7, 6, 3), bone)       # jaw
	draw_rect(Rect2(p.x - 3, p.y + 2, 2, 2), dark)       # sockets
	draw_rect(Rect2(p.x + 1, p.y + 2, 2, 2), dark)
	draw_rect(Rect2(p.x - 1, p.y + 5, 1, 2), dark)       # nose
	draw_rect(Rect2(p.x - 2, p.y + 8, 1, 2), dark)       # teeth
	draw_rect(Rect2(p.x, p.y + 8, 1, 2), dark)
	draw_rect(Rect2(p.x + 2, p.y + 8, 1, 2), dark)
