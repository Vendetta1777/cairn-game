extends Node
## Cairn — GameManager (autoload singleton, GDD Section 13).
##
## The global spine of the game. M1 scope: pause handling + a place for the
## other managers to hang off as they come online. Grows through the milestones:
##   M6: save/load orchestration, run lifecycle (death -> Sanctum), ending flags.
##
## Registered as the "GameManager" autoload in project.godot.

signal game_paused(is_paused: bool)

var is_paused: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()


func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)


## Combat juice: freeze everything for a beat on impact, then resume. Runs on a
## real-time timer so it works even though time_scale is 0.
func hitstop(duration: float) -> void:
	if duration <= 0.0:
		return
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

