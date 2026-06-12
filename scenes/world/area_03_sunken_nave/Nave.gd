extends Node2D
## Cairn — Area 3 "THE SUNKEN NAVE" root. The drowned cathedral: black water,
## shelf-top crossings, the bell tower, and a choir door that stays sealed —
## whatever sings behind it belongs to the next descent.

func _ready() -> void:
	GameManager.current_area_name = "THE SUNKEN NAVE"
	PlayerProgress.furthest_area = "sunken_nave"
	QuestTracker.begin_area("Wade in — the black water drags, the deep water keeps")
	call_deferred("_apply_pending_spawn")
	await get_tree().process_frame
	var title := get_tree().get_first_node_in_group("location_title")
	if title and title.has_method("reveal"):
		title.reveal("THE SUNKEN NAVE", "DESCENT III")


func _apply_pending_spawn() -> void:
	if GameManager.pending_spawn == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = GameManager.pending_spawn
		player.velocity = Vector2.ZERO
	GameManager.pending_spawn = null
