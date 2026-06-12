extends Node2D
## Cairn — a counterweighted stone door driven by pressure plates (set_active).
## Slides up into the lintel when powered; falls shut when released (latch
## plates hold it forever). Solid while shut.

@export var door_height: float = 76.0
@export var door_width: float = 16.0

var _open_amt := 0.0
var _active := false
var _body: StaticBody2D


func _ready() -> void:
	_body = StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(door_width, door_height)
	cs.shape = shape
	cs.position = Vector2(0, -door_height * 0.5)
	_body.add_child(cs)
	add_child(_body)


func set_active(on: bool) -> void:
	_active = on
	if on:
		AudioManager.play_at("door", global_position, -8.0)


func _process(delta: float) -> void:
	var prev := _open_amt
	_open_amt = move_toward(_open_amt, 1.0 if _active else 0.0, delta * 0.9)
	if _open_amt != prev:
		queue_redraw()
		var solid := _open_amt < 0.7
		_body.collision_layer = 1 if solid else 0
		_body.get_child(0).set_deferred("disabled", not solid)


func _draw() -> void:
	var stone := Color(0.34, 0.33, 0.3)
	var stone_d := Color(0.2, 0.19, 0.17)
	# Frame posts + lintel.
	draw_rect(Rect2(-door_width * 0.5 - 6, -door_height - 14, 6, door_height + 14), stone_d)
	draw_rect(Rect2(door_width * 0.5, -door_height - 14, 6, door_height + 14), stone_d)
	draw_rect(Rect2(-door_width * 0.5 - 8, -door_height - 20, door_width + 16, 8), stone_d)
	# The slab, risen by _open_amt.
	var visible_h := door_height * (1.0 - _open_amt)
	if visible_h > 1.0:
		var r := Rect2(-door_width * 0.5, -visible_h, door_width, visible_h)
		draw_rect(r, stone)
		draw_rect(Rect2(r.position.x, r.position.y, door_width, 3), Color(0.45, 0.44, 0.4))
		for i in int(visible_h / 16.0):
			draw_rect(Rect2(r.position.x + 2, r.position.y + 8 + i * 16.0, door_width - 4, 1.5), stone_d)
