extends Node2D
## Cairn — the way down out of an area: a CAVE PASSAGE (a jagged chasm-mouth in
## the rock, not a door). Blocked by rubble + a ward until the area's boss falls;
## then the rubble clears, glowing crystals brighten, and a cold draft of motes
## sinks into the dark. Stand in it and press interact to descend to the next
## level. Drawn procedurally — no art needed.

@export var boss_id: String = "mother_bat"
@export var area_id: String = "hollowed_gate"
@export var open_objective: String = "Descend — press E at the chasm"
@export_file("*.tscn") var next_scene: String = ""
## A passage that was never warded (no boss guards it) — open from the start.
@export var starts_open: bool = false

var _sealed := true
var _open_amt := 0.0     ## 0 shut .. 1 fully open
var _t := 0.0
var _player_in := false

@onready var _glow: PointLight2D = $WardLight
@onready var _zone: Area2D = $Threshold
@onready var _prompt: Control = $Prompt

var _blocker: StaticBody2D


func _ready() -> void:
	add_to_group("exit")
	QuestTracker.boss_defeated.connect(_on_boss_defeated)
	_zone.area_entered.connect(_on_enter)
	_zone.area_exited.connect(_on_exit)
	_make_blocker()
	_prompt.modulate.a = 0.0
	# Already cleared (this session OR a saved one), or never warded? Start open.
	if starts_open or QuestTracker.has_flag("boss_%s_dead" % boss_id) \
			or PlayerProgress.has_flag("boss_%s_dead" % boss_id):
		_sealed = false
		_open_amt = 1.0
		_remove_blocker()
		QuestTracker.set_objective(open_objective)
	set_process(true)


## A solid wall in the passage so the player CANNOT pass until the boss falls.
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
		_glow.energy = 0.7 + sin(_t * 2.2) * 0.25
		_glow.color = Color(0.55, 0.7, 1.0)
	else:
		_open_amt = move_toward(_open_amt, 1.0, delta * 0.6)
		_glow.energy = 1.0 + sin(_t * 1.6) * 0.3
		_glow.color = Color(0.5, 0.85, 0.95)
	queue_redraw()

	# Descend on interact when open and standing in the chasm mouth.
	if not _sealed and _open_amt > 0.85 and _player_in \
			and Input.is_action_just_pressed("interact") and next_scene != "":
		_descend()


func _on_boss_defeated(id: String) -> void:
	if id != boss_id or not _sealed:
		return
	_sealed = false
	_remove_blocker()
	QuestTracker.set_objective(open_objective)
	AudioManager.play_at("door", global_position, -4.0)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.6)


func _on_enter(area: Area2D) -> void:
	if area.get_parent() and area.get_parent().is_in_group("player"):
		_player_in = true
		if not _sealed:
			create_tween().tween_property(_prompt, "modulate:a", 1.0, 0.2)


func _on_exit(area: Area2D) -> void:
	if area.get_parent() and area.get_parent().is_in_group("player"):
		_player_in = false
		create_tween().tween_property(_prompt, "modulate:a", 0.0, 0.2)


func _descend() -> void:
	# The descent IS the completion — go straight down (no full-screen card to
	# flash for a frame before the scene swaps).
	QuestTracker.set_flag("area_%s_done" % area_id, true)
	SaveManager.autosave()
	SceneFlow.travel(next_scene, "down")


func _draw() -> void:
	# A jagged chasm-mouth carved in the rock. Origin sits at the floor, centred.
	var W := 60.0
	var H := 150.0
	var rock := Color(0.13, 0.12, 0.17)
	var rock_lip := Color(0.22, 0.21, 0.28)
	var deep := Color(0.015, 0.02, 0.035)

	# Rocky frame (left and right jagged jambs + a lintel of stone).
	var left := PackedVector2Array([
		Vector2(-W - 22, 6), Vector2(-W - 4, 6), Vector2(-W, -H * 0.4),
		Vector2(-W - 6, -H * 0.75), Vector2(-W + 2, -H), Vector2(-W - 26, -H - 8), Vector2(-W - 26, 6)])
	var right := PackedVector2Array([
		Vector2(W + 22, 6), Vector2(W + 4, 6), Vector2(W, -H * 0.4),
		Vector2(W + 6, -H * 0.75), Vector2(W - 2, -H), Vector2(W + 26, -H - 8), Vector2(W + 26, 6)])
	# Dark interior of the chasm.
	draw_rect(Rect2(-W, -H, W * 2.0, H + 6.0), deep)
	draw_colored_polygon(left, rock)
	draw_colored_polygon(right, rock)
	# Jagged lintel across the top.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-W - 26, -H - 8), Vector2(0, -H - 22), Vector2(W + 26, -H - 8),
		Vector2(W + 26, -H + 16), Vector2(0, -H + 4), Vector2(-W - 26, -H + 16)]), rock)
	# Lip highlights.
	draw_polyline(PackedVector2Array([Vector2(-W, -H * 0.4), Vector2(-W + 2, -H)]), rock_lip, 1.5)
	draw_polyline(PackedVector2Array([Vector2(W, -H * 0.4), Vector2(W - 2, -H)]), rock_lip, 1.5)

	if _sealed:
		# Rubble pile + a faint ward across the mouth.
		_draw_rubble(W, deep, rock, rock_lip)
		var pulse := 0.5 + sin(_t * 2.2) * 0.4
		draw_arc(Vector2(0, -H * 0.55), 16.0, 0, TAU, 22, Color(0.55, 0.7, 1.0, pulse), 1.5)
		draw_line(Vector2(0, -H * 0.55 - 14), Vector2(0, -H * 0.55 + 14), Color(0.6, 0.74, 1.0, pulse), 1.5)
	else:
		# Open: crystals along the rim glow, and motes drift DOWN into the dark.
		var g := _open_amt
		for cx in [-W + 6, -W * 0.4, W * 0.4, W - 6]:
			var cy := -H * 0.5 + sin(cx) * 18.0
			var cc := Color(0.4, 0.85, 0.95, 0.9 * g)
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, cy - 6), Vector2(cx + 3, cy), Vector2(cx, cy + 6), Vector2(cx - 3, cy)]), cc)
		for k in range(7):
			var mx := sin(_t * 0.7 + k * 1.4) * W * 0.6
			var my := -H + fmod(_t * 30.0 + k * 22.0, H)   # sink downward
			draw_circle(Vector2(mx, -my * 0.0 + my), 1.4, Color(0.6, 0.9, 1.0, 0.5 * g))


func _draw_rubble(w: float, deep: Color, rock: Color, lip: Color) -> void:
	# A heap of boulders sealing the lower mouth.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	draw_rect(Rect2(-w, -52, w * 2.0, 58), deep)
	var x := -w + 6.0
	while x < w - 6.0:
		var r := rng.randf_range(7.0, 14.0)
		var y := -rng.randf_range(8.0, 46.0)
		draw_circle(Vector2(x, y), r, rock)
		draw_circle(Vector2(x - r * 0.3, y - r * 0.3), r * 0.4, lip)
		x += rng.randf_range(12.0, 22.0)
