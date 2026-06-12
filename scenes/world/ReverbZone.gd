extends Area2D
## Cairn — a REVERB ZONE: walk in and the SFX bus reshapes itself over 1.5s.
##   "cathedral" — long wet tails (great halls, boss chambers)
##   "small"     — tight and dry (crawl tunnels)
##   "flooded"   — muffled low-pass (underwater / drowned rooms)
## Leaving restores the default cave acoustics. Pure Area2D + exported size.

@export var preset: String = "cathedral"
@export var size := Vector2(600, 280)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	cs.position = size * 0.5
	add_child(cs)
	area_entered.connect(_on_enter)
	area_exited.connect(_on_exit)


func _on_enter(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		AudioManager.set_reverb_zone(preset)


func _on_exit(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		AudioManager.set_reverb_zone("default")
