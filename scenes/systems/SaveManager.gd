extends Node
## Cairn — SaveManager (autoload, GDD Section 15: 3 slots, auto-save on
## checkpoint / area transition / boss death). Serialises PlayerProgress (the
## durable spine) plus a little meta to a JSON file per slot under user://.
## Auto-save listens to the world's own signals so the game persists itself
## without any scene having to remember to call it.

signal saved(slot: int)
signal loaded(slot: int)

const SLOTS := 3
const VERSION := 1

var current_slot: int = 0


func _ready() -> void:
	# Persist automatically at the natural beats.
	GameManager.checkpoint_set.connect(func(_p): autosave())
	QuestTracker.boss_defeated.connect(func(_id): autosave())
	QuestTracker.area_completed.connect(func(_id): autosave())


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
	loaded.emit(slot)
	return true


func delete_slot(slot: int) -> void:
	if has_slot(slot):
		DirAccess.remove_absolute(_path(slot))


## Save to the active slot (called by the auto-save signal hooks).
func autosave() -> void:
	save_slot(current_slot)
