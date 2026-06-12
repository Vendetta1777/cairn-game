extends Node2D
## Cairn — a doorway between scenes. While the player stands in it, a prompt
## shows; pressing interact changes to target_scene. PlayerProgress + SaveManager
## are autoloads, so progression carries across the transition. Used to step
## between the world and the Sanctum hub.

@export_file("*.tscn") var target_scene: String = ""
@export var label: String = "Descend"
@export var glow_color: Color = Color(0.55, 0.7, 1.0)
## Where the player should appear in the TARGET scene (so they arrive next to the
## matching portal, not at the level start). Zero = use the scene's default spawn.
@export var arrival_marker: Vector2 = Vector2.ZERO

var _player_in := false
var _t := 0.0

@onready var _zone: Area2D = $Zone
@onready var _prompt: Label = $Prompt/Text


func _ready() -> void:
	add_to_group("portal")   # for the map overlay
	_zone.area_entered.connect(_on_enter)
	_zone.area_exited.connect(_on_exit)
	_prompt.text = "[E] %s" % label
	$Prompt.modulate.a = 0.0
	set_process(true)


func _on_enter(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		_player_in = true
		create_tween().tween_property($Prompt, "modulate:a", 1.0, 0.2)


func _on_exit(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		_player_in = false
		create_tween().tween_property($Prompt, "modulate:a", 0.0, 0.2)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _player_in and Input.is_action_just_pressed("interact") and target_scene != "":
		# Persist before leaving, and tell the next scene where to drop the player.
		SaveManager.autosave()
		if arrival_marker != Vector2.ZERO:
			GameManager.pending_spawn = arrival_marker
		AudioManager.play("door", -6.0)
		SceneFlow.travel(target_scene, "up")


func _draw() -> void:
	var glow := 0.6 + sin(_t * 2.0) * 0.25
	# Arched portal of cool light.
	var W := 26.0
	var H := 64.0
	for i in range(6):
		var f := i / 6.0
		var a := (1.0 - f) * 0.5 * glow
		draw_rect(Rect2(-W * (1.0 - f * 0.5), -H * (1.0 - f * 0.3), W * 2.0 * (1.0 - f * 0.5), H * (1.0 - f * 0.3)),
			Color(glow_color.r, glow_color.g, glow_color.b, a))
	# Bright core slit.
	draw_rect(Rect2(-4, -H, 8, H), Color(0.9, 0.95, 1.0, 0.8 * glow))
	# Drifting motes.
	for k in range(5):
		var ang := _t * 0.6 + k * 1.3
		var mp := Vector2(sin(ang) * W * 0.7, -H * 0.5 - cos(ang * 0.7) * H * 0.4)
		draw_circle(mp, 1.5, Color(0.85, 0.92, 1.0, 0.7 * glow))
