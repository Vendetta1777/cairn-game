extends CanvasLayer
## Cairn — area-name reveal card (metroidvania style). reveal() fades the title
## in, holds, then fades out. Triggered when the player first learns where they are.

@onready var _root: Control = $Center
@onready var _title: Label = $Center/Title
@onready var _sub: Label = $Center/Sub


func _ready() -> void:
	add_to_group("location_title")
	_root.modulate.a = 0.0


func reveal(title: String, sub: String = "") -> void:
	_title.text = title
	_sub.text = sub
	_root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 0.9)
	tw.tween_interval(2.0)
	tw.tween_property(_root, "modulate:a", 0.0, 1.1)
