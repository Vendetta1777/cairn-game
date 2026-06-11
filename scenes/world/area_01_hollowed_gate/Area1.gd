extends Node2D
## Cairn — Area 1 root. Seeds the opening objective when the Hollowed Gate loads,
## and hands out the boss reward: slaying the Hollow Warden grants the Wardstone
## (a permanent +1 heart) and opens the path onward to the Sanctum.

const BOSS_ID := "mother_bat"


func _ready() -> void:
	GameManager.current_area_name = "THE HOLLOWED GATE"
	QuestTracker.begin_area("The Waking — move with A / D, leap with Space")
	QuestTracker.boss_defeated.connect(_on_boss_defeated)
	# The Brood Mother dies ONCE. If she's already slain on this save, remove her
	# so a return trip (or a death) never re-spawns the fight.
	if PlayerProgress.has_flag("warden_slain"):
		var boss := get_node_or_null("MotherBat")
		if boss:
			boss.queue_free()
	call_deferred("_apply_pending_spawn")


## A portal told us where to drop the player — place them beside it, not at start.
func _apply_pending_spawn() -> void:
	if GameManager.pending_spawn == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = GameManager.pending_spawn
		player.velocity = Vector2.ZERO
	GameManager.pending_spawn = null


func _on_boss_defeated(id: String) -> void:
	if id != BOSS_ID or PlayerProgress.has_flag("warden_slain"):
		return
	PlayerProgress.set_flag("warden_slain")
	# No heart from the boss — hearts come only from heart-shrines (every 5
	# levels). Slaying her simply opens the way down to the next descent.
	var banner := get_tree().get_first_node_in_group("location_title")
	if banner and banner.has_method("reveal"):
		banner.reveal("THE BROOD IS BROKEN", "THE WAY DOWN OPENS")
