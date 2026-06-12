extends Node2D
## Cairn — Area 4 "THE PALE LIBRARY" root. The drowned archive: shades still
## shelving, plates and counterweights still working, and the Librarian still
## guarding what the kingdom tried to forget.

const BOSS_ID := "pale_librarian"


func _ready() -> void:
	GameManager.current_area_name = "THE PALE LIBRARY"
	GameManager.current_area_id = "pale_library"
	PlayerProgress.set_flag("seen_pale_library")
	PlayerProgress.furthest_area = "pale_library"
	AudioManager.play_music("library")
	QuestTracker.begin_area("The archive remembers — mind the pages")
	QuestTracker.boss_defeated.connect(_on_boss_defeated)
	if PlayerProgress.has_flag("boss_%s_dead" % BOSS_ID):
		var boss := get_node_or_null("PaleLibrarian")
		if boss:
			boss.queue_free()
	call_deferred("_apply_pending_spawn")
	await get_tree().process_frame
	var title := get_tree().get_first_node_in_group("location_title")
	if title and title.has_method("reveal"):
		title.reveal("THE PALE LIBRARY", "DESCENT IV")


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
	var banner := get_tree().get_first_node_in_group("location_title")
	if banner and banner.has_method("reveal"):
		banner.reveal("THE BINDING IS BROKEN", "CLAIM THE RIGGER'S HOOK")
