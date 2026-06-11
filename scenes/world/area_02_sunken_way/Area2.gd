extends Node2D
## Cairn — Area 2 "The Sunken Way" (placeholder/stub for now). Proves the descent
## works: the chasm at the end of Area 1 drops you here. A small, darker cave with
## a wanderer's note; the full level arrives with M7. A passage back to the
## Sanctum keeps you from being stranded.

func _ready() -> void:
	GameManager.current_area_name = "THE SUNKEN WAY"
	PlayerProgress.furthest_area = "sunken_way"
	QuestTracker.begin_area("The Sunken Way — deeper still (more to come)")
	call_deferred("_apply_pending_spawn")
	await get_tree().process_frame
	var title := get_tree().get_first_node_in_group("location_title")
	if title and title.has_method("reveal"):
		title.reveal("THE SUNKEN WAY", "DESCENT II")


func _apply_pending_spawn() -> void:
	if GameManager.pending_spawn == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = GameManager.pending_spawn
		player.velocity = Vector2.ZERO
	GameManager.pending_spawn = null
