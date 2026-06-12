extends Node2D
## Cairn — PALE ORE: the mineral the Forger feeds the blade. Six pieces exist
## in all the deep. It glows faintly with what it remembers being.

@export var ore_id: String = "ore_1"
@export var appears_flag: String = ""

var _t := 0.0
var _claimed := false

@onready var _zone: Area2D = $Zone
@onready var _light: PointLight2D = $Light


func _ready() -> void:
	add_to_group("cache")
	if appears_flag != "" and not PlayerProgress.has_flag(appears_flag):
		queue_free()
		return
	if PlayerProgress.has_flag("ore_%s" % ore_id):
		queue_free()
		return
	_zone.area_entered.connect(_on_enter)


func _on_enter(area: Area2D) -> void:
	if _claimed:
		return
	var b := area.get_parent()
	if not (b and b.is_in_group("player")):
		return
	_claimed = true
	PlayerProgress.set_flag("ore_%s" % ore_id)
	PlayerProgress.pale_ore += 1
	var banner := get_tree().get_first_node_in_group("location_title")
	if banner and banner.has_method("reveal"):
		banner.reveal("PALE ORE", "%d held — the Forger waits in the Warrens" % PlayerProgress.pale_ore)
	AudioManager.play("item_pickup", -6.0)
	SaveManager.autosave()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	_light.energy = 0.5 + sin(_t * 1.6) * 0.18
	queue_redraw()


func _draw() -> void:
	if _claimed:
		return
	var bob := sin(_t * 1.4) * 2.0
	var c := Vector2(0, -16 + bob)
	var pale := Color(0.88, 0.9, 0.95)
	var pale_d := Color(0.6, 0.64, 0.72)
	# A rough pale nugget with one polished facet.
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-7, 2), c + Vector2(-4, -6), c + Vector2(3, -7),
		c + Vector2(8, -1), c + Vector2(4, 5), c + Vector2(-3, 6)]), pale_d)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-4, -6), c + Vector2(3, -7), c + Vector2(0, 0)]), pale)
	draw_circle(c, 13.0, Color(0.9, 0.92, 1.0, 0.07 + 0.04 * sin(_t * 1.6)))
