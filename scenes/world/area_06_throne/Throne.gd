extends Node2D
## Cairn — Area 6 "THE SOVEREIGN'S THRONE" root. The end of the descent: the
## Pale Sovereign waits at the dais, and what happens when it falls depends on
## the answer you gave its echo — THE CAIRN FALLS (the escape, ending A) or
## THE CAIRN ENDURES (you take the throne, ending B).

const BOSS_ID := "pale_sovereign"

const ENDING_B_PANELS := [
	{"art": "warden", "text": "The grief does not die. Grief never dies. It only needs somewhere to sit.", "hold": 13.0},
	{"art": "king", "text": "You take the throne the way you took every room on the way down — quietly, and as the last one standing.", "hold": 13.0},
	{"art": "sealing", "text": "The kingdom holds. The water stays where it is. The forges warm. The pages settle. The promise has a keeper again.", "hold": 13.0},
	{"art": "hollow", "text": "Somewhere above, the surface forgets there was ever a door. That is the price, and you knew it when you answered.", "hold": 13.0},
	{"art": "warden", "text": "The dead of Cairn rest easier under a warden who once bled like them.", "hold": 13.0},
	{"art": "crown", "text": "THE CAIRN ENDURES.    Some endings are thrones.", "hold": 14.0},
]


func _ready() -> void:
	QuestTracker.boss_defeated.connect(_on_boss_defeated)
	if PlayerProgress.has_flag("boss_%s_dead" % BOSS_ID):
		var boss := get_node_or_null("PaleSovereign")
		if boss:
			boss.queue_free()
	GameManager.current_area_name = "THE SOVEREIGN'S THRONE"
	GameManager.current_area_id = "throne"
	PlayerProgress.set_flag("seen_throne")
	PlayerProgress.furthest_area = "throne"
	AudioManager.play_music("throne")
	QuestTracker.begin_area("The processional — walk where the court walked")
	call_deferred("_apply_pending_spawn")
	await get_tree().process_frame
	var title := get_tree().get_first_node_in_group("location_title")
	if title and title.has_method("reveal"):
		title.reveal("THE SOVEREIGN'S THRONE", "DESCENT VI — THE LAST")


func _apply_pending_spawn() -> void:
	if GameManager.pending_spawn == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = GameManager.pending_spawn
		player.velocity = Vector2.ZERO
	GameManager.pending_spawn = null


## The Sovereign falls: the white flash plays from the boss itself; once the
## screen clears, the chosen ending takes over.
func _on_boss_defeated(id: String) -> void:
	if id != BOSS_ID:
		return
	get_tree().create_timer(3.0).timeout.connect(func():
		if PlayerProgress.has_flag("choice_endure"):
			# ENDING B: the throne is taken.
			PlayerProgress.set_flag("ending_endure_seen")
			SaveManager.autosave()
			var cut := get_node_or_null("Cutscene")
			if cut:
				cut.play(ENDING_B_PANELS)
				cut.finished.connect(func():
					SceneFlow.travel("res://scenes/ui/Credits.tscn", "up"), CONNECT_ONE_SHOT)
			else:
				SceneFlow.travel("res://scenes/ui/Credits.tscn", "up")
		else:
			# ENDING A (default): the deep comes down — RUN.
			SceneFlow.travel("res://scenes/world/escape/Escape.tscn", "down"))
