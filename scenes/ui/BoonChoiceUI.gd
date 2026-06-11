extends Control
## Cairn — the Shrine's boon-choice screen. Presents three random run-only boons;
## the player picks one (left/right to choose, attack/interact to confirm). The
## chosen boon is applied live to the current run. No cancel — a shrine's gift is
## taken. Pauses the game while open.

signal chosen

const FONT := preload("res://assets/fonts/silkscreen.ttf")
const CARD_W := 200.0
const CARD_H := 150.0
const GAP := 24.0

var _open := false
var _boons: Array = []
var _sel := 0
var _time := 0.0


func _ready() -> void:
	add_to_group("boon_choice")
	visible = false


func is_open() -> bool:
	return _open


func open(boons: Array) -> void:
	if boons.is_empty():
		return
	_boons = boons
	_sel = 0
	_open = true
	visible = true
	get_tree().paused = true


func _close() -> void:
	_open = false
	visible = false
	get_tree().paused = false
	chosen.emit()


func _process(delta: float) -> void:
	if _open:
		_time += delta
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("move_left"):
		_sel = wrapi(_sel - 1, 0, _boons.size())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		_sel = wrapi(_sel + 1, 0, _boons.size())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack") or event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		_confirm()
		get_viewport().set_input_as_handled()


func _confirm() -> void:
	var boon: Dictionary = _boons[_sel]
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("grant_boon"):
		player.grant_boon(boon.get("effect", {}))
	_close()


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.02, 0.02, 0.05, 0.84))
	draw_string(FONT, Vector2(0, 74), "A SHRINE OFFERS", HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color(0.86, 0.82, 1.0))
	draw_string(FONT, Vector2(0, 96), "choose one — it lasts the run", HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0.6, 0.6, 0.74))

	var n := _boons.size()
	var total := n * CARD_W + (n - 1) * GAP
	var x0 := (size.x - total) * 0.5
	var y := size.y * 0.5 - CARD_H * 0.5 + 10.0
	for i in range(n):
		var boon: Dictionary = _boons[i]
		var cx := x0 + i * (CARD_W + GAP)
		var rect := Rect2(cx, y, CARD_W, CARD_H)
		var selected := i == _sel
		# Card body + frame.
		draw_rect(rect, Color(0.08, 0.08, 0.13) if not selected else Color(0.14, 0.13, 0.2))
		var fc := Color(0.4, 0.4, 0.5) if not selected else Color(0.7, 0.66, 1.0)
		draw_rect(rect, fc, false, 2.0 if selected else 1.0)
		if selected:
			var glow := 0.5 + 0.5 * sin(_time * 5.0)
			draw_rect(rect.grow(3.0), Color(0.6, 0.55, 1.0, 0.15 + 0.15 * glow), false, 2.0)
		# Sigil.
		var sc := rect.position + Vector2(CARD_W * 0.5, 38.0)
		draw_arc(sc, 16.0, 0, TAU, 20, Color(0.7, 0.74, 1.0, 0.9), 2.0)
		draw_arc(sc, 8.0, 0, TAU, 14, Color(0.7, 0.74, 1.0, 0.6), 1.5)
		# Name + desc.
		draw_string(FONT, Vector2(cx, y + 80.0), boon.get("name", "?"), HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 14, Color(0.95, 0.95, 1.0))
		draw_multiline_string(FONT, Vector2(cx + 10.0, y + 104.0), boon.get("desc", ""), HORIZONTAL_ALIGNMENT_CENTER, CARD_W - 20.0, 10, 3, Color(0.74, 0.78, 0.9))

	draw_string(FONT, Vector2(0, size.y - 20.0), "← →  choose      J  take", HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0.55, 0.58, 0.7))
