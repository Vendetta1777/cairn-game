extends CanvasLayer
## Cairn — the Vestibule merchant's stall. A dark keyboard-driven list: W/S
## browse, E buy, Esc/Ctrl leave. Sells the eight usable items (Bone Charms are
## scarce — one per boss felled, the stock "refreshing" as the deep empties).
## Pauses the game while open.

const Items = preload("res://scenes/systems/ItemDB.gd")
const FONT := preload("res://assets/fonts/silkscreen.ttf")

const STOCK_ORDER := ["ichor", "smoke", "prism", "shatter", "lantern", "flask", "echo", "charm"]
## Charms the merchant deals in (sold once each; the 5th purchase of ANYTHING
## earns the Shaman Stone as the house's regards).
const CHARM_STOCK := {"quick_slash": 25, "fragile_strength": 60, "quick_focus": 45}
const CharmsDB = preload("res://scenes/systems/CharmDB.gd")

var _open := false
var _sel := 0
var _msg := ""
var _msg_t := 0.0

@onready var _canvas: Control = $Canvas


func _ready() -> void:
	add_to_group("shop")
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_canvas.draw.connect(_paint)


func open_shop() -> void:
	_open = true
	_sel = 0
	_msg = ""
	visible = true
	get_tree().paused = true


func _close() -> void:
	_open = false
	visible = false
	get_tree().paused = false


func _killed_bosses() -> int:
	var n := 0
	for id in PlayerProgress.KNOWN_BOSSES:
		if PlayerProgress.boss_defeated(id):
			n += 1
	return n


func _charm_in_stock() -> bool:
	return not PlayerProgress.has_flag("charm_sold_%d" % _killed_bosses())


## Items first, then the charm shelf (each "charm:<id>" sold once).
func _rows() -> Array:
	var out := STOCK_ORDER.duplicate()
	for id in CHARM_STOCK:
		if not PlayerProgress.has_charm(id):
			out.append("charm:" + id)
	return out


func _process(delta: float) -> void:
	if not _open:
		return
	_msg_t = maxf(0.0, _msg_t - delta)
	var rows := _rows()
	if Input.is_action_just_pressed("move_up"):
		_sel = wrapi(_sel - 1, 0, rows.size())
		AudioManager.ui("menu_click", -14.0)
	elif Input.is_action_just_pressed("move_down"):
		_sel = wrapi(_sel + 1, 0, rows.size())
		AudioManager.ui("menu_click", -14.0)
	elif Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack"):
		var row: String = rows[mini(_sel, rows.size() - 1)]
		if row.begins_with("charm:"):
			_buy_charm(row.trim_prefix("charm:"))
		else:
			_buy(row)
	elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("crouch"):
		_close()
	_canvas.queue_redraw()


func _buy_charm(id: String) -> void:
	var cost: int = CHARM_STOCK.get(id, 9999)
	var player := get_tree().get_first_node_in_group("player")
	var stats = player.get_node_or_null("Stats") if player else null
	var shards: int = stats.shards if stats else PlayerProgress.shards
	if shards < cost:
		_flash_msg("Not enough Shards.")
		AudioManager.play("enemy_hurt", -16.0)
		return
	if stats:
		stats.spend_shards(cost)
	else:
		PlayerProgress.spend_shards(cost)
	PlayerProgress.grant_charm(id)
	AudioManager.ui("skill_buy", -8.0)
	_flash_msg("%s — carved into your pouch. Attune at a stone." % CharmsDB.get_charm(id).get("name", id))
	_count_purchase()
	SaveManager.autosave()


## The 5th purchase of anything earns the Shaman Stone.
func _count_purchase() -> void:
	for i in range(1, 6):
		if not PlayerProgress.has_flag("shop_buy_%d" % i):
			PlayerProgress.set_flag("shop_buy_%d" % i)
			if i == 5 and not PlayerProgress.has_charm("shaman_stone"):
				PlayerProgress.grant_charm("shaman_stone")
				_flash_msg("A regular! Take this — the Shaman Stone. House's regards.")
				AudioManager.ui("skill_buy", -4.0)
			return


func _buy(id: String) -> void:
	var item: Dictionary = Items.get_item(id)
	var cost := int(item.get("cost", 9999))
	if id == "charm" and not _charm_in_stock():
		_flash_msg("The charms are spent. Fell another guardian.")
		return
	var player := get_tree().get_first_node_in_group("player")
	var stats = player.get_node_or_null("Stats") if player else null
	var shards: int = stats.shards if stats else PlayerProgress.shards
	if shards < cost:
		_flash_msg("Not enough Shards.")
		AudioManager.play("enemy_hurt", -16.0)
		return
	if not PlayerProgress.add_item(id):
		_flash_msg("Your ring carries four kinds, no more.")
		return
	if stats:
		stats.spend_shards(cost)
	else:
		PlayerProgress.spend_shards(cost)
	if id == "charm":
		PlayerProgress.set_flag("charm_sold_%d" % _killed_bosses())
	AudioManager.play("chest", -10.0)
	_flash_msg("%s — bought." % item.get("name", id))
	_count_purchase()
	SaveManager.autosave()


func _flash_msg(m: String) -> void:
	_msg = m
	_msg_t = 2.2


func _paint() -> void:
	var s := _canvas.size
	_canvas.draw_rect(Rect2(0, 0, s.x, s.y), Color(0.01, 0.012, 0.02, 0.86))
	var x0 := s.x * 0.5 - 260.0
	var y0 := 70.0
	_canvas.draw_string(FONT, Vector2(0, y0 - 22), "THE MERCHANT OF THE VESTIBULE",
		HORIZONTAL_ALIGNMENT_CENTER, s.x, 16, Color(0.85, 0.8, 0.9))
	var player := get_tree().get_first_node_in_group("player")
	var stats = player.get_node_or_null("Stats") if player else null
	var shards: int = stats.shards if stats else PlayerProgress.shards
	_canvas.draw_string(FONT, Vector2(0, y0 + 2), "your shards: %d" % shards,
		HORIZONTAL_ALIGNMENT_CENTER, s.x, 10, Color(0.55, 0.8, 0.85))
	var rows := _rows()
	for i in rows.size():
		var row: String = rows[i]
		var is_charm := row.begins_with("charm:")
		var id := row.trim_prefix("charm:")
		var item: Dictionary = CharmsDB.get_charm(id) if is_charm else Items.get_item(id)
		var iy := y0 + 30.0 + i * 33.0
		var seld := i == _sel
		var avail: bool = is_charm or id != "charm" or _charm_in_stock()
		var col := Color(0.92, 0.92, 1.0) if seld else Color(0.55, 0.57, 0.7)
		if is_charm:
			col = Color(0.85, 0.78, 1.0) if seld else Color(0.6, 0.55, 0.75)
		if not avail:
			col = Color(0.3, 0.3, 0.4)
		if seld:
			_canvas.draw_rect(Rect2(x0 - 14, iy - 14, 540, 28), Color(0.12, 0.11, 0.18, 0.8))
			_canvas.draw_rect(Rect2(x0 - 14, iy - 14, 540, 28), Color(0.5, 0.48, 0.7, 0.6), false, 1.0)
		var tint: Color = item.get("tint", Color(0.6, 0.5, 0.85))
		if is_charm:
			_canvas.draw_arc(Vector2(x0, iy), 5.0, 0, TAU, 12, tint, 2.0)
		else:
			_canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(x0, iy - 6), Vector2(x0 + 6, iy), Vector2(x0, iy + 6), Vector2(x0 - 6, iy)]), tint)
		_canvas.draw_string(FONT, Vector2(x0 + 16, iy + 4), str(item.get("name", id)),
			HORIZONTAL_ALIGNMENT_LEFT, 240, 12, col)
		var cost: int = CHARM_STOCK.get(id, 0) if is_charm else int(item.get("cost", 0))
		_canvas.draw_string(FONT, Vector2(x0 + 250, iy + 4),
			("%d ◆" % cost) if avail else "sold out",
			HORIZONTAL_ALIGNMENT_LEFT, 100, 11, col)
		if not is_charm:
			_canvas.draw_string(FONT, Vector2(x0 + 330, iy + 4), "held x%d" % PlayerProgress.item_count(id),
				HORIZONTAL_ALIGNMENT_LEFT, 120, 9, Color(0.45, 0.48, 0.6))
		if seld:
			_canvas.draw_string(FONT, Vector2(0, y0 + 30.0 + rows.size() * 33.0 + 16.0),
				str(item.get("desc", item.get("lore", ""))), HORIZONTAL_ALIGNMENT_CENTER, s.x, 10, Color(0.62, 0.66, 0.8))
	if _msg_t > 0.0:
		_canvas.draw_string(FONT, Vector2(0, s.y - 64), _msg,
			HORIZONTAL_ALIGNMENT_CENTER, s.x, 11, Color(0.95, 0.8, 0.5))
	_canvas.draw_string(FONT, Vector2(0, s.y - 30), "W / S  browse      E  buy      Esc  leave",
		HORIZONTAL_ALIGNMENT_CENTER, s.x, 9, Color(0.45, 0.48, 0.6))
