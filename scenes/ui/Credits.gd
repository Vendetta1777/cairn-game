extends Control
## Cairn — the credits roll. Plays after either ending's cutscene, over the
## ending's closing tint. At the end: continue to the title, or — the deep is
## never really done — begin NEW GAME+ (everything kept, the world reborn,
## every horror 40% meaner per cycle).

const FONT := preload("res://assets/fonts/silkscreen.ttf")

const LINES := [
	["CAIRN", 26],
	["a descent", 11],
	["", 10],
	["DESIGN · CODE · WORLD", 10],
	["Vendetta", 14],
	["", 10],
	["ENGINE FELLOW-TRAVELLER", 10],
	["Claude", 14],
	["", 10],
	["PIXEL FOUNDATIONS", 10],
	["Ansimuz — GothicVania (CC0)", 11],
	["", 10],
	["SOUND & MUSIC", 10],
	["synthesized in the deep — no samples, no survivors", 11],
	["", 10],
	["MADE WITH", 10],
	["Godot 4", 14],
	["", 18],
	["for everyone who reads the tells", 11],
	["and strikes in the vulnerable window", 11],
	["", 24],
	["the cairn marks a grave. or a path.", 12],
	["now you know which.", 12],
]

var _scroll := -300.0
var _done := false
var _t := 0.0


func _ready() -> void:
	AudioManager.play_music("menu")


func _process(delta: float) -> void:
	_t += delta
	if not _done:
		_scroll += delta * 36.0
		if _scroll > LINES.size() * 34.0 + 200.0:
			_done = true
	queue_redraw()
	if _done:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump"):
			SceneFlow.travel("res://scenes/ui/TitleScreen.tscn", "up")
		elif Input.is_action_just_pressed("attack") and PlayerProgress.has_flag("game_beaten"):
			PlayerProgress.start_ng_plus()
			SaveManager.autosave()
			SceneFlow.travel("res://scenes/world/area_01_hollowed_gate/Area1.tscn", "down")


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.012, 0.012, 0.02))
	# The ending's afterimage: the fallen crown, faint.
	var cx := size.x * 0.5
	var gold := Color(0.5, 0.42, 0.22, 0.25 + 0.05 * sin(_t))
	draw_rect(Rect2(cx - 22, size.y - 90, 44, 13), gold)
	for k in 3:
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 20 + k * 16, size.y - 90), Vector2(cx - 14 + k * 16, size.y - 104),
			Vector2(cx - 8 + k * 16, size.y - 90)]), gold)
	var y := size.y - _scroll
	for entry in LINES:
		var text: String = entry[0]
		var sz: int = entry[1]
		if text != "":
			draw_string(FONT, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, sz,
				Color(0.8, 0.8, 0.9) if sz >= 14 else Color(0.5, 0.53, 0.66))
		y += 34.0
	if _done:
		var pulse := 0.5 + 0.3 * sin(_t * 2.0)
		draw_string(FONT, Vector2(0, size.y * 0.5 - 20), "the descent is over",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color(0.8, 0.82, 0.95))
		draw_string(FONT, Vector2(0, size.y * 0.5 + 20), "E — return to the surface (title)",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color(0.6, 0.64, 0.78, pulse))
		if PlayerProgress.has_flag("game_beaten"):
			draw_string(FONT, Vector2(0, size.y * 0.5 + 44),
				"J — DESCEND AGAIN  (New Game+: keep everything; the deep grows 40% crueller)",
				HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, Color(0.85, 0.6, 0.5, pulse))
