extends Node2D
## Cairn — Area 1 "The Hollowed Gate" terrain.
##
## Data-driven: every solid piece is generated WITH its collision body (so all
## floors/ceilings/walls/platforms/objects have hitboxes — guaranteed) and is
## drawn as detailed cave stone (gradient + speckle texture + cracks + lit top
## edge + bevels). Also clamps the player camera and handles fall-into-a-pit
## respawn (back to start, minus one heart).

# Stone palette (dark cave, cool).
const STONE_TOP := Color(0.16, 0.18, 0.24)
const STONE_MID := Color(0.11, 0.125, 0.175)
const STONE_LOW := Color(0.07, 0.08, 0.115)
const STONE_LIP := Color(0.28, 0.33, 0.43)
const STONE_FACE := Color(0.19, 0.22, 0.29)
const STONE_EDGE := Color(0.05, 0.055, 0.085)
const SPECK_LIGHT := Color(0.24, 0.27, 0.35)
const SPECK_DARK := Color(0.05, 0.05, 0.08)
const MOSS := Color(0.4, 0.82, 0.74)
const CRATE := Color(0.3, 0.21, 0.13)
const CRATE_DK := Color(0.2, 0.13, 0.08)
const CRATE_LIP := Color(0.46, 0.34, 0.21)
const CRATE_BOLT := Color(0.55, 0.5, 0.42)

@export var bounds := Rect2(0, 0, 1440, 288)
@export var fall_damage_halves := 2   # one full heart when you fall in a pit

const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 1440, 14),       # ceiling
	Rect2(0, 0, 14, 288),        # left wall
	Rect2(1426, 0, 14, 288),     # right wall
	Rect2(14, 252, 330, 36),     # floor 1
	Rect2(420, 252, 280, 36),    # floor 2
	Rect2(774, 252, 652, 36),    # floor 3
	Rect2(150, 200, 84, 14),
	Rect2(360, 196, 64, 14),
	Rect2(520, 178, 84, 14),
	Rect2(660, 140, 76, 14),
	Rect2(716, 196, 64, 14),
	Rect2(840, 200, 96, 14),
	Rect2(980, 160, 100, 14),
	Rect2(1140, 124, 110, 14),
	Rect2(1300, 200, 126, 52),   # raised step
]

const OBJECTS: Array[Rect2] = [
	Rect2(262, 220, 28, 32),
	Rect2(902, 168, 30, 32),
]

# Top edges that get a moss accent.
const MOSS_SPOTS := [Vector2(226, 200), Vector2(596, 178), Vector2(1078, 160), Vector2(1240, 124)]

var _player: Node2D
var _spawn := Vector2.ZERO


func _ready() -> void:
	for r in TERRAIN:
		_make_body(r)
	for r in OBJECTS:
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
	_spawn = _player.global_position
	var cam = _player.get_node_or_null("Camera")
	if cam:
		cam.limit_left = int(bounds.position.x)
		cam.limit_top = int(bounds.position.y)
		cam.limit_right = int(bounds.end.x)
		cam.limit_bottom = int(bounds.end.y)


func _physics_process(_delta: float) -> void:
	# Fell into a pit -> respawn at the start, minus one heart.
	if _player and _player.global_position.y > bounds.end.y + 30.0:
		_player.global_position = _spawn
		_player.velocity = Vector2.ZERO
		var stats = _player.get_node_or_null("Stats")
		if stats:
			stats.take_damage(fall_damage_halves)


# --- Detailed stone drawing -----------------------------------------------

func _draw() -> void:
	for r in TERRAIN:
		_draw_stone(r)
	for spot in MOSS_SPOTS:
		_draw_moss(spot)
	for r in OBJECTS:
		_draw_crate(r)


func _draw_stone(r: Rect2) -> void:
	# Vertical gradient body (top lighter -> bottom darker).
	var h := r.size.y
	draw_rect(r, STONE_MID)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, h * 0.45), STONE_TOP)
	draw_rect(Rect2(r.position.x, r.position.y + h * 0.7, r.size.x, h * 0.3), STONE_LOW)

	# Deterministic speckle texture + cracks (seeded by position so it's stable).
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x * 7.0 + r.position.y * 13.0 + 1.0)
	var count := int(clampf(r.size.x * r.size.y / 90.0, 4.0, 60.0))
	for i in count:
		var px := r.position.x + rng.randf() * r.size.x
		var py := r.position.y + rng.randf() * r.size.y
		var c := SPECK_LIGHT if rng.randf() > 0.5 else SPECK_DARK
		draw_rect(Rect2(px, py, 1.0, 1.0), c)
	var cracks := int(clampf(r.size.x / 90.0, 1.0, 5.0))
	for i in cracks:
		var sx := r.position.x + rng.randf() * r.size.x
		var sy := r.position.y + 4.0 + rng.randf() * (r.size.y - 6.0)
		var seg := Vector2(sx, sy)
		for j in 3:
			var nxt := seg + Vector2(rng.randf_range(-6.0, 6.0), rng.randf_range(2.0, 6.0))
			draw_line(seg, nxt, STONE_EDGE, 1.0)
			seg = nxt

	# Lit top edge + face band, dark side bevels + bottom shadow.
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2.0), STONE_LIP)
	draw_rect(Rect2(r.position.x, r.position.y + 2.0, r.size.x, 2.0), STONE_FACE)
	draw_rect(Rect2(r.position.x, r.position.y, 1.5, r.size.y), STONE_EDGE)
	draw_rect(Rect2(r.end.x - 1.5, r.position.y, 1.5, r.size.y), STONE_EDGE)
	draw_rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 2.0), STONE_EDGE)


func _draw_moss(top_center: Vector2) -> void:
	# A little clump of glowing moss on a ledge edge.
	draw_rect(Rect2(top_center.x - 5.0, top_center.y - 1.0, 10.0, 2.0), MOSS)
	draw_rect(Rect2(top_center.x - 3.0, top_center.y - 3.0, 2.0, 2.0), MOSS * Color(1, 1, 1, 0.7))
	draw_rect(Rect2(top_center.x + 2.0, top_center.y - 2.0, 2.0, 1.0), MOSS * Color(1, 1, 1, 0.7))


func _draw_crate(r: Rect2) -> void:
	draw_rect(r, CRATE)
	# plank shading
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3.0), CRATE_LIP)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.5 - 1.0, r.size.x, 1.5), CRATE_DK)
	draw_rect(Rect2(r.position.x, r.end.y - 3.0, r.size.x, 3.0), CRATE_DK)
	# frame edges + corner bolts
	draw_rect(Rect2(r.position.x, r.position.y, 2.0, r.size.y), CRATE_DK)
	draw_rect(Rect2(r.end.x - 2.0, r.position.y, 2.0, r.size.y), CRATE_DK)
	for corner in [r.position + Vector2(2, 2), Vector2(r.end.x - 4, r.position.y + 2),
			Vector2(r.position.x + 2, r.end.y - 4), r.end - Vector2(4, 4)]:
		draw_rect(Rect2(corner.x, corner.y, 2.0, 2.0), CRATE_BOLT)
