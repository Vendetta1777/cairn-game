extends Node2D
class_name LoreNPC
## Cairn — an NPC (a Remnant: a fragment of a former resident). Walk up, press
## E: the dialogue band opens with portrait + name + typewriter. v2 adds:
##   - appears_flag / vanish_flag — NPCs come and go with the story (a vanished
##     NPC here usually re-appears elsewhere: "moved" via paired instances)
##   - alt_lines once alt_requires_flag is set (progress-aware dialogue)
##   - an optional CHOICE at the end (shop hooks, the ending decision):
##     choice_prompt + choice_options; on pick, choice_flags[i] is set (if any)
##     and `chose(i)` is emitted for bespoke handlers (Cartographer, Ghost…).

signal chose(index: int)

@export var npc_id: String = ""
@export var display_name: String = "REMNANT"
@export var portrait: String = ""            ## pilgrim/ghost/digger/cartographer/knight/sovereign/merchant
@export var lines: PackedStringArray = [""]
@export var location_name := "THE HOLLOWED GATE"
@export var location_subtitle := "CAIRN"
@export var reveals_location := true

@export_group("Story state")
@export var appears_flag: String = ""        ## only present once this flag is set
@export var vanish_flag: String = ""         ## gone once this flag is set
@export var alt_requires_flag: String = ""
@export var alt_lines: PackedStringArray = []

@export_group("Choice")
@export var choice_prompt: String = ""
@export var choice_options: PackedStringArray = []
@export var choice_flags: PackedStringArray = []   ## flag set per option ("" = none)

var _near := false
var _talking := false
var _revealed := false
var _box

@onready var _prompt: Label = get_node_or_null("Prompt")


func _box_ref():
	if _box == null or not is_instance_valid(_box):
		_box = get_tree().get_first_node_in_group("dialogue")
	return _box


func _ready() -> void:
	if appears_flag != "" and not PlayerProgress.has_flag(appears_flag):
		queue_free()
		return
	if vanish_flag != "" and PlayerProgress.has_flag(vanish_flag):
		queue_free()
		return
	var det := get_node_or_null("Detector") as Area2D
	if det:
		det.area_entered.connect(_on_enter)
		det.area_exited.connect(_on_exit)
	if _prompt:
		_prompt.visible = false


func _current_lines() -> PackedStringArray:
	if alt_requires_flag != "" and PlayerProgress.has_flag(alt_requires_flag) \
			and not alt_lines.is_empty():
		return alt_lines
	return lines


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
		_talking = false
		if _prompt:
			_prompt.visible = false
		var box = _box_ref()
		if box:
			box.close()


func _unhandled_input(event: InputEvent) -> void:
	if not _near:
		return
	if not event.is_action_pressed("interact"):
		return
	var box = _box_ref()
	if box == null:
		return
	if box.has_method("in_choice") and box.in_choice():
		return   # the box handles choice input itself
	if not _talking:
		_talking = true
		if npc_id != "":
			PlayerProgress.set_flag("talked_%s" % npc_id)
		if not _revealed and reveals_location:
			_revealed = true
			var title = get_tree().get_first_node_in_group("location_title")
			if title and title.has_method("reveal"):
				title.reveal(location_name, location_subtitle)
		box.open_dialogue(display_name, portrait, _current_lines())
		if _prompt:
			_prompt.visible = false
		get_viewport().set_input_as_handled()
		return
	# Mid-conversation: advance; at the end, offer the choice (if any).
	get_viewport().set_input_as_handled()
	if not box.advance():
		if choice_prompt != "" and not choice_options.is_empty():
			box.show_choice(choice_prompt, choice_options)
			# One-shot connection for THIS conversation.
			box.choice_made.connect(_on_choice, CONNECT_ONE_SHOT)
		else:
			_end_talk()


func _on_choice(idx: int) -> void:
	if idx < choice_flags.size() and choice_flags[idx] != "":
		PlayerProgress.set_flag(choice_flags[idx])
		SaveManager.autosave()
	chose.emit(idx)
	_end_talk()


func _end_talk() -> void:
	_talking = false
	if _prompt and _near:
		_prompt.visible = true
