extends Node2D
## Cairn — an EXTENDING BRIDGE driven by pressure plates: stone segments slide
## out of the wall one by one while active, and withdraw when the plate
## releases (unless the plate latches). Solid only where extended.

@export var segments: int = 5
@export var segment_size := Vector2(26, 12)
@export var direction: int = 1        ## 1 = extends right, -1 = left
@export var extend_time: float = 0.22 ## per segment

var _active := false
var _extended := 0.0   ## 0..segments, fractional while moving
var _bodies: Array[StaticBody2D] = []


func _ready() -> void:
	for i in segments:
		var b := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = segment_size
		cs.shape = shape
		b.add_child(cs)
		b.position = Vector2(direction * (i + 0.5) * segment_size.x, segment_size.y * 0.5)
		add_child(b)
		_set_solid(b, false)
		_bodies.append(b)


func _set_solid(b: StaticBody2D, on: bool) -> void:
	b.collision_layer = 1 if on else 0
	b.get_child(0).set_deferred("disabled", not on)


func set_active(on: bool) -> void:
	_active = on
	if on:
		AudioManager.play_at("door", global_position, -10.0)


func _process(delta: float) -> void:
	var target := float(segments) if _active else 0.0
	var prev := _extended
	_extended = move_toward(_extended, target, delta / extend_time)
	if _extended != prev:
		queue_redraw()
		for i in segments:
			_set_solid(_bodies[i], _extended >= i + 0.6)


func _draw() -> void:
	var n := int(ceil(_extended))
	for i in n:
		var frac: float = clampf(_extended - i, 0.0, 1.0)
		var w: float = segment_size.x * frac
		var x: float = direction * i * segment_size.x
		if direction < 0:
			x -= w
		var r := Rect2(x, 0, w, segment_size.y)
		draw_rect(r, Color(0.3, 0.29, 0.26))
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2.0), Color(0.44, 0.43, 0.38))
		draw_rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 2.0), Color(0.16, 0.155, 0.13))
		if frac >= 1.0:
			draw_line(Vector2(x + (segment_size.x if direction > 0 else 0.0), 1.0),
				Vector2(x + (segment_size.x if direction > 0 else 0.0), segment_size.y - 1.0),
				Color(0.12, 0.115, 0.1), 1.0)
