extends Control
## Cairn — the Skill Tree screen (GDD Section 9). Three columns (Blade / Shadow /
## Body), ten nodes each, bought with Shards. Keyboard/controller-navigable:
## left/right switch branch, up/down move tier, attack/interact unlocks the
## highlighted node, pause/cancel closes. Pauses the game while open. Effects are
## stored in PlayerProgress and take hold when the player next enters the world,
## so this doubles as the spend-Shards station inside the Sanctum.

signal closed

const Skills = preload("res://scenes/systems/SkillTreeData.gd")
const COL_X := [300.0, 480.0, 660.0]
const ROW_Y0 := 116.0
const ROW_DY := 30.0
const R := 9.0

@onready var _title: Label = $Title
@onready var _info_name: Label = $Info/NodeName
@onready var _info_desc: Label = $Info/NodeDesc
@onready var _info_cost: Label = $Info/NodeCost
@onready var _balance: Label = $Balance

var _open := false
var _branch := 0
var _tier := 0
var _time := 0.0


func _ready() -> void:
	add_to_group("skill_tree")
	visible = false


func is_open() -> bool:
	return _open


func open() -> void:
	_open = true
	visible = true
	get_tree().paused = true
	_refresh()


func close() -> void:
	_open = false
	visible = false
	get_tree().paused = false
	closed.emit()


func _process(delta: float) -> void:
	if _open:
		_time += delta
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("crouch"):
		close()
		get_viewport().set_input_as_handled()
		return
	var moved := false
	if event.is_action_pressed("move_left"):
		_branch = wrapi(_branch - 1, 0, 3); moved = true
	elif event.is_action_pressed("move_right"):
		_branch = wrapi(_branch + 1, 0, 3); moved = true
	elif event.is_action_pressed("move_up"):
		_tier = clampi(_tier - 1, 0, 9); moved = true
	elif event.is_action_pressed("move_down"):
		_tier = clampi(_tier + 1, 0, 9); moved = true
	elif event.is_action_pressed("attack") or event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		_try_unlock()
		get_viewport().set_input_as_handled()
		return
	if moved:
		_refresh()
		get_viewport().set_input_as_handled()


func _current() -> Dictionary:
	return Skills.in_branch(Skills.BRANCHES[_branch])[_tier]


func _try_unlock() -> void:
	var node := _current()
	if PlayerProgress.unlock(node.id):
		AudioManager.ui("skill_buy", -6.0)
		# Little confirm flash handled in _draw via _time; refresh labels.
		_refresh()


func _refresh() -> void:
	_balance.text = "SHARDS  %d" % PlayerProgress.shards
	var node := _current()
	_info_name.text = node.name
	_info_desc.text = node.desc
	var owned: bool = PlayerProgress.is_unlocked(node.id)
	var pre: String = Skills.prereq_of(node)
	if owned:
		_info_cost.text = "OWNED"
		_info_cost.modulate = Color(0.5, 0.85, 0.6)
	elif pre != "" and not PlayerProgress.is_unlocked(pre):
		_info_cost.text = "LOCKED  (needs %s)" % Skills.by_id(pre).name
		_info_cost.modulate = Color(0.7, 0.5, 0.5)
	elif PlayerProgress.shards < int(node.cost):
		_info_cost.text = "COST  %d  (not enough)" % node.cost
		_info_cost.modulate = Color(0.8, 0.6, 0.4)
	else:
		_info_cost.text = "COST  %d   [J] unlock" % node.cost
		_info_cost.modulate = Color(0.7, 0.85, 1.0)


func _draw() -> void:
	# Dim the world behind.
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.02, 0.02, 0.05, 0.86))

	for b in range(3):
		var branch: String = Skills.BRANCHES[b]
		var col: Color = Skills.BRANCH_COLOR[branch]
		var cx: float = COL_X[b]
		# Branch header.
		var nodes := Skills.in_branch(branch)
		# Connecting spine.
		draw_line(Vector2(cx, ROW_Y0), Vector2(cx, ROW_Y0 + 9 * ROW_DY), Color(col.r, col.g, col.b, 0.25), 2.0)
		for t in range(nodes.size()):
			var node: Dictionary = nodes[t]
			var p := Vector2(cx, ROW_Y0 + t * ROW_DY)
			var owned: bool = PlayerProgress.is_unlocked(node.id)
			var avail: bool = PlayerProgress.can_unlock(node.id)
			# Lit spine segment between owned nodes.
			if t > 0 and owned:
				draw_line(Vector2(cx, p.y - ROW_DY), p, col, 2.5)
			var fill := col if owned else Color(0.12, 0.12, 0.16)
			if not owned and avail:
				fill = Color(col.r * 0.4, col.g * 0.4, col.b * 0.4)
			_diamond(p, R, fill)
			# Outline: bright if available, faint if locked.
			var oc := col if (owned or avail) else Color(0.3, 0.3, 0.36)
			_diamond_outline(p, R, oc, 1.5)
			if owned:
				_diamond(p, R * 0.4, Color(1, 1, 1, 0.8))

		# Branch name under the column.
		draw_string(ThemeDB.fallback_font, Vector2(cx - 30, ROW_Y0 - 16),
			Skills.BRANCH_NAME[branch], HORIZONTAL_ALIGNMENT_CENTER, 60, 11, col)

	# Cursor ring around the selected node.
	var sp := Vector2(COL_X[_branch], ROW_Y0 + _tier * ROW_DY)
	var pulse := 2.0 + sin(_time * 6.0) * 1.5
	draw_arc(sp, R + 4.0 + pulse, 0, TAU, 20, Color(1, 1, 1, 0.9), 1.5)


func _diamond(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)


func _diamond_outline(c: Vector2, r: float, col: Color, w: float) -> void:
	draw_polyline(PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0), c + Vector2(0, -r)]), col, w, true)
