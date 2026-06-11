extends Node2D
## Cairn — Sanctum root. Reveals the location card on entry and clears any active
## objective (you're safe here). The hub between runs: spend Shards at the altar,
## hear the keeper's lore, then descend through the portal.

func _ready() -> void:
	QuestTracker.set_objective("")
	await get_tree().process_frame
	var title := get_tree().get_first_node_in_group("location_title")
	if title and title.has_method("reveal"):
		title.reveal("THE SANCTUM", "A REST BETWEEN DEATHS")
