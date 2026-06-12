extends Node
## Cairn — SaveManager (autoload, GDD Section 15: 3 slots, auto-save on
## checkpoint / area transition / boss death). Serialises PlayerProgress (the
## durable spine) plus a little meta to a JSON file per slot under user://.
## Auto-save listens to the world's own signals so the game persists itself
## without any scene having to remember to call it.

signal saved(slot: int)
signal loaded(slot: int)

const SLOTS := 3
const VERSION := 2

var current_slot: int = 0

## Autosaves only fire once a slot has been deliberately entered (New Game /
## Continue on the title screen). Without this, ANY session that skips the
## title — running a scene directly from the editor, a test script — would
## autosave near-empty progress over the real slot 0 on the first checkpoint
## touch. That silent stomp looks exactly like "the portal reset my save".
var session_active: bool = false


func _ready() -> void:
	# Persist automatically at every state-changing beat.
	GameManager.checkpoint_set.connect(func(_p): autosave())
	QuestTracker.boss_defeated.connect(func(_id): autosave())
	QuestTracker.area_completed.connect(func(_id): autosave())
	PlayerProgress.ability_unlocked.connect(func(_id): autosave())
	PlayerProgress.node_unlocked.connect(func(_id): autosave())


## The title screen calls this when a slot is chosen — arms autosaving.
func start_session(slot: int) -> void:
	current_slot = slot
	session_active = true


func _path(slot: int) -> String:
	return "user://cairn_save_%d.json" % slot


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(_path(slot))


## Light metadata for a save-select screen without fully loading the slot.
func slot_summary(slot: int) -> Dictionary:
	if not has_slot(slot):
		return {}
	var f := FileAccess.open(_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return {
		"area": data.get("furthest_area", "?"),
		"shards": data.get("shards", 0),
		"nodes": (data.get("unlocked", []) as Array).size(),
		"saved_at": data.get("saved_at", ""),
	}


func save_slot(slot: int) -> bool:
	var data := PlayerProgress.to_dict()
	data["version"] = VERSION
	data["saved_at"] = Time.get_datetime_string_from_system()
	var f := FileAccess.open(_path(slot), FileAccess.WRITE)
	if f == null:
		push_warning("Cairn: could not open save slot %d for writing" % slot)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	current_slot = slot
	saved.emit(slot)
	return true


func load_slot(slot: int) -> bool:
	if not has_slot(slot):
		return false
	var f := FileAccess.open(_path(slot), FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	PlayerProgress.from_dict(data)
	current_slot = slot
	session_active = true
	loaded.emit(slot)
	return true


func delete_slot(slot: int) -> void:
	if has_slot(slot):
		DirAccess.remove_absolute(_path(slot))


## Save to the active slot (called by the auto-save signal hooks). No-op until
## a slot is properly entered, so stray sessions can't stomp a real save.
func autosave() -> void:
	if not session_active:
		return
	save_slot(current_slot)
