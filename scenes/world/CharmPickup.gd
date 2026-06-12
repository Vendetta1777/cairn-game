extends Node2D
## Cairn — a carved CHARM (or a NOTCH STONE) waiting in the world. Walk over
## it: charms join your pouch (attune at any lit Remnant Stone); notch stones
## widen what you can wear. Persisted by flag. Drawn as a small carved token
## on a thread, or a notched ring of stone.

const Charms = preload("res://scenes/systems/CharmDB.gd")

@export var charm_id: String = ""        ## "" + notch=true -> a Notch Stone
@export var notch: bool = false
@export var pickup_id: String = ""       ## persistence key (defaults to charm_id)
@export var appears_flag: String = ""    ## optional story gate

var _t := 0.0
var _claimed := false

@onready var _zone: Area2D = $Zone
@onready var _light: PointLight2D = $Light


func _key() -> String:
	return pickup_id if pickup_id != "" else (charm_id if charm_id != "" else "notch")


func _ready() -> void:
	add_to_group("cache")   # the Pale Lantern reveals these too
	if appears_flag != "" and not PlayerProgress.has_flag(appears_flag):
		queue_free()
		return
	if PlayerProgress.has_flag("charm_pickup_%s" % _key()) \
			or (charm_id != "" and PlayerProgress.has_charm(charm_id)):
		queue_free()
		return
	_light.color = Color(0.8, 0.7, 1.0) if not notch else Color(0.9, 0.85, 0.6)
	_zone.area_entered.connect(_on_enter)


func _on_enter(area: Area2D) -> void:
	if _claimed:
		return
	var b := area.get_parent()
	if not (b and b.is_in_group("player")):
		return
	_claimed = true
	PlayerProgress.set_flag("charm_pickup_%s" % _key())
	var banner := get_tree().get_first_node_in_group("location_title")
	if notch:
		PlayerProgress.notch_stones += 1
		if banner and banner.has_method("reveal"):
			var slots := PlayerProgress.charm_slots()
			banner.reveal("A NOTCH STONE", "%d notch%s to wear charms in" % [slots, "es" if slots != 1 else ""])
	else:
		PlayerProgress.grant_charm(charm_id)
		if banner and banner.has_method("reveal"):
			banner.reveal(str(Charms.get_charm(charm_id).get("name", charm_id)).to_upper(),
				"CARVED — attune at a remnant stone")
	AudioManager.play("skill_buy", -8.0)
	SaveManager.autosave()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	_light.energy = 0.55 + sin(_t * 2.2) * 0.2
	queue_redraw()


func _draw() -> void:
	if _claimed:
		return
	var bob := sin(_t * 1.7) * 2.5
	if notch:
		# A ring of stone with carved notches.
		var c := Vector2(0, -22 + bob)
		draw_arc(c, 8.0, 0, TAU, 18, Color(0.8, 0.75, 0.55), 3.0)
		for i in 6:
			var a := TAU * i / 6.0
			draw_circle(c + Vector2.from_angle(a) * 8.0, 1.4, Color(0.5, 0.45, 0.3))
		draw_circle(c, 11.0, Color(0.9, 0.85, 0.6, 0.08 + 0.05 * sin(_t * 2.2)))
	else:
		# A carved token swinging on its thread.
		var c := Vector2(sin(_t * 1.3) * 3.0, -20 + bob)
		draw_line(Vector2(0, -34), c + Vector2(0, -7), Color(0.4, 0.38, 0.5), 1.0)
		draw_circle(c, 7.0, Color(0.32, 0.28, 0.45))
		draw_arc(c, 7.0, 0, TAU, 14, Color(0.6, 0.55, 0.8), 1.4)
		draw_circle(c + Vector2(-1.5, -1.5), 2.0, Color(0.85, 0.8, 1.0))
		draw_circle(c, 12.0, Color(0.7, 0.6, 1.0, 0.07 + 0.05 * sin(_t * 2.2)))
