extends Node
## Cairn — GameManager (autoload singleton, GDD Section 13).
##
## The global spine of the game. M1 scope: pause handling + a place for the
## other managers to hang off as they come online. Grows through the milestones:
##   M6: save/load orchestration, run lifecycle (death -> Sanctum), ending flags.
##
## Registered as the "GameManager" autoload in project.godot.

signal game_paused(is_paused: bool)
signal checkpoint_set(position: Vector2)

var is_paused: bool = false

## Active respawn point (a Remnant Stone). Unset until the player touches one.
var has_checkpoint: bool = false
var checkpoint_position: Vector2 = Vector2.ZERO

## The display name of the loaded area (set by each area root) and how long this
## life has lasted — both shown on the death screen.
var current_area_name: String = "THE DEEP"
var current_area_id: String = ""
var run_time: float = 0.0
## Boss Rush plays with real bosses but must not write world flags or saves.
var boss_rush_mode: bool = false


func _process(delta: float) -> void:
	if not get_tree().paused:
		run_time += delta

## Where to drop the player when the next scene loads — set by a Portal so you
## arrive beside the destination's portal, not at the level start. null = none.
var pending_spawn = null


## Called by a Remnant Stone when the player activates it. The checkpoint is
## also written into PlayerProgress so it survives saves and portal round trips.
func set_checkpoint(position: Vector2) -> void:
	has_checkpoint = true
	checkpoint_position = position
	PlayerProgress.last_checkpoint = {
		"area": current_area_id, "x": position.x, "y": position.y}
	checkpoint_set.emit(position)

## Where the player should respawn — the last checkpoint, or the given fallback.
func get_respawn(fallback: Vector2) -> Vector2:
	return checkpoint_position if has_checkpoint else fallback


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


## Brief slow-motion (e.g. on a successful parry). Real-time timer so it restores.
func slowmo(scale: float, duration: float) -> void:
	if duration <= 0.0:
		return
	Engine.time_scale = clampf(scale, 0.05, 1.0)
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


# --- letterbox (boss intros + cutscenes) ------------------------------------

var _letterbox: CanvasLayer
var _lb_top: ColorRect
var _lb_bottom: ColorRect


## Cinematic black bars, slid in/out. Used by boss intros and the cutscene player.
func letterbox(on: bool) -> void:
	if _letterbox == null:
		_letterbox = CanvasLayer.new()
		_letterbox.layer = 35
		add_child(_letterbox)
		_lb_top = ColorRect.new()
		_lb_top.color = Color(0.005, 0.005, 0.01)
		_lb_top.size = Vector2(2000, 54)
		_lb_top.position = Vector2(0, -54)
		_letterbox.add_child(_lb_top)
		_lb_bottom = ColorRect.new()
		_lb_bottom.color = Color(0.005, 0.005, 0.01)
		_lb_bottom.size = Vector2(2000, 54)
		_lb_bottom.position = Vector2(0, 540)
		_letterbox.add_child(_lb_bottom)
	var tw := create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	tw.tween_property(_lb_top, "position:y", 0.0 if on else -54.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_lb_bottom, "position:y", 486.0 if on else 540.0, 0.4).set_trans(Tween.TRANS_CUBIC)

