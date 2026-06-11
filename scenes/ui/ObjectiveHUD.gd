extends CanvasLayer
## Cairn — ObjectiveHUD. Shows the current QuestTracker objective in the top-right
## as a quiet "» do this next" line. Slides + fades in whenever the objective
## changes and briefly brightens so the player notices the new step.

@onready var _marker: Control = $Marker
@onready var _label: Label = $Marker/Label

const REST := Vector2(0, 0)


func _ready() -> void:
	QuestTracker.objective_changed.connect(_on_objective_changed)
	if QuestTracker.current_objective != "":
		_set_text(QuestTracker.current_objective)
	else:
		_marker.modulate.a = 0.0


func _on_objective_changed(text: String) -> void:
	if text == "":
		create_tween().tween_property(_marker, "modulate:a", 0.0, 0.5)
		return
	_set_text(text)


func _set_text(text: String) -> void:
	_label.text = text
	_marker.position = REST + Vector2(16, 0)
	_marker.modulate = Color(1.0, 1.0, 0.8, 0.0)  # warm flash on entry
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_marker, "position", REST, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_marker, "modulate:a", 1.0, 0.35)
	# settle to the resting steel colour after the flash
	tw.chain().tween_property(_marker, "modulate", Color(0.78, 0.82, 0.92, 0.92), 0.9)
