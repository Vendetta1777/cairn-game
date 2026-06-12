extends Node2D
class_name RemnantStone
## Cairn — Remnant Stone (GDD checkpoint, "bonfire equivalent"). When the player
## touches it, it lights up and registers itself as the active respawn point in
## GameManager. Reusable across areas.

@export var respawn_offset := Vector2(0, -6)

var _active := false
var _player_near := false

@onready var _light: PointLight2D = get_node_or_null("Light")
@onready var _detector: Area2D = get_node_or_null("Detector")
@onready var _cap: Polygon2D = get_node_or_null("Cap")


func _ready() -> void:
	add_to_group("checkpoint")   # for the map overlay
	AudioManager.attach_loop(self, "shrine_loop", -22.0)
	# Already-set checkpoint (returning / loaded save) stays lit. Deferred:
	# the terrain restores the saved checkpoint in ITS deferred setup, and we
	# must check after that, not before.
	call_deferred("_check_lit")
	if _detector:
		_detector.area_entered.connect(_on_area_entered)
		_detector.area_exited.connect(_on_area_exited)


func _check_lit() -> void:
	if GameManager.has_checkpoint \
			and GameManager.checkpoint_position.distance_to(global_position + respawn_offset) < 4.0:
		_set_lit(true)


func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	if body and body.is_in_group("player"):
		_activate()
		_maybe_heal(body)
		_player_near = true


func _on_area_exited(area: Area2D) -> void:
	var body := area.get_parent()
	if body and body.is_in_group("player"):
		_player_near = false


## E at a lit stone opens the ATTUNEMENT screen (charms equip only here).
func _unhandled_input(event: InputEvent) -> void:
	if _player_near and _active and event.is_action_pressed("interact"):
		var ui := get_tree().get_first_node_in_group("charm_ui")
		if ui and ui.has_method("open_charms"):
			ui.open_charms()
			get_viewport().set_input_as_handled()


## A remnant's small mercy: if you arrive hurt and down to 2 hearts or fewer,
## it restores one heart. (Only when you've actually lost health.)
func _maybe_heal(body: Node) -> void:
	var stats = body.get_node_or_null("Stats")
	if stats == null:
		return
	if stats.health < stats.max_health and stats.health <= 4:   # 4 halves = 2 hearts
		stats.heal(2)                                            # +1 heart
		# A warm restorative pulse on the stone's light.
		if _light:
			var c := _light.color
			var tw := create_tween()
			tw.tween_property(_light, "color", Color(0.6, 1.0, 0.7), 0.15)
			tw.tween_property(_light, "energy", 3.0, 0.15)
			tw.tween_property(_light, "energy", 2.0 if _active else 1.0, 0.5)
			tw.parallel().tween_property(_light, "color", c, 0.5)


func _activate() -> void:
	if _active:
		return
	GameManager.set_checkpoint(global_position + respawn_offset)
	AudioManager.play("checkpoint", -8.0)
	_set_lit(true)


func _set_lit(on: bool) -> void:
	_active = on
	if _light:
		_light.color = Color(0.45, 0.9, 0.85) if on else Color(0.7, 0.45, 0.78)
		if on:
			var tw := create_tween()
			tw.tween_property(_light, "energy", 2.0, 0.4)
	if _cap:
		_cap.color = Color(0.5, 0.92, 0.85) if on else Color(0.55, 0.35, 0.62)
