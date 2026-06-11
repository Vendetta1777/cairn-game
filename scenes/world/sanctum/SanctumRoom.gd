extends Node2D
## Cairn — the Sanctum hub room (GDD Section 9, "The Sanctum"). A small, safe,
## candle-lit stone chamber between runs: no enemies, no pits. Builds its own
## floor/walls/ceiling collision (data-driven like the area terrain) and clamps
## the player's camera. A quiet place to spend Shards at the altar and descend.

@export var bounds := Rect2(0, 0, 960, 288)

const SEGMENTS: Array[Rect2] = [
	Rect2(0, 0, 960, 16),      # ceiling
	Rect2(0, 0, 16, 288),      # left wall
	Rect2(944, 0, 16, 288),    # right wall
	Rect2(16, 252, 928, 36),   # floor
	# a low dais in the middle the altar stands on
	Rect2(420, 240, 120, 12),
]

const STONE := Color(0.1, 0.1, 0.15)
const STONE_HI := Color(0.16, 0.16, 0.22)
const STONE_LO := Color(0.06, 0.06, 0.1)
const RIM := Color(0.28, 0.3, 0.42)

var _player: Node2D


func _ready() -> void:
	for r in SEGMENTS:
		_make_body(r)
	queue_redraw()
	call_deferred("_setup_player")


func _make_body(r: Rect2) -> void:
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	cs.position = r.position + r.size * 0.5
	body.add_child(cs)
	add_child(body)


func _setup_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	var cam = _player.get_node_or_null("Camera")
	if cam:
		cam.limit_left = int(bounds.position.x)
		cam.limit_top = int(bounds.position.y)
		cam.limit_right = int(bounds.end.x)
		cam.limit_bottom = int(bounds.end.y)


func _draw() -> void:
	for r in SEGMENTS:
		draw_rect(r, STONE)
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, maxf(r.size.y * 0.4, 3.0)), STONE_HI)
		draw_rect(Rect2(r.position.x, r.end.y - 3.0, r.size.x, 3.0), STONE_LO)
		# top rim accent on upward-facing ledges
		if r.size.x > r.size.y and r.position.y > 0.0:
			draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1.5), RIM)
	# Faint floor brick seams.
	var x := 40.0
	while x < bounds.size.x - 40.0:
		draw_line(Vector2(x, 252), Vector2(x, 270), STONE_LO, 1.0)
		x += 48.0
