extends Node2D
class_name RemnantStone
## Cairn — Remnant Stone (GDD checkpoint, "bonfire equivalent"). When the player
## touches it, it lights up and registers itself as the active respawn point in
## GameManager. Reusable across areas.

@export var respawn_offset := Vector2(0, -6)

var _active := false

@onready var _light: PointLight2D = get_node_or_null("Light")
@onready var _detector: Area2D = get_node_or_null("Detector")
@onready var _cap: Polygon2D = get_node_or_null("Cap")


func _ready() -> void:
	# Already-set checkpoint (e.g. returning) stays lit.
	if GameManager.has_checkpoint and GameManager.checkpoint_position.distance_to(global_position + respawn_offset) < 4.0:
		_set_lit(true)
	if _detector:
		_detector.area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	if body and body.is_in_group("player"):
		_activate()


func _activate() -> void:
	if _active:
		return
	GameManager.set_checkpoint(global_position + respawn_offset)
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
