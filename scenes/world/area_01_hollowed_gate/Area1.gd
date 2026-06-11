extends Node2D
## Cairn — Area 1 root. Seeds the opening objective when the Hollowed Gate loads,
## and hands out the boss reward: slaying the Hollow Warden grants the Wardstone
## (a permanent +1 heart) and opens the path onward to the Sanctum.

const BOSS_ID := "mother_bat"


func _ready() -> void:
	QuestTracker.begin_area("Explore the Hollowed Gate")
	QuestTracker.boss_defeated.connect(_on_boss_defeated)


func _on_boss_defeated(id: String) -> void:
	if id != BOSS_ID or PlayerProgress.has_flag("warden_slain"):
		return
	PlayerProgress.set_flag("warden_slain")
	# The unlock: a permanent heart, applied live to the current player and
	# persisted via PlayerProgress (add_heart bumps bonus_hearts under the hood).
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var stats = player.get_node_or_null("Stats")
		if stats and stats.has_method("add_heart"):
			stats.add_heart(1)
	# Announce it, reusing the location-title card.
	var banner := get_tree().get_first_node_in_group("location_title")
	if banner and banner.has_method("reveal"):
		banner.reveal("BROODHEART CLAIMED", "+1 MAX HEART  ·  THE PATH OPENS")
