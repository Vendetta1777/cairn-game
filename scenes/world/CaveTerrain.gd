extends Node2D
class_name CaveTerrain
## Cairn — shared cave-terrain base for every level. Data-driven: a subclass
## supplies its layout (solids / objects / hazards / moss) and bounds; this base
## generates the collision bodies, draws detailed cave stone + an organic
## ceiling, clamps the player camera, handles fall-into-a-pit respawn, and
## exposes the solids for the map. New levels = a tiny subclass with new arrays.

# Stone palette (dark cave, cool) — shared so every level reads as one world.
const ROCK_A := Color(0.12, 0.14, 0.19)
const ROCK_B := Color(0.16, 0.185, 0.245)
const STONE_DEEP := Color(0.045, 0.052, 0.08)
const SPECK_LIGHT := Color(0.24, 0.27, 0.35)
const SPECK_DARK := Color(0.05, 0.05, 0.08)
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
const SPIKE := Color(0.56, 0.59, 0.68)
const SPIKE_DK := Color(0.28, 0.3, 0.38)

@export var bounds := Rect2(0, 0, 3700, 288)
@export var fall_damage_halves := 2
@export var ceiling_seed := 99

var _player: Node2D
var _spawn := Vector2.ZERO


# --- Subclasses override these to define the level ---------------------------
func solids() -> Array[Rect2]:
	return []

func objects() -> Array[Rect2]:
	return []

func hazards() -> Array[Rect2]:
	return []

func moss_spots() -> Array:
	return []


func _ready() -> void:
	add_to_group("terrain")
	for r in solids():
		_make_body(r)
	for r in objects():
		_make_body(r)
	for r in hazards():
		_make_hazard(r)
	queue_redraw()
	call_deferred("_setup_player")


## Solids + objects, for the map overlay to draw the level silhouette.
func get_solids() -> Array[Rect2]:
	var out: Array[Rect2] = []
	out.append_array(solids())
	out.append_array(objects())
	return out


func _make_hazard(r: Rect2) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
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
		b.receive_attack(null, 1)


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


## Health hit 0 -> die: respawn at the checkpoint (or start) at full health, and
## reset any active boss fight so it's a clean retry.
func _on_player_died() -> void:
	if _player == null:
		return
	_player.global_position = GameManager.get_respawn(_spawn)
	_player.velocity = Vector2.ZERO
	var stats = _player.get_node_or_null("Stats")
	if stats:
		stats.heal(stats.max_health)
		stats.refill_shadow()
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss.has_method("reset_fight"):
			boss.reset_fight()
	GameManager.hitstop(0.16)
	var cam = _player.get_node_or_null("Camera")
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.7)


func _physics_process(_delta: float) -> void:
	if _player and _player.global_position.y > bounds.end.y + 30.0:
		_player.global_position = GameManager.get_respawn(_spawn)
		_player.velocity = Vector2.ZERO
		var stats = _player.get_node_or_null("Stats")
		if stats:
			stats.take_damage(fall_damage_halves)


# --- Drawing ----------------------------------------------------------------

func _draw() -> void:
	for r in solids():
		_draw_stone(r)
	_draw_ceiling()
	for r in objects():
		_draw_crate(r)
	for r in hazards():
		_draw_spikes(r)


func _is_ceiling(r: Rect2) -> bool:
	return r.position.y <= 0.0 and r.size.x > 400.0


func _draw_spikes(r: Rect2) -> void:
	var base_y := r.end.y
	var tip_y := r.end.y - 11.0
	var x := r.position.x
	while x < r.end.x - 1.0:
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, base_y), Vector2(x + 8.0, base_y), Vector2(x + 4.0, tip_y)]), SPIKE)
		draw_line(Vector2(x + 4.0, tip_y), Vector2(x + 6.0, base_y), SPIKE_DK, 1.0)
		x += 8.0


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

	var x := r.position.x
	while x < r.end.x:
		var rr := rng.randf_range(2.6, 4.2)
		draw_circle(Vector2(x, r.position.y + 1.5), rr, RIM)
		draw_circle(Vector2(x, r.position.y + 0.5), rr * 0.55, RIM_HI)
		x += 4.6

	x = r.position.x + 6.0 + rng.randf() * 12.0
	while x < r.end.x - 4.0:
		draw_rect(Rect2(x - 4.0, r.position.y - 1.0, 9.0, 3.0), MOSS_D)
		draw_rect(Rect2(x - 2.0, r.position.y - 2.0, 5.0, 2.0), MOSS_L)
		draw_line(Vector2(x - 1.0, r.position.y - 1.0), Vector2(x - 2.0, r.position.y - 6.0), MOSS_L, 1.0)
		draw_line(Vector2(x + 2.0, r.position.y - 1.0), Vector2(x + 2.0, r.position.y - 5.0), MOSS_D, 1.0)
		x += rng.randf_range(46.0, 90.0)

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


## Organic cave ceiling. Subclasses may override ceiling_y for a different roof.
func ceiling_y(x: float) -> float:
	return 42.0 + sin(x * 0.013) * 11.0 + sin(x * 0.029 + 1.0) * 6.0 + sin(x * 0.061 + 2.0) * 3.0


func _draw_ceiling() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = ceiling_seed
	var w := bounds.size.x

	var pts := PackedVector2Array([Vector2(0, 0), Vector2(w, 0)])
	var x := w
	while x >= 0.0:
		pts.append(Vector2(x, ceiling_y(x)))
		x -= 6.0
	draw_colored_polygon(pts, ROCK_A)
	var pts2 := PackedVector2Array([Vector2(0, 0), Vector2(w, 0)])
	x = w
	while x >= 0.0:
		pts2.append(Vector2(x, ceiling_y(x) * 0.45))
		x -= 6.0
	draw_colored_polygon(pts2, ROCK_B)
	for i in int(w / 13.0):
		var bx := rng.randf() * w
		var by := rng.randf() * (ceiling_y(bx) - 4.0)
		draw_circle(Vector2(bx, by), rng.randf_range(3.0, 7.0), STONE_DEEP if rng.randf() > 0.55 else ROCK_B)

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
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3.0), CRATE_LIP)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.5 - 1.0, r.size.x, 1.5), CRATE_DK)
	draw_rect(Rect2(r.position.x, r.end.y - 3.0, r.size.x, 3.0), CRATE_DK)
	draw_rect(Rect2(r.position.x, r.position.y, 2.0, r.size.y), CRATE_DK)
	draw_rect(Rect2(r.end.x - 2.0, r.position.y, 2.0, r.size.y), CRATE_DK)
	for corner in [r.position + Vector2(2, 2), Vector2(r.end.x - 4, r.position.y + 2),
			Vector2(r.position.x + 2, r.end.y - 4), r.end - Vector2(4, 4)]:
		draw_rect(Rect2(corner.x, corner.y, 2.0, 2.0), CRATE_BOLT)
