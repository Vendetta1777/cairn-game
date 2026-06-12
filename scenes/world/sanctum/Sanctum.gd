extends Node2D
## Cairn — THE VESTIBULE (the hub once called the Sanctum): the one still point
## between all depths. Rest, spend, restock, hear the news. It grows as you do:
##   - the Hollow Pilgrim arrives once the Brood Mother falls (he leaves Area 1)
##   - the Cartographer appears once you've reached the Sunken Nave; for shards
##     she charts one depth you haven't walked yet (map reveal)
##   - the Merchant trades the eight usable items (Bone Charms restock per boss)
##   - memorial candles light along the wall for every guardian you've felled.

const CARTOGRAPHER_FEE := 15
const HINTABLE := ["pale_library", "iron_warrens", "throne"]


func _ready() -> void:
	GameManager.current_area_name = "THE VESTIBULE"
	GameManager.current_area_id = "sanctum"
	PlayerProgress.set_flag("seen_sanctum")
	AudioManager.play_music("sanctum")
	QuestTracker.set_objective("")
	_wire_npcs()
	_memorial_candles()
	call_deferred("_apply_pending_spawn")
	await get_tree().process_frame
	var title := get_tree().get_first_node_in_group("location_title")
	if title and title.has_method("reveal"):
		title.reveal("THE VESTIBULE", "BETWEEN ALL DEPTHS")


func _wire_npcs() -> void:
	var merchant := get_node_or_null("Merchant")
	if merchant:
		merchant.chose.connect(func(idx):
			if idx == 0:
				var shop := get_node_or_null("ShopUI")
				if shop:
					shop.open_shop())
	var carto := get_node_or_null("Cartographer")
	if carto:
		carto.chose.connect(_on_cartographer)


func _on_cartographer(idx: int) -> void:
	if idx != 0:
		return
	var player := get_tree().get_first_node_in_group("player")
	var stats = player.get_node_or_null("Stats") if player else null
	if stats == null or stats.shards < CARTOGRAPHER_FEE:
		var box := get_tree().get_first_node_in_group("dialogue")
		if box:
			box.show_text("\"Ink costs. Fifteen shards, and not one fewer.\"")
		return
	# Chart the first depth the player hasn't seen.
	for id in ["pale_library", "iron_warrens", "throne", "ashpits", "sunken_nave"]:
		if not PlayerProgress.has_flag("seen_%s" % id):
			stats.spend_shards(CARTOGRAPHER_FEE)
			PlayerProgress.set_flag("seen_%s" % id)
			SaveManager.autosave()
			AudioManager.play("checkpoint", -10.0)
			var banner := get_tree().get_first_node_in_group("location_title")
			if banner and banner.has_method("reveal"):
				banner.reveal("A DEPTH IS CHARTED", "PRESS M — THE TABLET REMEMBERS")
			return
	var box := get_tree().get_first_node_in_group("dialogue")
	if box:
		box.show_text("\"There is nothing left to chart, wanderer. You have walked it all.\"")


## A memorial candle on the back wall per guardian felled — the hub grows.
func _memorial_candles() -> void:
	var killed := 0
	for id in PlayerProgress.KNOWN_BOSSES:
		if PlayerProgress.boss_defeated(id):
			killed += 1
	for i in killed:
		var l := PointLight2D.new()
		l.position = Vector2(360 + i * 60.0, 180)
		l.color = Color(1.0, 0.8, 0.45)
		l.energy = 0.5
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.width = 64
		gt.height = 64
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(0.5, 0)
		l.texture = gt
		l.texture_scale = 0.6
		add_child(l)


## A portal told us where to drop the player — beside the Vestibule's own portal.
func _apply_pending_spawn() -> void:
	if GameManager.pending_spawn == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = GameManager.pending_spawn
		player.velocity = Vector2.ZERO
	GameManager.pending_spawn = null
