extends Node2D
## Cairn — the Hollowed Gate itself: the great warded door the player must reach.
## Sealed (runes lit, doors shut) until its boss is defeated; then the ward
## shatters, the doors grind apart, and the gate becomes the area exit. Walking
## into the open threshold completes Area 1.
##
## Drawn procedurally so it needs no art: a carved arch, two stone leaves, and a
## breathing ward sigil between them.

@export var boss_id: String = "hollow_warden"
@export var area_id: String = "hollowed_gate"
@export var open_objective: String = "Enter the Hollowed Gate"

var _sealed := true
var _open_amt := 0.0     ## 0 shut .. 1 fully parted
var _t := 0.0

@onready var _ward: PointLight2D = $WardLight
@onready var _zone: Area2D = $Threshold

var _blocker: StaticBody2D


func _ready() -> void:
	add_to_group("exit")   # for the map overlay
	QuestTracker.boss_defeated.connect(_on_boss_defeated)
	_zone.area_entered.connect(_on_area)
	_make_blocker()
	# Already cleared (this session OR a saved one)? Start open.
	if QuestTracker.has_flag("boss_%s_dead" % boss_id) or PlayerProgress.has_flag("boss_%s_dead" % boss_id):
		_sealed = false
		_open_amt = 1.0
		_ward.energy = 0.0
		_remove_blocker()
		QuestTracker.set_objective(open_objective)
	set_process(true)


## A solid wall in the doorway so the player CANNOT pass until the ward breaks.
func _make_blocker() -> void:
	_blocker = StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 156)
	cs.shape = shape
	cs.position = Vector2(0, -78)
	_blocker.add_child(cs)
	add_child(_blocker)


func _remove_blocker() -> void:
	if _blocker:
		_blocker.queue_free()
		_blocker = null


func _process(delta: float) -> void:
	_t += delta
	if _sealed:
		# Ward breathes ominously.
		_ward.energy = 0.9 + sin(_t * 2.2) * 0.35
	else:
		_open_amt = move_toward(_open_amt, 1.0, delta * 0.55)
	queue_redraw()


func _on_boss_defeated(id: String) -> void:
	if id != boss_id or not _sealed:
		return
	_sealed = false
	_remove_blocker()
	QuestTracker.set_objective(open_objective)
	# Ward shatters: bright flash then dark.
	_ward.color = Color(0.8, 0.85, 1.0)
	var tw := create_tween()
	tw.tween_property(_ward, "energy", 2.6, 0.15)
	tw.tween_property(_ward, "energy", 0.0, 1.2)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.7)


func _on_area(area: Area2D) -> void:
	if _sealed or _open_amt < 0.85:
		return
	var body := area.get_parent()
	if body and body.is_in_group("player"):
		QuestTracker.complete_area(area_id)


func _draw() -> void:
	# Arch + frame (local origin sits at the floor, centre of the doorway).
	var W := 66.0    # half-width of the opening
	var H := 150.0   # height of the doorway
	var frame := Color(0.14, 0.12, 0.18)
	var frame_lit := Color(0.3, 0.26, 0.36)
	# Outer pillars.
	draw_rect(Rect2(-W - 16, -H, 16, H), frame)
	draw_rect(Rect2(W, -H, 16, H), frame)
	draw_rect(Rect2(-W - 16, -H - 18, (W + 16) * 2.0, 18), frame)
	# Arch keystone hint.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, -H - 18), Vector2(14, -H - 18), Vector2(8, -H - 34), Vector2(-8, -H - 34)
	]), frame_lit)
	# Dark recess behind the doors.
	draw_rect(Rect2(-W, -H, W * 2.0, H), Color(0.02, 0.02, 0.04))

	# The two stone leaves, parting by _open_amt.
	var slide := _open_amt * (W - 4.0)
	var leaf := Color(0.2, 0.18, 0.24)
	var leaf_edge := Color(0.34, 0.3, 0.4)
	# Left leaf.
	draw_rect(Rect2(-W - slide, -H, W, H), leaf)
	draw_line(Vector2(-2 - slide, -H), Vector2(-2 - slide, 0), leaf_edge, 2.0)
	# Right leaf.
	draw_rect(Rect2(0 + slide, -H, W, H), leaf)
	draw_line(Vector2(2 + slide, -H), Vector2(2 + slide, 0), leaf_edge, 2.0)
	# Horizontal banding on the leaves for carved-stone feel.
	for i in range(1, 5):
		var yy := -H + H * (i / 5.0)
		draw_line(Vector2(-W - slide, yy), Vector2(-slide, yy), Color(0.12, 0.1, 0.15, 0.7), 1.0)
		draw_line(Vector2(slide, yy), Vector2(W + slide, yy), Color(0.12, 0.1, 0.15, 0.7), 1.0)

	# Ward sigil over the seam — only while sealed (or fading right after).
	if _sealed:
		var pulse := 0.6 + sin(_t * 2.2) * 0.4
		var c := Color(0.55, 0.7, 1.0, pulse)
		var cy := -H * 0.55
		var r := 18.0
		# A ringed rune.
		draw_arc(Vector2(0, cy), r, 0, TAU, 24, c, 2.0)
		draw_arc(Vector2(0, cy), r * 0.55, 0, TAU, 16, c, 1.5)
		for k in range(6):
			var ang := TAU * k / 6.0 + _t * 0.4
			var p := Vector2(cos(ang), sin(ang)) * r
			draw_line(Vector2(0, cy), Vector2(0, cy) + p, Color(c.r, c.g, c.b, pulse * 0.5), 1.0)
