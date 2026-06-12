extends Node2D
## Cairn — Area 2 "THE ASHPITS" root. Seeds the objective flow, and stages the
## Ashen Warden's fall: when the furnace-guardian dies the room goes dark for a
## beat (the forge's last light dies with it), then the chasm onward opens.

const BOSS_ID := "ashen_warden"


func _ready() -> void:
	GameManager.current_area_name = "THE ASHPITS"
	GameManager.current_area_id = "ashpits"
	PlayerProgress.set_flag("seen_ashpits")
	AudioManager.play_music("ashpits")
	PlayerProgress.furthest_area = "ashpits"
	QuestTracker.begin_area("Cross the dead forges — the heat still breathes")
	QuestTracker.boss_defeated.connect(_on_boss_defeated)
	# The Warden burns once. Already slain on this save? Clear the arena.
	if PlayerProgress.has_flag("boss_%s_dead" % BOSS_ID):
		var boss := get_node_or_null("AshenWarden")
		if boss:
			boss.queue_free()
	call_deferred("_apply_pending_spawn")
	await get_tree().process_frame
	var title := get_tree().get_first_node_in_group("location_title")
	if title and title.has_method("reveal"):
		title.reveal("THE ASHPITS", "DESCENT II")


func _apply_pending_spawn() -> void:
	if GameManager.pending_spawn == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = GameManager.pending_spawn
		player.velocity = Vector2.ZERO
	GameManager.pending_spawn = null


func _on_boss_defeated(id: String) -> void:
	if id != BOSS_ID:
		return
	# The furnace dies: the room drops to near-black, holds, then breathes back.
	var mood: CanvasModulate = get_node_or_null("Mood")
	if mood:
		var base := mood.color
		var tw := create_tween()
		tw.tween_property(mood, "color", Color(0.12, 0.1, 0.1), 1.2)
		tw.tween_interval(1.0)
		tw.tween_property(mood, "color", base, 2.5)
	var banner := get_tree().get_first_node_in_group("location_title")
	if banner and banner.has_method("reveal"):
		banner.reveal("THE FORGE IS COLD", "THE WAY DOWN OPENS")
