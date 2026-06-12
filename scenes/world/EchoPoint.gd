extends Node2D
## Cairn — an ECHO POINT: a place where the past pooled too deep to drain.
## With the ECHO TOUCH (taught by the Pale Archivist), HOLD E for 1.5s and a
## vision plays — a translucent panel of what happened here before the fall.
## Every echo is recorded in the journal (M, then E). Without the Touch, the
## shimmer only whispers. Hidden echoes also wake a reward when first seen.

@export var echo_id: String = ""
@export var title: String = "A MEMORY"
@export var text: String = ""
@export var art: String = "kingdom"      ## a Cutscene painter key
@export var reveals_cache: bool = false  ## hidden wall echoes leave a gift
@export var appears_after_echoes: int = 0  ## the 16th waits for the other 15

const CACHE := preload("res://scenes/world/ShardCache.tscn")

var _near := false
var _charge := 0.0
var _t := 0.0

@onready var _zone: Area2D = $Zone


func _ready() -> void:
	add_to_group("echo_point")
	if appears_after_echoes > 0 and PlayerProgress.echoes_seen.size() < appears_after_echoes:
		queue_free()
		return
	_zone.area_entered.connect(func(a):
		var b = a.get_parent()
		if b and b.is_in_group("player"):
			_near = true)
	_zone.area_exited.connect(func(a):
		var b = a.get_parent()
		if b and b.is_in_group("player"):
			_near = false
			_charge = 0.0)


func seen() -> bool:
	return PlayerProgress.echoes_seen.has(echo_id)


func _process(delta: float) -> void:
	_t += delta
	if _near and Input.is_action_pressed("interact") and not get_tree().paused:
		if not PlayerProgress.has_flag("echo_touch"):
			_charge = 0.0
		else:
			_charge += delta
			if _charge >= 1.5:
				_charge = 0.0
				_play_vision()
	else:
		_charge = maxf(0.0, _charge - delta * 3.0)
	queue_redraw()


func _play_vision() -> void:
	var first := not seen()
	PlayerProgress.echoes_seen[echo_id] = title
	AudioManager.play("heal", -8.0, 0.0, &"SFX", 0.7)
	var cut := get_tree().get_first_node_in_group("cutscene")
	if cut and cut.has_method("play"):
		cut.play([{"art": art, "text": "%s  —  %s" % [title, text], "hold": 5.0}])
	if first:
		SaveManager.autosave()
		if reveals_cache:
			var cache := CACHE.instantiate()
			cache.cache_id = "echo_%s" % echo_id
			cache.shards = 10
			get_parent().add_child(cache)
			cache.global_position = global_position + Vector2(24, 0)
		var n := PlayerProgress.echoes_seen.size()
		var banner := get_tree().get_first_node_in_group("location_title")
		if banner and banner.has_method("reveal"):
			banner.reveal("THE PAST, KEPT", "echo %d — the journal remembers" % n)


func _draw() -> void:
	var has_touch := PlayerProgress.has_flag("echo_touch")
	var was_seen := seen()
	# A pooled shimmer: drifting motes in a slow ring, dimmer once seen.
	var base_a := 0.18 if was_seen else 0.5
	for i in 5:
		var ang := _t * 0.8 + TAU * i / 5.0
		var p := Vector2(cos(ang) * 10.0, -14.0 + sin(ang * 1.3) * 7.0)
		draw_circle(p, 1.4, Color(0.7, 0.85, 1.0, base_a * (0.5 + 0.5 * sin(_t * 2.0 + i))))
	draw_circle(Vector2(0, -14), 14.0, Color(0.6, 0.8, 1.0, 0.05 + 0.03 * sin(_t * 1.5)))
	if _near:
		if not has_touch:
			# It stirs, but you lack the Touch.
			draw_circle(Vector2(0, -14), 3.0, Color(0.7, 0.85, 1.0, 0.2 + 0.1 * sin(_t * 6.0)))
		elif _charge > 0.0:
			# The charge ring closes as you hold.
			draw_arc(Vector2(0, -14), 9.0, -PI / 2.0, -PI / 2.0 + TAU * (_charge / 1.5), 24,
				Color(0.85, 0.95, 1.0, 0.9), 2.0)
