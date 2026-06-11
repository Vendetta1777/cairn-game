extends CanvasLayer
## Cairn — "AREA COMPLETE" card. Listens for QuestTracker.area_completed and
## plays a slow, earned fade: the screen dims, the title rises, a subline names
## what you just cleared. The capstone of the M5 loop — proof the area is a real,
## finishable thing and not a sandbox.

@onready var _dim: ColorRect = $Dim
@onready var _title: Label = $Center/Title
@onready var _sub: Label = $Center/Sub


func _ready() -> void:
	visible = false
	_dim.color.a = 0.0
	_title.modulate.a = 0.0
	_sub.modulate.a = 0.0
	QuestTracker.area_completed.connect(_on_area_completed)


func _on_area_completed(_area_id: String) -> void:
	visible = true
	QuestTracker.set_objective("")   # clear the tracker
	var tw := create_tween()
	tw.tween_property(_dim, "color:a", 0.72, 1.0)
	tw.parallel().tween_property(_title, "modulate:a", 1.0, 1.2).set_delay(0.4)
	tw.parallel().tween_property(_sub, "modulate:a", 1.0, 1.2).set_delay(0.9)
