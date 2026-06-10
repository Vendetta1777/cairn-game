extends Node2D
class_name LoreNPC
## Cairn — a lore-giving NPC (a Remnant: a fragment of a former resident). Walk
## up, press E to read each line in the dialogue band, looping when finished.

@export var lines: PackedStringArray = [""]
@export var location_name := "THE HOLLOWED GATE"
@export var location_subtitle := "CAIRN"

var _near := false
var _idx := 0
var _revealed := false
var _box

@onready var _prompt: Label = get_node_or_null("Prompt")


func _box_ref():
	# Looked up lazily — the DialogueBox may join its group after this NPC's _ready.
	if _box == null or not is_instance_valid(_box):
		_box = get_tree().get_first_node_in_group("dialogue")
	return _box


func _ready() -> void:
	var det := get_node_or_null("Detector") as Area2D
	if det:
		det.area_entered.connect(_on_enter)
		det.area_exited.connect(_on_exit)
	if _prompt:
		_prompt.visible = false


func _on_enter(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		_near = true
		if _prompt:
			_prompt.visible = true


func _on_exit(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		_near = false
		_idx = 0
		if _prompt:
			_prompt.visible = false
		var box = _box_ref()
		if box:
			box.close()


func _unhandled_input(event: InputEvent) -> void:
	if not _near:
		return
	if event.is_action_pressed("interact"):
		var box = _box_ref()
		if box == null:
			return
		# First time we talk: reveal where we are.
		if not _revealed:
			_revealed = true
			var title = get_tree().get_first_node_in_group("location_title")
			if title and title.has_method("reveal"):
				title.reveal(location_name, location_subtitle)
		if _idx < lines.size():
			box.show_text(lines[_idx])
			_idx += 1
			if _prompt:
				_prompt.visible = false
		else:
			box.close()
			_idx = 0
			if _prompt:
				_prompt.visible = true
