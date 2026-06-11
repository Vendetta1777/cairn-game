extends Control
## Cairn — title screen + save-slot select (GDD Section 15: 3 slots). Boots first.
## An empty slot starts a New Game (resets PlayerProgress, drops you into Area 1);
## a used slot Continues (loads it, drops you into the Sanctum hub to regroup).
## Up/Down pick a slot, attack/jump/interact confirm, crouch deletes.

const FONT := preload("res://assets/fonts/silkscreen.ttf")
const AREA_SCENE := "res://scenes/world/area_01_hollowed_gate/Area1.tscn"
const HUB_SCENE := "res://scenes/world/sanctum/Sanctum.tscn"

var _sel := 0
var _time := 0.0
var _confirm_delete := -1


func _ready() -> void:
	# Fresh progression until a slot is chosen.
	PlayerProgress.reset()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		_sel = wrapi(_sel - 1, 0, SaveManager.SLOTS); _confirm_delete = -1
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_sel = wrapi(_sel + 1, 0, SaveManager.SLOTS); _confirm_delete = -1
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack") or event.is_action_pressed("jump") or event.is_action_pressed("interact"):
		_enter_slot(_sel)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("crouch"):
		_delete_slot(_sel)
		get_viewport().set_input_as_handled()


func _enter_slot(slot: int) -> void:
	SaveManager.current_slot = slot
	if SaveManager.has_slot(slot):
		SaveManager.load_slot(slot)
		get_tree().change_scene_to_file(HUB_SCENE)
	else:
		PlayerProgress.reset()
		SaveManager.save_slot(slot)   # stake the slot
		get_tree().change_scene_to_file(AREA_SCENE)


func _delete_slot(slot: int) -> void:
	if not SaveManager.has_slot(slot):
		return
	if _confirm_delete != slot:
		_confirm_delete = slot   # arm; a second press confirms
		return
	SaveManager.delete_slot(slot)
	_confirm_delete = -1


func _draw() -> void:
	# Backdrop.
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.03, 0.03, 0.06))
	for i in range(60):
		var fx := fmod(i * 137.0 + _time * 4.0, size.x)
		var fy := fmod(i * 73.0, size.y * 0.7)
		draw_circle(Vector2(fx, fy), 1.0, Color(0.5, 0.6, 0.9, 0.08 + 0.06 * sin(_time + i)))

	var cx := size.x * 0.5
	# Title.
	draw_string(FONT, Vector2(0, 110), "CAIRN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 56, Color(0.9, 0.92, 1.0))
	draw_string(FONT, Vector2(0, 138), "descend into the hollow", HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color(0.5, 0.55, 0.72))

	# Slots.
	var rw := 420.0
	var rh := 56.0
	var x0 := cx - rw * 0.5
	var y0 := 210.0
	for i in range(SaveManager.SLOTS):
		var ry := y0 + i * (rh + 14.0)
		var rect := Rect2(x0, ry, rw, rh)
		var selected := i == _sel
		draw_rect(rect, Color(0.08, 0.08, 0.13) if not selected else Color(0.14, 0.14, 0.21))
		draw_rect(rect, Color(0.35, 0.36, 0.46) if not selected else Color(0.7, 0.66, 1.0), false, 2.0 if selected else 1.0)
		var s := SaveManager.slot_summary(i)
		var label := "SLOT %d" % (i + 1)
		draw_string(FONT, Vector2(x0 + 16.0, ry + 24.0), label, HORIZONTAL_ALIGNMENT_LEFT, rw, 14, Color(0.85, 0.88, 0.98))
		if s.is_empty():
			draw_string(FONT, Vector2(x0 + 16.0, ry + 44.0), "— empty —   [enter] new game", HORIZONTAL_ALIGNMENT_LEFT, rw - 32.0, 10, Color(0.55, 0.58, 0.7))
		else:
			var info := "Shards %d   ·   %d skills   ·   %s" % [s.get("shards", 0), s.get("nodes", 0), str(s.get("area", "?")).capitalize()]
			draw_string(FONT, Vector2(x0 + 16.0, ry + 44.0), info, HORIZONTAL_ALIGNMENT_LEFT, rw - 32.0, 10, Color(0.6, 0.75, 0.7))
			if _confirm_delete == i:
				draw_string(FONT, Vector2(x0 + rw - 150.0, ry + 44.0), "delete? crouch again", HORIZONTAL_ALIGNMENT_LEFT, 150.0, 9, Color(0.85, 0.45, 0.45))

	draw_string(FONT, Vector2(0, size.y - 30.0), "↑ ↓  select      J / Space  confirm      Ctrl  delete", HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0.5, 0.53, 0.64))
