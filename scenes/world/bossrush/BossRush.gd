extends Node2D
## Cairn — BOSS RUSH (unlocked by beating the game): all five guardians, back
## to back, one arena, one clock. Half a heal between fights. Death ends the
## run. Nothing here writes to the save (GameManager.boss_rush_mode).

const ROSTER := [
	["res://scenes/enemies/boss/MotherBat.tscn", "THE BROOD MOTHER"],
	["res://scenes/enemies/boss/AshenWarden.tscn", "THE ASHEN WARDEN"],
	["res://scenes/enemies/boss/PaleLibrarian.tscn", "THE PALE LIBRARIAN"],
	["res://scenes/enemies/boss/BuriedKing.tscn", "THE BURIED KING"],
	["res://scenes/enemies/boss/PaleSovereign.tscn", "THE PALE SOVEREIGN"],
]

const ARENA_L := 30.0
const ARENA_R := 930.0
const FLOOR_Y := 252.0

var _idx := -1
var _clock := 0.0
var _running := false
var _current_boss: Node

@onready var _clock_label: Label = $RushHUD/Clock


func _ready() -> void:
	GameManager.boss_rush_mode = true
	GameManager.current_area_name = "THE GAUNTLET"
	GameManager.current_area_id = "boss_rush"
	GameManager.has_checkpoint = false
	AudioManager.play_music("boss")
	QuestTracker.begin_area("Five guardians. One clock. Begin")
	QuestTracker.boss_defeated.connect(_on_boss_down)
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var stats = player.get_node_or_null("Stats")
		if stats:
			stats.died.connect(_on_player_died)
	_next_boss()


func _exit_tree() -> void:
	GameManager.boss_rush_mode = false


func _process(delta: float) -> void:
	if _running:
		_clock += delta
	_clock_label.text = "%d:%05.2f" % [int(_clock) / 60, fmod(_clock, 60.0)]


func _next_boss() -> void:
	_idx += 1
	if _idx >= ROSTER.size():
		_finish()
		return
	_running = true
	var packed: PackedScene = load(ROSTER[_idx][0])
	_current_boss = packed.instantiate()
	# Aim every boss's arena exports at THIS hall.
	for prop in ["arena_left", "arena_right", "floor_y", "throne_x", "home_y", "ceiling_y_pos"]:
		if prop in _current_boss:
			match prop:
				"arena_left": _current_boss.arena_left = ARENA_L
				"arena_right": _current_boss.arena_right = ARENA_R
				"floor_y": _current_boss.floor_y = FLOOR_Y
				"throne_x": _current_boss.throne_x = 480.0
				"home_y": _current_boss.home_y = 110.0
				"ceiling_y_pos": _current_boss.ceiling_y_pos = 60.0
	add_child(_current_boss)
	_current_boss.global_position = Vector2(640, 110 if _idx in [0, 2] else 215)
	for bar in get_tree().get_nodes_in_group("boss_bar"):
		if bar.has_method("bind"):
			bar.bind(_current_boss, "%d / %d   %s" % [_idx + 1, ROSTER.size(), ROSTER[_idx][1]])
	if _current_boss.has_method("engage"):
		_current_boss.engage()
	QuestTracker.set_objective(ROSTER[_idx][1])


func _on_boss_down(_id: String) -> void:
	_running = false
	# Clear leftovers + half-heal, then the next one comes.
	for n in get_tree().get_nodes_in_group("boss_projectile"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("summoned_bat"):
		n.queue_free()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var stats = player.get_node_or_null("Stats")
		if stats:
			stats.heal(stats.max_health / 2)
			stats.refill_shadow()
	get_tree().create_timer(2.2).timeout.connect(_next_boss)


func _on_player_died() -> void:
	_running = false
	QuestTracker.set_objective("The gauntlet keeps you. (returning to title)")
	get_tree().create_timer(2.5).timeout.connect(func():
		get_tree().paused = false
		SceneFlow.travel("res://scenes/ui/TitleScreen.tscn", "up"))


func _finish() -> void:
	var banner := get_tree().get_first_node_in_group("location_title")
	if banner and banner.has_method("reveal"):
		banner.reveal("THE GAUNTLET FALLS", "%d:%05.2f" % [int(_clock) / 60, fmod(_clock, 60.0)])
	QuestTracker.set_objective("All five. %d:%05.2f. The title awaits (E at the portal of light)" % [int(_clock) / 60, fmod(_clock, 60.0)])
	get_tree().create_timer(6.0).timeout.connect(func():
		SceneFlow.travel("res://scenes/ui/TitleScreen.tscn", "up"))
