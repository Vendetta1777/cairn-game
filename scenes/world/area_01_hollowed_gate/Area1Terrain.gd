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
# Richer stone/rock palette.
const ROCK_A := Color(0.12, 0.14, 0.19)
const ROCK_B := Color(0.16, 0.185, 0.245)
const STONE_DEEP := Color(0.045, 0.052, 0.08)
const RIM := Color(0.3, 0.35, 0.46)
const RIM_HI := Color(0.42, 0.48, 0.6)
const MOSS_D := Color(0.22, 0.46, 0.4)
const MOSS_L := Color(0.42, 0.8, 0.62)
const ROOT := Color(0.07, 0.11, 0.09)
const STAL := Color(0.1, 0.115, 0.16)
const STAL_HI := Color(0.2, 0.23, 0.31)
const CRATE := Color(0.3, 0.21, 0.13)
const CRATE_DK := Color(0.2, 0.13, 0.08)
const CRATE_LIP := Color(0.46, 0.34, 0.21)
const CRATE_BOLT := Color(0.55, 0.5, 0.42)

@export var bounds := Rect2(0, 0, 3700, 288)
@export var fall_damage_halves := 2   # one full heart when you fall in a pit

# Paced left->right: a long SAFE intro floor (story, no pits/enemies), then
# pits + platforming only once the player has learned the ropes.
# A learning cave: each section teaches ONE new mechanic, in order. The pits
# between sections are bottomless (a miss = a fall) and lined with spikes. Moving
# platforms live ONLY in open pits with no static platform in their path, so they
# never clip a fixed ledge.
const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 3700, 14),        # ceiling
	Rect2(0, 0, 14, 288),         # left wall
	Rect2(3686, 0, 14, 288),      # right wall

	# S1 — THE WAKING (move + jump): safe ground, gentle hops
	Rect2(14, 252, 686, 36),      # x14..700
	Rect2(300, 210, 110, 16),     # gentle hop
	Rect2(470, 180, 100, 16),     # higher hop

	# S2 — THE ROOST (combat: bats)
	Rect2(760, 252, 560, 36),     # x760..1320
	Rect2(930, 205, 90, 16),
	Rect2(1130, 198, 90, 16),

	# S3 — THE GAPS (precise jumps over spikes): pit 1380..1900
	Rect2(1320, 252, 60, 36),     # entry ledge (checkpoint) x1320..1380
	Rect2(1410, 222, 72, 14),     # hop 1
	Rect2(1540, 206, 66, 14),     # hop 2
	Rect2(1670, 222, 66, 14),     # hop 3
	Rect2(1800, 210, 72, 14),     # hop 4
	Rect2(1900, 252, 90, 36),     # landing x1900..1990

	# S4 — THE TIDES (moving platforms): pit 1990..2480, movers in Area1.tscn
	Rect2(2240, 205, 80, 14),     # mid-pit rest (sits BETWEEN the two movers)
	Rect2(2480, 252, 110, 36),    # landing x2480..2590

	# S5 — THE ASCENT (wall jump): pit 2590..2900 with a climb-only chimney
	Rect2(2624, 230, 56, 14),     # stepping stone over the pit
	Rect2(2700, 238, 96, 14),     # chimney base (jump to it, then climb)
	Rect2(2706, 120, 14, 70),     # left wall  (y120..190)
	Rect2(2782, 120, 14, 70),     # right wall
	Rect2(2796, 124, 110, 16),    # exit ledge -> drop into the arena

	# S6 — THE BROOD (boss arena + gate + threshold)
	Rect2(2900, 252, 786, 36),    # x2900..3686
]

const OBJECTS: Array[Rect2] = [
	Rect2(230, 220, 28, 32),      # S1 crate
	Rect2(1020, 220, 28, 32),     # S2 crate
]

# Spike hazards lining the section pits — a fall hurts before it respawns you.
const HAZARDS: Array[Rect2] = [
	Rect2(1380, 262, 520, 26),    # S3 — under the gap jumps
	Rect2(1990, 262, 490, 26),    # S4 — under the moving platforms
	Rect2(2590, 262, 310, 26),    # S5 — under the chimney climb
]
const SPIKE := Color(0.56, 0.59, 0.68)
const SPIKE_DK := Color(0.28, 0.3, 0.38)

# Top edges that get a moss accent.
const MOSS_SPOTS := [Vector2(355, 198), Vector2(975, 193), Vector2(1575, 194), Vector2(2850, 112)]

var _player: Node2D
var _spawn := Vector2.ZERO


func _ready() -> void:
	for r in TERRAIN:
		_make_body(r)
	for r in OBJECTS:
		_make_body(r)
	for r in HAZARDS:
		_make_hazard(r)
	queue_redraw()
	call_deferred("_setup_player")


func _make_hazard(r: Rect2) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2   # player hurtbox
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	cs.position = r.position + r.size * 0.5
	a.add_child(cs)
	add_child(a)
	a.area_entered.connect(_on_hazard_touched)


func _on_hazard_touched(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player") and b.has_method("receive_attack"):
		b.receive_attack(null, 1)   # half a heart, with i-frames


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
	var stats = _player.get_node_or_null("Stats")
	if stats:
		stats.died.connect(_on_player_died)
	var cam = _player.get_node_or_null("Camera")
	if cam:
		cam.limit_left = int(bounds.position.x)
		cam.limit_top = int(bounds.position.y)
		cam.limit_right = int(bounds.end.x)
		cam.limit_bottom = int(bounds.end.y)


## Health hit 0 -> die: respawn at the checkpoint (or start) with full health.
func _on_player_died() -> void:
	if _player == null:
		return
	_player.global_position = GameManager.get_respawn(_spawn)
	_player.velocity = Vector2.ZERO
	var stats = _player.get_node_or_null("Stats")
	if stats:
		stats.heal(stats.max_health)   # full refill
		stats.refill_shadow()
	GameManager.hitstop(0.16)
	var cam = _player.get_node_or_null("Camera")
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.7)


func _physics_process(_delta: float) -> void:
	# Fell into a pit -> respawn at the last checkpoint (or start), minus a heart.
	if _player and _player.global_position.y > bounds.end.y + 30.0:
		_player.global_position = GameManager.get_respawn(_spawn)
		_player.velocity = Vector2.ZERO
		var stats = _player.get_node_or_null("Stats")
		if stats:
			stats.take_damage(fall_damage_halves)


# --- Detailed stone drawing -----------------------------------------------

func _draw() -> void:
	for r in TERRAIN:
		_draw_stone(r)
	_draw_ceiling()
	for r in OBJECTS:
		_draw_crate(r)
	for r in HAZARDS:
		_draw_spikes(r)


func _is_ceiling(r: Rect2) -> bool:
	return r.position.y <= 0.0 and r.size.x > 400.0


func _draw_spikes(r: Rect2) -> void:
	# Short spikes at the bottom of the (taller, invisible) hazard zone.
	var base_y := r.end.y
	var tip_y := r.end.y - 11.0
	var x := r.position.x
	while x < r.end.x - 1.0:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, base_y), Vector2(x + 8.0, base_y), Vector2(x + 4.0, tip_y)]), SPIKE)
		draw_line(Vector2(x + 4.0, tip_y), Vector2(x + 6.0, base_y), SPIKE_DK, 1.0)
		x += 8.0


## A platform/floor as a chunky rock ledge: layered body, bumpy rock rim, moss
## on top, hanging roots underneath. Thin platforms get a deeper visual body.
func _draw_stone(r: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x * 7.0 + r.position.y * 13.0 + 1.0)
	var vis_h: float = maxf(r.size.y, 30.0)
	var body := Rect2(r.position.x, r.position.y, r.size.x, vis_h)

	draw_rect(body, ROCK_A)
	draw_rect(Rect2(body.position.x, body.position.y, body.size.x, vis_h * 0.42), ROCK_B)
	draw_rect(Rect2(body.position.x, body.position.y + vis_h * 0.74, body.size.x, vis_h * 0.26), STONE_DEEP)

	var blobs := int(clampf(r.size.x * vis_h / 240.0, 3.0, 60.0))
	for i in blobs:
		var bx := body.position.x + rng.randf() * r.size.x
		var by := r.position.y + 5.0 + rng.randf() * (vis_h - 7.0)
		draw_circle(Vector2(bx, by), rng.randf_range(3.0, 7.0), STONE_DEEP if rng.randf() > 0.55 else ROCK_B)
	for i in blobs:
		var px := body.position.x + rng.randf() * r.size.x
		var py := r.position.y + rng.randf() * vis_h
		draw_rect(Rect2(px, py, 1.0, 1.0), SPECK_LIGHT if rng.randf() > 0.55 else SPECK_DARK)

	if _is_ceiling(r):
		return

	# Bumpy rock rim along the top.
	var x := r.position.x
	while x < r.end.x:
		var rr := rng.randf_range(2.6, 4.2)
		draw_circle(Vector2(x, r.position.y + 1.5), rr, RIM)
		draw_circle(Vector2(x, r.position.y + 0.5), rr * 0.55, RIM_HI)
		x += 4.6

	# Moss/grass tufts over the front edge.
	x = r.position.x + 6.0 + rng.randf() * 12.0
	while x < r.end.x - 4.0:
		draw_rect(Rect2(x - 4.0, r.position.y - 1.0, 9.0, 3.0), MOSS_D)
		draw_rect(Rect2(x - 2.0, r.position.y - 2.0, 5.0, 2.0), MOSS_L)
		draw_line(Vector2(x - 1.0, r.position.y - 1.0), Vector2(x - 2.0, r.position.y - 6.0), MOSS_L, 1.0)
		draw_line(Vector2(x + 2.0, r.position.y - 1.0), Vector2(x + 2.0, r.position.y - 5.0), MOSS_D, 1.0)
		x += rng.randf_range(46.0, 90.0)

	# Roots hanging from the underside.
	x = r.position.x + 10.0 + rng.randf() * 14.0
	while x < r.end.x - 6.0:
		var seg := Vector2(x, body.position.y + vis_h - 1.0)
		var rlen := rng.randf_range(6.0, 13.0)
		for j in 2:
			var nxt := seg + Vector2(rng.randf_range(-2.5, 2.5), rlen * 0.5)
			draw_line(seg, nxt, ROOT, rng.randf_range(1.0, 2.0))
			seg = nxt
		x += rng.randf_range(34.0, 72.0)

	draw_rect(Rect2(body.position.x, body.position.y, 1.5, vis_h), STONE_DEEP)
	draw_rect(Rect2(body.end.x - 1.5, body.position.y, 1.5, vis_h), STONE_DEEP)


## Organic cave ceiling — the underside UNDULATES (curves down and back up) like a
## real cave roof, instead of a straight line. Shared so vines hang from the curve.
func ceiling_y(x: float) -> float:
	return 42.0 + sin(x * 0.013) * 11.0 + sin(x * 0.029 + 1.0) * 6.0 + sin(x * 0.061 + 2.0) * 3.0


func _draw_ceiling() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var w := bounds.size.x

	# Filled rock with a wavy bottom edge.
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(w, 0)])
	var x := w
	while x >= 0.0:
		pts.append(Vector2(x, ceiling_y(x)))
		x -= 6.0
	draw_colored_polygon(pts, ROCK_A)
	# Lighter upper band (follows the curve, thinner).
	var pts2 := PackedVector2Array([Vector2(0, 0), Vector2(w, 0)])
	x = w
	while x >= 0.0:
		pts2.append(Vector2(x, ceiling_y(x) * 0.45))
		x -= 6.0
	draw_colored_polygon(pts2, ROCK_B)
	# Texture blobs inside the rock.
	for i in int(w / 13.0):
		var bx := rng.randf() * w
		var by := rng.randf() * (ceiling_y(bx) - 4.0)
		draw_circle(Vector2(bx, by), rng.randf_range(3.0, 7.0), STONE_DEEP if rng.randf() > 0.55 else ROCK_B)

	# Bumpy rim, moss tufts, and stalactites following the curve.
	x = 0.0
	while x < w:
		draw_circle(Vector2(x, ceiling_y(x) - 1.0), rng.randf_range(2.6, 4.2), RIM)
		x += 4.6
	x = 14.0
	while x < w - 6.0:
		var cy := ceiling_y(x)
		draw_rect(Rect2(x - 4.0, cy - 2.0, 9.0, 3.0), MOSS_D)
		draw_rect(Rect2(x - 2.0, cy, 5.0, 2.0), MOSS_L)
		x += rng.randf_range(70.0, 130.0)
	x = 18.0
	while x < w - 18.0:
		if rng.randf() > 0.32:
			var cy := ceiling_y(x)
			var sw := rng.randf_range(5.0, 14.0)
			var slen := rng.randf_range(10.0, 48.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - sw, cy), Vector2(x + sw, cy), Vector2(x, cy + slen)]), STAL)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - sw * 0.4, cy), Vector2(x + sw * 0.2, cy), Vector2(x, cy + slen * 0.65)]), STAL_HI)
		x += rng.randf_range(20.0, 38.0)


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
