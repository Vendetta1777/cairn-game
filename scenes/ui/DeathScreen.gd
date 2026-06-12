extends CanvasLayer
## Cairn — the DEATH SEQUENCE (GDD: dying should feel like an event, not a
## reload). On death: 0.5s of slow motion while the world drains to grey, then a
## fade to black and the verdict — YOU PERISHED, where you fell, how long you
## lasted, and one of the old kingdom's epitaphs. Any key asks the level
## (CaveTerrain) to respawn; it fades us back in from black at the shrine.
##
## Lives on layer 30 with PROCESS_MODE_ALWAYS: it keeps animating while the
## tree is paused underneath it. All tweens ignore time_scale (slow-mo / pause).

signal respawn_requested

const QUOTES := [
	"The deep does not hunger. It simply keeps.",
	"Every cairn was raised by hands that believed someone would return.",
	"The kingdom did not fall. It sank — and called the sinking sleep.",
	"Light is a debt the dark always collects.",
	"The Wardens still keep their posts. No one told them the war was lost.",
	"What the stone remembers, the flesh repays.",
	"You were not the first to wake down here. You will not be the last.",
	"Names are for the surface. The deep takes those first.",
	"The bells below still toll. For whom, the water will not say.",
	"Death is a door the deep leaves unlatched.",
]

var _armed := false      ## accepting the "any key" respawn press
var _active := false

@onready var _desat: ColorRect = $Desat
@onready var _black: ColorRect = $Black
@onready var _center: Control = $Center
@onready var _title: Label = $Center/Title
@onready var _sub: Label = $Center/Sub
@onready var _quote: Label = $Center/Quote
@onready var _hint: Label = $Center/Hint


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_desat.material.set_shader_parameter("amount", 0.0)
	_black.modulate.a = 0.0
	_center.modulate.a = 0.0


func _rt_tween() -> Tween:
	return create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)


## The whole sequence. area_name e.g. "THE HOLLOWED GATE"; run_time in seconds.
func play_death(area_name: String, run_time: float) -> void:
	if _active:
		return
	_active = true
	_armed = false
	visible = true
	_title.text = "YOU PERISHED"
	var mins := int(run_time) / 60
	var secs := int(run_time) % 60
	_sub.text = "%s   —   SURVIVED %02d:%02d" % [area_name, mins, secs]
	_quote.text = "\"%s\"" % QUOTES[randi() % QUOTES.size()]
	_hint.text = "press any key"

	# Beat 1 — 0.5s of slow motion while colour drains out of the world; the
	# soundscape ducks under with it.
	AudioManager.duck(-12.0, 2.2)
	Engine.time_scale = 0.18
	var tw := _rt_tween()
	tw.tween_method(_set_desat, 0.0, 1.0, 0.5)
	# Beat 2 — the world stops; black closes over the grey.
	tw.tween_callback(func():
		get_tree().paused = true
		Engine.time_scale = 1.0)
	tw.tween_property(_black, "modulate:a", 1.0, 0.7)
	# Beat 3 — the verdict fades up, then the hint arms.
	tw.tween_property(_center, "modulate:a", 1.0, 0.9)
	tw.tween_callback(func(): _armed = true)


func _set_desat(v: float) -> void:
	_desat.material.set_shader_parameter("amount", v)


func _input(event: InputEvent) -> void:
	if not _armed:
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventJoypadButton and event.pressed)
	if pressed:
		_armed = false
		respawn_requested.emit()


## CaveTerrain calls this once the player is back at the shrine: fade in from
## black with the world already restored.
func dismiss() -> void:
	if not _active:
		return
	_set_desat(0.0)
	var tw := _rt_tween()
	tw.tween_property(_center, "modulate:a", 0.0, 0.35)
	tw.tween_property(_black, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func():
		visible = false
		_active = false)
