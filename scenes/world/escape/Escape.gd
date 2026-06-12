extends Node2D
## Cairn — THE ESCAPE root (Ending A): a two-minute collapse run. The kingdom
## is falling behind you as a wall of dust and stone; debris rains ahead of it;
## the timer is the mountain's patience. Reach the chasm of grey light at the
## far end. Dying restarts the run (the deep is generous exactly once per try).

const ENDING_A_PANELS := [
	{"art": "collapse", "text": "The promise breaks, and Cairn finally finishes falling — all at once, the way it always wanted to.", "hold": 13.0},
	{"art": "collapse", "text": "You run the processional as the columns kneel. The memory echoes do not run. They are already home.", "hold": 13.0},
	{"art": "surface", "text": "Grey daylight. Wind. The first sky the deep has shown anyone in three hundred years.", "hold": 13.0},
	{"art": "crown", "text": "Behind you, the mountain settles over the kingdom like a hand closing. A cairn, at last, in the true sense.", "hold": 13.0},
	{"art": "hollow", "text": "The dead of Cairn keep nothing now — no promise, no king, no grief. You carry all of it, alone, into the morning.", "hold": 13.0},
	{"art": "surface", "text": "THE CAIRN FALLS.    Some endings are mercies.", "hold": 14.0},
]

const TIME_LIMIT := 120.0
const WALL_SPEED := 95.0

var _time_left := TIME_LIMIT
var _wall_x := -160.0
var _running := true
var _quake_t := 0.0

@onready var _hud_label: Label = $EscapeHUD/TimeLabel


func _ready() -> void:
	GameManager.current_area_name = "THE COLLAPSE"
	GameManager.current_area_id = "escape"
	AudioManager.play_music("boss")
	QuestTracker.begin_area("RUN. The light is at the far end")
	GameManager.has_checkpoint = false
	GameManager.run_time = 0.0


func _process(delta: float) -> void:
	if not _running:
		return
	_time_left -= delta
	_wall_x += WALL_SPEED * delta
	_quake_t -= delta
	_hud_label.text = "%d:%02d" % [int(_time_left) / 60, int(_time_left) % 60]
	if _quake_t <= 0.0:
		_quake_t = randf_range(0.8, 1.6)
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.25)
		# Debris falls somewhere ahead of the wall.
		var player := get_tree().get_first_node_in_group("player")
		if player:
			var rock := preload("res://scenes/enemies/boss/EmberFall.tscn").instantiate()
			add_child(rock)
			rock.global_position = Vector2(player.global_position.x + randf_range(-40, 260), 30.0)
			rock.setup(1, 252.0)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		# The collapse catches you — or time runs out under the falling roof.
		if player.global_position.x < _wall_x or _time_left <= 0.0:
			_running = false
			var stats = player.get_node_or_null("Stats")
			if stats:
				stats.take_damage(999)
			# Reset the run after the death screen does its thing.
			get_tree().create_timer(3.0).timeout.connect(func():
				_time_left = TIME_LIMIT
				_wall_x = -160.0
				_running = true)
		elif player.global_position.x > 3920.0:
			_finish()
	queue_redraw()


func _finish() -> void:
	_running = false
	PlayerProgress.set_flag("ending_fall_seen")
	SaveManager.autosave()
	var cut := get_node_or_null("Cutscene")
	if cut:
		cut.play(ENDING_A_PANELS)
		cut.finished.connect(func():
			SceneFlow.travel("res://scenes/ui/Credits.tscn", "up"), CONNECT_ONE_SHOT)


func _draw() -> void:
	# The collapse wall: a churning face of dust and tumbling stone.
	var x := _wall_x
	draw_rect(Rect2(x - 400, 0, 400, 288), Color(0.08, 0.06, 0.05, 0.96))
	var t := Time.get_ticks_msec() / 1000.0
	for i in 14:
		var yy := fmod(i * 37.0 + t * 60.0, 288.0)
		var xx := x - 8.0 - fmod(i * 53.0 + t * 30.0, 60.0)
		draw_circle(Vector2(xx, yy), 6.0 + (i % 4) * 3.0, Color(0.16, 0.12, 0.1, 0.8))
	for i in 8:
		var yy := fmod(i * 53.0 - t * 80.0, 288.0)
		draw_circle(Vector2(x + sin(t * 4.0 + i) * 6.0, yy), 3.0, Color(0.35, 0.28, 0.22, 0.6))
