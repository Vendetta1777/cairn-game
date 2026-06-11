extends Control
## Cairn — the area map (hold TAB). A real side-view minimap: it reads the level's
## actual terrain (CaveTerrain.get_solids) and draws the platform silhouette to
## scale inside a framed panel, with fog of war (only what you've explored shows),
## spike-pit warnings, pinned points of interest, and your position. Held, not
## toggled.

const FONT := preload("res://assets/fonts/silkscreen.ttf")

var _player: Node2D
var _terrain: Node
var _bl := 0.0
var _br := 3000.0
var _explored_l := INF
var _explored_r := -INF


func _ready() -> void:
	visible = false


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _terrain == null or not is_instance_valid(_terrain):
		_terrain = get_tree().get_first_node_in_group("terrain")
	if _player:
		if _terrain and "bounds" in _terrain:
			_bl = _terrain.bounds.position.x
			_br = _terrain.bounds.end.x
		var px := _player.global_position.x
		_explored_l = minf(_explored_l, px - 130.0)
		_explored_r = maxf(_explored_r, px + 130.0)

	var show := Input.is_action_pressed("map")
	if show != visible:
		visible = show
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.02, 0.02, 0.05, 0.82))

	# Panel.
	var pw := size.x * 0.82
	var px0 := (size.x - pw) * 0.5
	var pad := 22.0
	var bounds_w := maxf(_br - _bl, 1.0)
	var scale := (pw - pad * 2.0) / bounds_w
	var map_h := 288.0 * scale
	var py0 := size.y * 0.5 - map_h * 0.5
	var ph := map_h + pad * 1.6

	# Frame + backplate.
	var frame := Rect2(px0, py0 - pad * 0.6, pw, ph)
	draw_rect(frame, Color(0.04, 0.05, 0.08, 0.95))
	draw_rect(frame, Color(0.4, 0.45, 0.58, 0.8), false, 1.5)
	draw_rect(Rect2(frame.position, Vector2(frame.size.x, 1.0)), Color(0.55, 0.62, 0.78, 0.9))

	draw_string(FONT, Vector2(px0 + pad, py0 - pad * 0.6 - 8.0), "MAP", HORIZONTAL_ALIGNMENT_LEFT, pw, 14, Color(0.86, 0.9, 1.0))

	var mx := px0 + pad
	var my := py0
	var to_map := func(wx: float, wy: float) -> Vector2:
		return Vector2(mx + (wx - _bl) * scale, my + wy * scale)

	# Explored band shading.
	if _explored_r > _explored_l:
		var ex0: float = (to_map.call(maxf(_explored_l, _bl), 0.0) as Vector2).x
		var ex1: float = (to_map.call(minf(_explored_r, _br), 0.0) as Vector2).x
		draw_rect(Rect2(ex0, my, ex1 - ex0, map_h), Color(0.12, 0.16, 0.24, 0.6))

	# Terrain silhouette — only the interior platforms/floors, fogged by explore.
	if _terrain and _terrain.has_method("get_solids"):
		for r in _terrain.get_solids():
			# Skip the ceiling and the full-height border walls (they're the frame).
			if r.position.y <= 0.0 or r.size.y > 180.0:
				continue
			var cxw: float = r.position.x + r.size.x * 0.5
			if cxw < _explored_l or cxw > _explored_r:
				continue
			var a: Vector2 = to_map.call(r.position.x, r.position.y)
			var b: Vector2 = to_map.call(r.end.x, r.end.y)
			var rect := Rect2(a, b - a)
			rect.size = rect.size.max(Vector2(1.5, 1.5))
			draw_rect(rect, Color(0.5, 0.56, 0.7))
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1.0)), Color(0.7, 0.78, 0.92))

	# Spike pits (hazards) as small red warnings.
	if _terrain and _terrain.has_method("hazards"):
		for r in _terrain.hazards():
			var cxw: float = r.position.x + r.size.x * 0.5
			if cxw < _explored_l or cxw > _explored_r:
				continue
			var a: Vector2 = to_map.call(r.position.x, r.position.y)
			var w: float = r.size.x * scale
			draw_rect(Rect2(a.x, a.y, w, 2.0), Color(0.85, 0.3, 0.32, 0.85))

	# POI pins.
	_pins("checkpoint", Color(0.7, 0.45, 0.85), to_map, my, map_h)
	_pins("boss", Color(0.85, 0.3, 0.34), to_map, my, map_h)
	_pins("exit", Color(0.55, 0.85, 0.95), to_map, my, map_h)
	_pins("portal", Color(0.7, 0.66, 1.0), to_map, my, map_h)
	_pins("shrine", Color(1.0, 0.55, 0.6), to_map, my, map_h)

	# Player marker (pulsing).
	if _player:
		var p: Vector2 = to_map.call(_player.global_position.x, _player.global_position.y)
		draw_circle(p, 4.0, Color(1, 1, 1, 0.25))
		draw_circle(p, 2.2, Color(1, 1, 1))

	draw_string(FONT, Vector2(px0 + pad, py0 + map_h + pad * 0.7), "hold TAB", HORIZONTAL_ALIGNMENT_LEFT, pw, 9, Color(0.5, 0.54, 0.66))


func _pins(group: String, col: Color, to_map: Callable, my: float, map_h: float) -> void:
	for n in get_tree().get_nodes_in_group(group):
		if not (n is Node2D):
			continue
		var wx: float = (n as Node2D).global_position.x
		if wx < _explored_l or wx > _explored_r:
			continue
		var p: Vector2 = to_map.call(wx, (n as Node2D).global_position.y)
		# Pin sits just above the floor line for clarity.
		var pin := Vector2(p.x, my + map_h - 4.0)
		draw_circle(pin, 3.0, col)
		draw_line(pin, Vector2(pin.x, my), Color(col.r, col.g, col.b, 0.25), 1.0)
