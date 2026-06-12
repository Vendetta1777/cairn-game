extends Node
## Cairn — Achievements (autoload): fifteen quiet stones, each earned once and
## persisted. A small toast slides in when one is set. Event-driven where
## signals exist; a slow 2s poll covers the count-based ones.

const FONT := preload("res://assets/fonts/silkscreen.ttf")

const DEFS := {
	"first_blood":    "FIRST BLOOD — fell your first guardian",
	"broodbreaker":   "BROODBREAKER — the Brood Mother is broken",
	"forge_cold":     "THE FORGE GOES COLD — the Ashen Warden falls",
	"unbinder":       "UNBINDER — the Pale Librarian is unbound",
	"unburier":       "UNBURIER — the Buried King is unburied",
	"kingslayer":     "KINGSLAYER — the Pale Sovereign is ended",
	"all_depths":     "EVERY DEPTH — walked all six descents",
	"heart_of_iron":  "HEART OF IRON — claimed the Warrens heart-shrine",
	"charmed_life":   "CHARMED LIFE — a bone charm spent itself for you",
	"deep_pockets":   "DEEP POCKETS — held 60 shards at once",
	"carved_ten":     "CARVED IN — ten skills taken at the altar",
	"confidant":      "CONFIDANT — heard out all six rememberers",
	"ending_fall":    "THE CAIRN FALLS — saw the ending of mercies",
	"ending_endure":  "THE CAIRN ENDURES — became the new warden",
	"twice_buried":   "TWICE BURIED — ended the Sovereign in New Game+",
}

const NPCS := ["hollow_pilgrim", "pale_archivist", "digger", "cartographer", "last_knight", "pale_sovereign"]
const AREAS := ["hollowed_gate", "ashpits", "sunken_nave", "pale_library", "iron_warrens", "throne"]

var _toasts: Array = []     ## queued [text]
var _layer: CanvasLayer
var _toast_label: Label
var _showing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	QuestTracker.boss_defeated.connect(_on_boss)
	var timer := Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(_poll)
	add_child(timer)


func grant(id: String) -> void:
	if not DEFS.has(id) or PlayerProgress.achievements.get(id, false):
		return
	PlayerProgress.achievements[id] = true
	SaveManager.autosave()
	_toasts.append(DEFS[id])
	_pump()


func count() -> int:
	return PlayerProgress.achievements.size()


func _on_boss(boss_id: String) -> void:
	grant("first_blood")
	match boss_id:
		"mother_bat": grant("broodbreaker")
		"ashen_warden": grant("forge_cold")
		"pale_librarian": grant("unbinder")
		"buried_king": grant("unburier")
		"pale_sovereign":
			grant("kingslayer")
			if PlayerProgress.ng_plus > 0:
				grant("twice_buried")


func _poll() -> void:
	if PlayerProgress.shards >= 60:
		grant("deep_pockets")
	if PlayerProgress.unlocked.size() >= 10:
		grant("carved_ten")
	if PlayerProgress.has_flag("used_warrens_heart"):
		grant("heart_of_iron")
	if PlayerProgress.has_flag("charm_saved_you"):
		grant("charmed_life")
	if PlayerProgress.has_flag("ending_fall_seen"):
		grant("ending_fall")
	if PlayerProgress.has_flag("ending_endure_seen"):
		grant("ending_endure")
	var all_seen := true
	for a in AREAS:
		if not PlayerProgress.has_flag("seen_%s" % a):
			all_seen = false
			break
	if all_seen:
		grant("all_depths")
	var all_talked := true
	for n in NPCS:
		if not PlayerProgress.has_flag("talked_%s" % n):
			all_talked = false
			break
	if all_talked:
		grant("confidant")


# --- the toast --------------------------------------------------------------------

func _pump() -> void:
	if _showing or _toasts.is_empty():
		return
	_showing = true
	if _layer == null:
		_layer = CanvasLayer.new()
		_layer.layer = 32
		add_child(_layer)
		_toast_label = Label.new()
		_toast_label.add_theme_font_override("font", FONT)
		_toast_label.add_theme_font_size_override("font_size", 11)
		_toast_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.6))
		_toast_label.position = Vector2(960, 70)
		_layer.add_child(_toast_label)
	var text: String = _toasts.pop_front()
	_toast_label.text = "◆  " + text
	AudioManager.ui("item_pickup", -8.0)
	var w := 420.0
	_toast_label.position = Vector2(970, 70)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_toast_label, "position:x", 960.0 - w, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.6)
	tw.tween_property(_toast_label, "position:x", 970.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_showing = false
		_pump())
