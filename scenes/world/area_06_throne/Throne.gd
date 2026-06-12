extends Node2D
## Cairn — Area 6 "THE SOVEREIGN'S THRONE" root. The end of the descent. The
## hall runs on elite versions of everything the deep has already sent; the
## throne itself waits for M12 (the Pale Sovereign). The court is still here,
## in a way — the memory echoes walk their processional forever.

func _ready() -> void:
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
