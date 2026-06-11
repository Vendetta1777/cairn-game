extends Node
## Cairn — QuestTracker (autoload). The lightweight spine of "what do I do now".
##
## Holds the player's current objective as a single line of text and broadcasts
## changes so the ObjectiveHUD can show it. It also owns the higher-level area
## flow flags (boss defeated, area complete) that gates/doors read. This is what
## turns the sandbox level into a game with actual steps.

signal objective_changed(text: String)
signal area_completed(area_id: String)
signal boss_defeated(boss_id: String)

var current_objective: String = ""

## Per-area progress flags. Reset when a new area loads via begin_area().
var flags: Dictionary = {}


## Called by an area's root when it loads, to seed the first objective.
func begin_area(first_objective: String) -> void:
	flags.clear()
	set_objective(first_objective)


func set_objective(text: String) -> void:
	if text == current_objective:
		return
	current_objective = text
	objective_changed.emit(text)


func set_flag(flag: String, value: bool = true) -> void:
	flags[flag] = value


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


## A boss reports its death here; gates listen for the matching id.
func report_boss_defeated(boss_id: String) -> void:
	set_flag("boss_%s_dead" % boss_id, true)
	boss_defeated.emit(boss_id)


## The player reached the area's exit. Fires the completion flow.
func complete_area(area_id: String) -> void:
	if has_flag("area_done"):
		return
	set_flag("area_done", true)
	area_completed.emit(area_id)
