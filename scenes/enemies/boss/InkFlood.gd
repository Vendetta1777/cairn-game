extends Node2D
## Cairn — the Pale Librarian's INK FLOOD: black liquid rises from the arena
## floor for a few seconds, then drains. Standing in it burns half-hearts in
## ticks — get to the platforms. Spawned by the boss; group boss_projectile so
## resets clear it.

@export var arena_left: float = 0.0
@export var arena_right: float = 600.0
@export var floor_y: float = 252.0
@export var rise_height: float = 64.0
@export var rise_time: float = 1.0
@export var hold_time: float = 2.5
@export var tick_damage: int = 1

var _t := 0.0
var _level := 0.0    ## current ink surface offset above floor (0..rise_height)
var _tick := 0.0


func _ready() -> void:
	add_to_group("boss_projectile")


func _process(delta: float) -> void:
	_t += delta
	var total := rise_time + hold_time + rise_time
	if _t >= total:
		queue_free()
		return
	if _t < rise_time:
		_level = rise_height * (_t / rise_time)
	elif _t < rise_time + hold_time:
		_level = rise_height
	else:
		_level = rise_height * (1.0 - (_t - rise_time - hold_time) / rise_time)
	# Damage tick while the player is in the ink.
	_tick -= delta
	var player := get_tree().get_first_node_in_group("player")
	if player and _tick <= 0.0:
		var surface := floor_y - _level
		if player.global_position.x > arena_left and player.global_position.x < arena_right \
				and player.global_position.y > surface - 4.0:
			_tick = 0.7
			if player.has_method("receive_attack"):
				player.receive_attack(self, tick_damage)
	queue_redraw()


func _draw() -> void:
	if _level <= 1.0:
		return
	var surface := floor_y - _level
	var ink := Color(0.04, 0.03, 0.06, 0.88)
	draw_rect(Rect2(arena_left, surface + 2.0, arena_right - arena_left, _level), ink)
	# A writhing surface of script — broken letter-strokes riding the ink.
	var x := arena_left
	var pts := PackedVector2Array()
	while x <= arena_right:
		pts.append(Vector2(x, surface + sin(_t * 3.0 + x * 0.07) * 2.0))
		x += 8.0
	draw_polyline(pts, Color(0.55, 0.5, 0.7, 0.7), 1.2)
	for k in int((arena_right - arena_left) / 60.0):
		var gx := arena_left + 30.0 + k * 60.0 + sin(_t * 2.0 + k) * 10.0
		draw_line(Vector2(gx, surface - 3.0), Vector2(gx + 4.0, surface - 6.0), Color(0.7, 0.66, 0.85, 0.5), 1.0)
