extends Node2D
class_name Keeper
## Cairn — The Keeper: a lantern-bearing remnant who trades Shards for vitality
## (a permanent +1 heart). Walk up and press E. (A simple take on the GDD's
## Sanctum upgrade flow.)

@export var heart_cost: int = 2   ## Shards per heart

var _player: Node = null

@onready var _light: PointLight2D = get_node_or_null("Light")
@onready var _prompt: Label = get_node_or_null("Prompt")


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
		_player = b
		if _prompt:
			_prompt.visible = true


func _on_exit(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player") and b == _player:
		_player = null
		if _prompt:
			_prompt.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _player and event.is_action_pressed("interact"):
		_try_upgrade()


func _try_upgrade() -> void:
	var stats = _player.get_node_or_null("Stats")
	if stats == null:
		return
	if stats.spend_shards(heart_cost):
		stats.add_heart(1)
		_flash(Color(0.5, 0.95, 0.6))    # success
	else:
		_flash(Color(0.95, 0.4, 0.4))    # not enough Shards


func _flash(c: Color) -> void:
	if _light == null:
		return
	_light.color = c
	var tw := create_tween()
	tw.tween_property(_light, "color", Color(0.88, 0.62, 0.32), 0.5)
