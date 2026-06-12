extends CanvasLayer
## Cairn — the Vestibule merchant's stall. A dark keyboard-driven list: W/S
## browse, E buy, Esc/Ctrl leave. Sells the eight usable items (Bone Charms are
## scarce — one per boss felled, the stock "refreshing" as the deep empties).
## Pauses the game while open.

const Items = preload("res://scenes/systems/ItemDB.gd")
const FONT := preload("res://assets/fonts/silkscreen.ttf")

const STOCK_ORDER := ["ichor", "smoke", "prism", "shatter", "lantern", "flask", "echo", "charm"]

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


func _process(delta: float) -> void:
	if not _open:
		return
	_msg_t = maxf(0.0, _msg_t - delta)
	if Input.is_action_just_pressed("move_up"):
		_sel = wrapi(_sel - 1, 0, STOCK_ORDER.size())
		AudioManager.ui("menu_click", -14.0)
	elif Input.is_action_just_pressed("move_down"):
		_sel = wrapi(_sel + 1, 0, STOCK_ORDER.size())
		AudioManager.ui("menu_click", -14.0)
	elif Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack"):
		_buy(STOCK_ORDER[_sel])
	elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("crouch"):
		_close()
	_canvas.queue_redraw()


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
	for i in STOCK_ORDER.size():
		var id: String = STOCK_ORDER[i]
		var item: Dictionary = Items.get_item(id)
		var iy := y0 + 36.0 + i * 40.0
		var seld := i == _sel
		var avail := id != "charm" or _charm_in_stock()
		var col := Color(0.92, 0.92, 1.0) if seld else Color(0.55, 0.57, 0.7)
		if not avail:
			col = Color(0.3, 0.3, 0.4)
		if seld:
			_canvas.draw_rect(Rect2(x0 - 14, iy - 16, 540, 34), Color(0.12, 0.11, 0.18, 0.8))
			_canvas.draw_rect(Rect2(x0 - 14, iy - 16, 540, 34), Color(0.5, 0.48, 0.7, 0.6), false, 1.0)
		var tint: Color = item.get("tint", Color.GRAY)
		_canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(x0, iy - 6), Vector2(x0 + 6, iy), Vector2(x0, iy + 6), Vector2(x0 - 6, iy)]), tint)
		_canvas.draw_string(FONT, Vector2(x0 + 16, iy + 4), str(item.get("name", id)),
			HORIZONTAL_ALIGNMENT_LEFT, 240, 12, col)
		_canvas.draw_string(FONT, Vector2(x0 + 250, iy + 4),
			("%d ◆" % item.get("cost", 0)) if avail else "sold out",
			HORIZONTAL_ALIGNMENT_LEFT, 100, 11, col)
		_canvas.draw_string(FONT, Vector2(x0 + 330, iy + 4), "held x%d" % PlayerProgress.item_count(id),
			HORIZONTAL_ALIGNMENT_LEFT, 120, 9, Color(0.45, 0.48, 0.6))
		if seld:
			_canvas.draw_string(FONT, Vector2(0, y0 + 36.0 + STOCK_ORDER.size() * 40.0 + 16.0),
				str(item.get("desc", "")), HORIZONTAL_ALIGNMENT_CENTER, s.x, 10, Color(0.62, 0.66, 0.8))
	if _msg_t > 0.0:
		_canvas.draw_string(FONT, Vector2(0, s.y - 64), _msg,
			HORIZONTAL_ALIGNMENT_CENTER, s.x, 11, Color(0.95, 0.8, 0.5))
	_canvas.draw_string(FONT, Vector2(0, s.y - 30), "W / S  browse      E  buy      Esc  leave",
		HORIZONTAL_ALIGNMENT_CENTER, s.x, 9, Color(0.45, 0.48, 0.6))
