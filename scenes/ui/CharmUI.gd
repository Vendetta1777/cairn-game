extends CanvasLayer
## Cairn — the ATTUNEMENT screen, opened with E at a lit Remnant Stone. Your
## carved charms on the left, the notch row up top, the chosen charm's lore on
## the right. W/S browse · E equip/unequip · Esc leave. Overcharms take two
## notches. Builds are decided here and nowhere else.

const Charms = preload("res://scenes/systems/CharmDB.gd")
const FONT := preload("res://assets/fonts/silkscreen.ttf")

var _open := false
var _sel := 0
var _msg := ""
var _msg_t := 0.0

@onready var _canvas: Control = $Canvas


func _ready() -> void:
	add_to_group("charm_ui")
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_canvas.draw.connect(_paint)


func open_charms() -> void:
	_open = true
	_sel = 0
	_msg = ""
	visible = true
	get_tree().paused = true
	AudioManager.ui("map_rustle", -10.0)


func _close() -> void:
	_open = false
	visible = false
	get_tree().paused = false
	# Re-apply: charms take hold by re-syncing the player's components.
	var player := get_tree().get_first_node_in_group("player")
	if player:
		for child_name in ["Stats", "Combat"]:
			var c = player.get_node_or_null(child_name)
			if c and c.has_method("_ready"):
				c._ready()
		if player.has_method("_ready"):
			player._ready()
	SaveManager.autosave()


func _owned() -> Array:
	var out := []
	for id in Charms.DB:
		if PlayerProgress.has_charm(id):
			out.append(id)
	return out


func _process(delta: float) -> void:
	if not _open:
		return
	_msg_t = maxf(0.0, _msg_t - delta)
	var owned := _owned()
	if Input.is_action_just_pressed("move_up"):
		_sel = wrapi(_sel - 1, 0, maxi(owned.size(), 1))
		AudioManager.ui("menu_click", -14.0)
	elif Input.is_action_just_pressed("move_down"):
		_sel = wrapi(_sel + 1, 0, maxi(owned.size(), 1))
		AudioManager.ui("menu_click", -14.0)
	elif Input.is_action_just_pressed("interact") and not owned.is_empty():
		var id: String = owned[mini(_sel, owned.size() - 1)]
		if PlayerProgress.is_equipped(id):
			PlayerProgress.unequip_charm(id)
			AudioManager.ui("menu_click", -10.0)
		elif PlayerProgress.equip_charm(id):
			AudioManager.ui("menu_select", -8.0)
		else:
			_msg = "Not enough notches."
			_msg_t = 1.8
			AudioManager.play("parry_fail", -12.0)
	elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("crouch"):
		_close()
	_canvas.queue_redraw()


func _paint() -> void:
	var s := _canvas.size
	_canvas.draw_rect(Rect2(0, 0, s.x, s.y), Color(0.01, 0.012, 0.02, 0.88))
	_canvas.draw_string(FONT, Vector2(0, 52), "ATTUNEMENT", HORIZONTAL_ALIGNMENT_CENTER, s.x, 18, Color(0.85, 0.82, 0.95))
	# The notch row.
	var slots := PlayerProgress.charm_slots()
	var used := PlayerProgress.slots_used()
	var nx := s.x * 0.5 - slots * 14.0
	for i in slots:
		var c := Vector2(nx + i * 28.0 + 10.0, 84.0)
		var filled := i < used
		_canvas.draw_circle(c, 8.0, Color(0.5, 0.45, 0.7) if filled else Color(0.12, 0.12, 0.2))
		_canvas.draw_arc(c, 8.0, 0, TAU, 16, Color(0.6, 0.58, 0.8), 1.4)
	var owned := _owned()
	if owned.is_empty():
		_canvas.draw_string(FONT, Vector2(0, s.y * 0.5), "— no charms carved yet — the deep hides twenty —",
			HORIZONTAL_ALIGNMENT_CENTER, s.x, 11, Color(0.6, 0.62, 0.75))
	else:
		var x0 := s.x * 0.5 - 330.0
		var sel: int = mini(_sel, owned.size() - 1)
		for i in owned.size():
			var id: String = owned[i]
			var charm: Dictionary = Charms.get_charm(id)
			var iy := 130.0 + i * 28.0
			var seld := i == sel
			var equipped := PlayerProgress.is_equipped(id)
			var col := Color(0.92, 0.92, 1.0) if seld else Color(0.55, 0.57, 0.7)
			if equipped:
				col = Color(0.95, 0.85, 0.55) if seld else Color(0.7, 0.62, 0.42)
			if seld:
				_canvas.draw_rect(Rect2(x0 - 12, iy - 14, 330, 26), Color(0.12, 0.11, 0.18, 0.8))
			_canvas.draw_circle(Vector2(x0, iy - 4), 5.0, col.darkened(0.3))
			_canvas.draw_circle(Vector2(x0, iy - 4), 3.0, col)
			_canvas.draw_string(FONT, Vector2(x0 + 14, iy), str(charm.get("name", id)),
				HORIZONTAL_ALIGNMENT_LEFT, 220, 11, col)
			_canvas.draw_string(FONT, Vector2(x0 + 240, iy), "%d◉" % charm.get("slots", 1),
				HORIZONTAL_ALIGNMENT_LEFT, 60, 10, Color(0.5, 0.48, 0.66))
			if equipped:
				_canvas.draw_string(FONT, Vector2(x0 + 280, iy), "worn", HORIZONTAL_ALIGNMENT_LEFT, 60, 9, col)
		# Lore panel for the selected charm.
		var cur: Dictionary = Charms.get_charm(owned[sel])
		var lx := s.x * 0.5 + 40.0
		_canvas.draw_rect(Rect2(lx - 12, 118, 300, 180), Color(0.05, 0.05, 0.09, 0.9))
		_canvas.draw_rect(Rect2(lx - 12, 118, 300, 180), Color(0.35, 0.36, 0.5, 0.7), false, 1.0)
		_canvas.draw_string(FONT, Vector2(lx, 142), str(cur.get("name", "")),
			HORIZONTAL_ALIGNMENT_LEFT, 280, 13, Color(0.95, 0.92, 1.0))
		_paint_wrapped(str(cur.get("lore", "")), Vector2(lx, 166), 276, 10, Color(0.62, 0.65, 0.78))
	if _msg_t > 0.0:
		_canvas.draw_string(FONT, Vector2(0, s.y - 64), _msg, HORIZONTAL_ALIGNMENT_CENTER, s.x, 11, Color(0.95, 0.7, 0.5))
	_canvas.draw_string(FONT, Vector2(0, s.y - 30), "W / S  browse      E  equip / unequip      Esc  done",
		HORIZONTAL_ALIGNMENT_CENTER, s.x, 9, Color(0.45, 0.48, 0.6))


func _paint_wrapped(text: String, at: Vector2, width: float, size_px: int, col: Color) -> void:
	var words := text.split(" ")
	var line := ""
	var y := at.y
	for w in words:
		var probe := (line + " " + w).strip_edges()
		if probe.length() * size_px * 0.62 > width:
			_canvas.draw_string(FONT, Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, size_px, col)
			y += size_px + 5
			line = w
		else:
			line = probe
	if line != "":
		_canvas.draw_string(FONT, Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, size_px, col)
