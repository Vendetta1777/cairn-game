extends CanvasLayer
## Cairn — dialogue display (GDD Section 10: text in a faded band at the bottom,
## no boxy frame). NPCs push lines to it; press the interact key to advance.

@onready var _band: Control = $Band
@onready var _label: Label = $Band/Label


func _ready() -> void:
	add_to_group("dialogue")
	_band.visible = false


func show_text(t: String) -> void:
	_label.text = t
	_band.visible = true


func close() -> void:
	_band.visible = false


func is_open() -> bool:
	return _band.visible
