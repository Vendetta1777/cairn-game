extends Node2D
## Cairn — Area 5 "THE IRON WARRENS" root. The mines that found the King.
## Slaying the Buried King grants a full heart and the kingdom's memory
## (the lore cutscene), and opens the last descent.

const BOSS_ID := "buried_king"
const CROWN := preload("res://scenes/enemies/boss/CrownProp.gd")

const LORE_PANELS := [
	{"art": "kingdom", "text": "Cairn was never a grave. It was a kingdom — the last one, built downward when the surface failed.", "hold": 13.0},
	{"art": "sinking", "text": "Then the water came up through the stone, patient as rot. The lower city drowned in a single winter.", "hold": 13.0},
	{"art": "king", "text": "The King would not abandon the deep. He swore the kingdom would endure — whatever it cost, whoever it cost.", "hold": 13.0},
	{"art": "sealing", "text": "So the court sealed him below with the thing he had bargained with. The miners were told to dig the door shut.", "hold": 13.0},
	{"art": "hollow", "text": "The kingdom endured. Hollow, sunken, ash-choked — but enduring. That was the bargain's shape.", "hold": 13.0},
	{"art": "crown", "text": "You have broken the seal the court died making. Below the throne, something pale is still keeping the King's promise.", "hold": 14.0},
]


func _ready() -> void:
	GameManager.current_area_name = "THE IRON WARRENS"
	GameManager.current_area_id = "iron_warrens"
	PlayerProgress.set_flag("seen_iron_warrens")
	PlayerProgress.furthest_area = "iron_warrens"
	AudioManager.play_music("warrens")
	QuestTracker.begin_area("The Warrens hear you — WALK past what digs")
	QuestTracker.boss_defeated.connect(_on_boss_defeated)
	if PlayerProgress.has_flag("boss_%s_dead" % BOSS_ID):
		var boss := get_node_or_null("BuriedKing")
		if boss:
			boss.queue_free()
		# His crown stays in the arena forever.
		var crown := Node2D.new()
		crown.set_script(CROWN)
		add_child(crown)
		crown.global_position = Vector2(3450, 252)
	# The Digger trades.
	var digger := get_node_or_null("LoreNPC")
	if digger:
		digger.chose.connect(_on_digger_trade)
	call_deferred("_apply_pending_spawn")
	await get_tree().process_frame
	var title := get_tree().get_first_node_in_group("location_title")
	if title and title.has_method("reveal"):
		title.reveal("THE IRON WARRENS", "DESCENT V")


func _on_digger_trade(idx: int) -> void:
	var box := get_tree().get_first_node_in_group("dialogue")
	var player := get_tree().get_first_node_in_group("player")
	var stats = player.get_node_or_null("Stats") if player else null
	if stats == null:
		return
	var deals := [["ichor", 10], ["charm", 25]]
	if idx >= deals.size():
		return
	var id: String = deals[idx][0]
	var cost: int = deals[idx][1]
	if stats.shards < cost:
		if box:
			box.show_text("\"Come back when your pockets jingle, outsider.\"")
		return
	if not PlayerProgress.add_item(id):
		if box:
			box.show_text("\"Your ring is full. Use something first.\"")
		return
	stats.spend_shards(cost)
	SaveManager.autosave()
	AudioManager.play("chest", -10.0)
	if box:
		box.show_text("\"Sold. Mind the dark with it.\"")


func _apply_pending_spawn() -> void:
	if GameManager.pending_spawn == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = GameManager.pending_spawn
		player.velocity = Vector2.ZERO
	GameManager.pending_spawn = null


func _on_boss_defeated(id: String) -> void:
	if id != BOSS_ID or PlayerProgress.has_flag("king_reward_given"):
		return
	PlayerProgress.set_flag("king_reward_given")
	# A full heart — the King's vitality passes on (cap-respecting).
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var stats = player.get_node_or_null("Stats")
		if stats:
			stats.grant_half_heart()
			stats.grant_half_heart()
	var banner := get_tree().get_first_node_in_group("location_title")
	if banner and banner.has_method("reveal"):
		banner.reveal("THE KING IS UNBURIED", "+1 HEART — THE MEMORY OPENS")
	SaveManager.autosave()
	# The lore reveal: what Cairn actually is. Plays after the shatter settles.
	get_tree().create_timer(3.4).timeout.connect(func():
		var cut := get_node_or_null("Cutscene")
		if cut:
			cut.play(LORE_PANELS))
