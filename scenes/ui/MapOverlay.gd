extends Control
## Cairn — the area map (GDD Section 10: "map on hold-TAB, fog of war"). A
## schematic strip of the current area: explored ground is lit, the unexplored
## stretch stays dark, and points of interest (checkpoints, the boss, the exit,
## shrines, portals) are pinned once you've been near them. Held, not toggled.

const FONT := preload("res://assets/fonts/silkscreen.ttf")

var _player: Node2D
var _bl := 0.0
var _br := 3000.0
var _explored_l := INF
var _explored_r := -INF


func _ready() -> void:
	visible = false


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player:
		# Bounds come from the camera limits the terrain set.
		var cam = _player.get_node_or_null("Camera")
		if cam:
			_bl = cam.limit_left
			_br = cam.limit_right
		var px := _player.global_position.x
		_explored_l = minf(_explored_l, px - 120.0)
		_explored_r = maxf(_explored_r, px + 120.0)

	var show := Input.is_action_pressed("map")
	if show != visible:
		visible = show
	if visible:
		queue_redraw()


func _x_to_screen(world_x: float, sx: float, sw: float) -> float:
	var span := maxf(_br - _bl, 1.0)
	return sx + sw * clampf((world_x - _bl) / span, 0.0, 1.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.02, 0.02, 0.05, 0.78))

	var sw := size.x * 0.74
	var sx := (size.x - sw) * 0.5
	var sy := size.y * 0.5
	var sh := 26.0

	draw_string(FONT, Vector2(sx, sy - 54.0), "THE HOLLOWED GATE", HORIZONTAL_ALIGNMENT_LEFT, sw, 16, Color(0.88, 0.9, 1.0))
	draw_string(FONT, Vector2(sx, sy - 34.0), "AREA MAP", HORIZONTAL_ALIGNMENT_LEFT, sw, 10, Color(0.55, 0.6, 0.74))

	# Unexplored track (dark) then explored band (lit) over it.
	draw_rect(Rect2(sx, sy, sw, sh), Color(0.07, 0.07, 0.11))
	draw_rect(Rect2(sx, sy, sw, sh), Color(0.3, 0.32, 0.42), false, 1.0)
	if _explored_r > _explored_l:
		var ex0 := _x_to_screen(_explored_l, sx, sw)
		var ex1 := _x_to_screen(_explored_r, sx, sw)
		draw_rect(Rect2(ex0, sy, ex1 - ex0, sh), Color(0.2, 0.26, 0.36))
		draw_rect(Rect2(ex0, sy, ex1 - ex0, sh * 0.4), Color(0.26, 0.34, 0.46))

	# POI pins (only if within the explored band — fog of war).
	_pins("checkpoint", Color(0.7, 0.45, 0.85), "R", sx, sw, sy, sh)
	_pins("shrine", Color(0.55, 0.72, 1.0), "S", sx, sw, sy, sh)
	_pins("boss", Color(0.85, 0.3, 0.34), "B", sx, sw, sy, sh)
	_pins("exit", Color(0.6, 0.85, 0.7), "G", sx, sw, sy, sh)
	_pins("portal", Color(0.7, 0.66, 1.0), "P", sx, sw, sy, sh)

	# Player marker.
	if _player:
		var mx := _x_to_screen(_player.global_position.x, sx, sw)
		draw_colored_polygon(PackedVector2Array([
			Vector2(mx, sy - 6.0), Vector2(mx + 4.0, sy - 13.0), Vector2(mx - 4.0, sy - 13.0)]),
			Color(1, 1, 1))
		draw_line(Vector2(mx, sy), Vector2(mx, sy + sh), Color(1, 1, 1, 0.8), 1.5)

	draw_string(FONT, Vector2(sx, sy + sh + 24.0), "hold TAB to view", HORIZONTAL_ALIGNMENT_LEFT, sw, 9, Color(0.5, 0.52, 0.62))


func _pins(group: String, col: Color, glyph: String, sx: float, sw: float, sy: float, sh: float) -> void:
	for n in get_tree().get_nodes_in_group(group):
		if not (n is Node2D):
			continue
		var wx: float = (n as Node2D).global_position.x
		# Fog of war: only show what you've discovered.
		if wx < _explored_l or wx > _explored_r:
			continue
		var px := _x_to_screen(wx, sx, sw)
		draw_circle(Vector2(px, sy + sh * 0.5), 4.0, col)
		draw_circle(Vector2(px, sy + sh * 0.5), 4.0, Color(0, 0, 0, 0.5), false)
		draw_string(FONT, Vector2(px - 4.0, sy - 2.0), glyph, HORIZONTAL_ALIGNMENT_CENTER, 8, 8, col)
