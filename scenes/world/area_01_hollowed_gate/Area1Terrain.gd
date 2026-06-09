extends Node2D
## Cairn — Area 1 "The Hollowed Gate" terrain.
##
## Data-driven so every solid piece is generated together with its collision
## body — guaranteeing floors, ceilings, walls, platforms and objects ALL have
## hitboxes. TERRAIN/OBJECTS are Rect2 (x, y, w, h) in world space; each becomes
## a StaticBody2D + matching RectangleShape2D, and is drawn as cave stone here.
## Also clamps the player camera to the area bounds.

const STONE_DARK := Color(0.085, 0.097, 0.145)
const STONE_FACE := Color(0.13, 0.15, 0.21)
const STONE_LIP := Color(0.23, 0.27, 0.36)
const MOSS := Color(0.4, 0.78, 0.74, 0.7)
const CRATE := Color(0.27, 0.19, 0.12)
const CRATE_LIP := Color(0.42, 0.31, 0.2)

@export var bounds := Rect2(0, 0, 1440, 288)

# Solid terrain: ceiling, walls, floor segments (with pit gaps), and platforms.
const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 1440, 14),       # ceiling
	Rect2(0, 0, 14, 288),        # left wall
	Rect2(1426, 0, 14, 288),     # right wall
	# floor segments (two pits between them)
	Rect2(14, 252, 330, 36),
	Rect2(420, 252, 280, 36),
	Rect2(774, 252, 652, 36),
	# platforms
	Rect2(150, 200, 84, 14),
	Rect2(360, 196, 64, 14),     # crosses the first pit
	Rect2(520, 178, 84, 14),
	Rect2(660, 140, 76, 14),
	Rect2(716, 196, 64, 14),     # crosses the second pit
	Rect2(840, 200, 96, 14),
	Rect2(980, 160, 100, 14),
	Rect2(1140, 124, 110, 14),   # high ledge
	Rect2(1300, 200, 126, 52),   # raised step up to the exit
]

# Pushable-looking crate objects (also solid — they have hitboxes too).
const OBJECTS: Array[Rect2] = [
	Rect2(262, 220, 28, 32),
	Rect2(902, 168, 30, 32),
]


func _ready() -> void:
	for r in TERRAIN:
		_make_body(r)
	for r in OBJECTS:
		_make_body(r)
	queue_redraw()
	call_deferred("_clamp_camera")


func _make_body(r: Rect2) -> void:
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	cs.position = r.position + r.size * 0.5
	body.add_child(cs)
	add_child(body)


func _clamp_camera() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		return
	var cam = p.get_node_or_null("Camera")
	if cam == null:
		return
	cam.limit_left = int(bounds.position.x)
	cam.limit_top = int(bounds.position.y)
	cam.limit_right = int(bounds.end.x)
	cam.limit_bottom = int(bounds.end.y)


func _draw() -> void:
	for r in TERRAIN:
		draw_rect(r, STONE_DARK)
		draw_rect(Rect2(r.position.x, r.position.y + 5.0, r.size.x, 3.0), STONE_FACE)
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 5.0), STONE_LIP)
	# A few moss glints on platform edges.
	for c in [Vector2(226, 200), Vector2(596, 178), Vector2(1078, 160), Vector2(1240, 124)]:
		draw_rect(Rect2(c.x, c.y - 1.0, 8.0, 3.0), MOSS)
	for r in OBJECTS:
		draw_rect(r, CRATE)
		draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3.0), CRATE_LIP)
