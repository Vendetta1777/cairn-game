extends Node2D
## Cairn — Sanctum root. Reveals the location card on entry and clears any active
## objective (you're safe here). The hub between runs: spend Shards at the altar,
## hear the keeper's lore, then descend through the portal.

func _ready() -> void:
	GameManager.current_area_name = "THE SANCTUM"
	QuestTracker.set_objective("")
	call_deferred("_apply_pending_spawn")
	await get_tree().process_frame
	var title := get_tree().get_first_node_in_group("location_title")
	if title and title.has_method("reveal"):
		title.reveal("THE SANCTUM", "A REST BETWEEN DEATHS")


## A portal told us where to drop the player — beside the Sanctum's own portal.
func _apply_pending_spawn() -> void:
	if GameManager.pending_spawn == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = GameManager.pending_spawn
		player.velocity = Vector2.ZERO
	GameManager.pending_spawn = null
