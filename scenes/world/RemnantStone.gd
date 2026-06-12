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
	add_to_group("checkpoint")   # for the map overlay
	AudioManager.attach_loop(self, "shrine_loop", -22.0)
	# Already-set checkpoint (e.g. returning) stays lit.
	if GameManager.has_checkpoint and GameManager.checkpoint_position.distance_to(global_position + respawn_offset) < 4.0:
		_set_lit(true)
	if _detector:
		_detector.area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	if body and body.is_in_group("player"):
		_activate()
		_maybe_heal(body)


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
