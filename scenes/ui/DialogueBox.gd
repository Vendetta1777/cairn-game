extends CanvasLayer
## Cairn — dialogue display v2. A faded band at the bottom of the screen with:
##   - a procedurally painted PORTRAIT + speaker name
##   - TYPEWRITER text (first E completes the line, next E advances)
##   - a short voice BARK as each line begins
##   - hold E (0.8s) to skip the whole conversation
##   - a CHOICE mode: 2–3 options picked with W/S + E (endings hang off these)
## Legacy API kept: show_text()/close()/is_open() still work for simple NPCs.

signal choice_made(index: int)
signal closed

const FONT := preload("res://assets/fonts/silkscreen.ttf")
const CHARS_PER_SEC := 44.0

var _lines: PackedStringArray = []
var _idx := 0
var _chars := 0.0
var _speaker := ""
var _portrait := ""
var _open_flag := false
var _hold := 0.0
var _t := 0.0

var _choice_mode := false
var _choice_prompt := ""
var _choices: PackedStringArray = []
var _choice_sel := 0

@onready var _band: Control = $Band
@onready var _label: Label = $Band/Label
@onready var _canvas: Control = $Band/Painter


func _ready() -> void:
	add_to_group("dialogue")
	_band.visible = false
	_canvas.draw.connect(_paint)


# --- conversation API -----------------------------------------------------------

## Open a full conversation. Returns immediately; advance() steps it.
func open_dialogue(speaker: String, portrait: String, lines: PackedStringArray) -> void:
	_speaker = speaker
	_portrait = portrait
	_lines = lines
	_idx = 0
	_chars = 0.0
	_choice_mode = false
	_open_flag = true
	_band.visible = true
	_bark()


## E pressed: complete the typewriter, else advance. Returns false when done.
func advance() -> bool:
	if _choice_mode:
		return true
	if _idx >= _lines.size():
		close()
		return false
	if _chars < _lines[_idx].length():
		_chars = 99999.0
		return true
	_idx += 1
	if _idx >= _lines.size():
		close()
		return false
	_chars = 0.0
	_bark()
	return true


## Present a choice (keeps the band open). Emits choice_made(index).
func show_choice(prompt: String, options: PackedStringArray) -> void:
	_choice_mode = true
	_choice_prompt = prompt
	_choices = options
	_choice_sel = 0
	_open_flag = true
	_band.visible = true
	AudioManager.play("chest", -16.0)


func close() -> void:
	if not _open_flag and not _band.visible:
		return
	_open_flag = false
	_choice_mode = false
	_band.visible = false
	closed.emit()


func is_open() -> bool:
	return _band.visible


func in_choice() -> bool:
	return _choice_mode


# --- legacy API (simple one-line NPCs) -------------------------------------------

func show_text(t: String) -> void:
	_speaker = ""
	_portrait = ""
	_lines = PackedStringArray([t])
	_idx = 0
	_chars = 0.0
	_choice_mode = false
	_open_flag = true
	_band.visible = true


# --- input / process --------------------------------------------------------------

func _process(delta: float) -> void:
	if not _band.visible:
		return
	_t += delta
	_chars += delta * CHARS_PER_SEC
	# Hold E to skip everything.
	if Input.is_action_pressed("interact") and not _choice_mode:
		_hold += delta
		if _hold > 0.8:
			_hold = 0.0
			close()
	else:
		_hold = 0.0
	if _choice_mode:
		if Input.is_action_just_pressed("move_up"):
			_choice_sel = wrapi(_choice_sel - 1, 0, _choices.size())
			AudioManager.ui("menu_click", -14.0)
		elif Input.is_action_just_pressed("move_down"):
			_choice_sel = wrapi(_choice_sel + 1, 0, _choices.size())
			AudioManager.ui("menu_click", -14.0)
		elif Input.is_action_just_pressed("interact"):
			var pick := _choice_sel
			AudioManager.play("checkpoint", -14.0)
			_choice_mode = false
			close()
			choice_made.emit(pick)
	_update_label()
	_canvas.queue_redraw()


func _update_label() -> void:
	if _choice_mode:
		_label.text = ""
		return
	if _idx < _lines.size():
		var line := _lines[_idx]
		_label.text = line.substr(0, int(_chars))
	# Indent past the portrait when a speaker is set.
	_label.offset_left = 150.0 if _portrait != "" else 60.0


func _bark() -> void:
	# A short voice grunt per speaker type — placeholder timbres by portrait.
	match _portrait:
		"pilgrim": AudioManager.play("hurt", -18.0, 0.25)
		"ghost", "sovereign": AudioManager.play("heal", -20.0, 0.2)
		"digger": AudioManager.play("enemy_hurt", -18.0, 0.3)
		"knight": AudioManager.play("parry", -22.0, 0.15)
		"cartographer", "merchant": AudioManager.play("chest", -20.0, 0.2)
		_: pass


# --- painting: portraits + choice list ---------------------------------------------

func _paint() -> void:
	var s := _canvas.size
	if _choice_mode:
		_paint_choices(s)
		return
	if _portrait == "":
		return
	# Portrait plate.
	var r := Rect2(24, s.y * 0.5 - 44, 88, 88)
	_canvas.draw_rect(r, Color(0.06, 0.06, 0.1, 0.92))
	_canvas.draw_rect(r, Color(0.4, 0.42, 0.55), false, 1.5)
	_paint_portrait(_portrait, r)
	# Speaker name.
	_canvas.draw_string(FONT, Vector2(r.position.x - 4, r.position.y - 8), _speaker,
		HORIZONTAL_ALIGNMENT_LEFT, 300, 10, Color(0.75, 0.78, 0.9))
	# Progress pips.
	for i in _lines.size():
		var c := Color(0.7, 0.7, 0.85) if i == _idx else Color(0.3, 0.3, 0.4)
		_canvas.draw_circle(Vector2(s.x - 40 + 0.0, s.y - 16 - (_lines.size() - 1 - i) * 0.0) + Vector2(-(_lines.size() - 1 - i) * 10.0, 0), 1.6, c)


func _paint_choices(s: Vector2) -> void:
	_canvas.draw_string(FONT, Vector2(60, 30), _choice_prompt,
		HORIZONTAL_ALIGNMENT_LEFT, s.x - 120, 12, Color(0.85, 0.86, 0.95))
	for i in _choices.size():
		var y := 56.0 + i * 24.0
		var sel := i == _choice_sel
		var col := Color(0.95, 0.95, 1.0) if sel else Color(0.5, 0.52, 0.65)
		if sel:
			_canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(64, y - 8), Vector2(71, y - 4), Vector2(64, y)]), Color(0.85, 0.82, 1.0))
		_canvas.draw_string(FONT, Vector2(82, y), _choices[i],
			HORIZONTAL_ALIGNMENT_LEFT, s.x - 160, 11, col)


## Small pixel busts, one painter per character.
func _paint_portrait(key: String, r: Rect2) -> void:
	var c := r.get_center() + Vector2(0, 10)
	match key:
		"pilgrim":
			_bust(c, Color(0.45, 0.38, 0.3), Color(0.7, 0.6, 0.5))
			_canvas.draw_rect(Rect2(c.x - 18, c.y - 34, 36, 10), Color(0.35, 0.3, 0.24))  # hood brim
			_canvas.draw_circle(c + Vector2(12, -10), 3.0, Color(0.8, 0.7, 0.4))          # lantern
		"ghost":
			_bust(c, Color(0.4, 0.5, 0.7, 0.7), Color(0.7, 0.8, 0.95, 0.8))
			for ey in [-16.0, -16.0]:
				pass
			_canvas.draw_circle(c + Vector2(-6, -16), 2.0, Color(0.95, 0.98, 1.0))
			_canvas.draw_circle(c + Vector2(6, -16), 2.0, Color(0.95, 0.98, 1.0))
		"digger":
			_bust(c, Color(0.4, 0.3, 0.22), Color(0.65, 0.5, 0.38))
			_canvas.draw_rect(Rect2(c.x - 16, c.y - 36, 32, 8), Color(0.6, 0.55, 0.3))    # helmet
			_canvas.draw_circle(c + Vector2(0, -34), 3.0, Color(1.0, 0.9, 0.5))           # head-lamp
		"cartographer":
			_bust(c, Color(0.3, 0.34, 0.42), Color(0.6, 0.64, 0.72))
			_canvas.draw_rect(Rect2(c.x - 4, c.y - 22, 14, 2), Color(0.85, 0.8, 0.6))     # quill
			_canvas.draw_circle(c + Vector2(-7, -16), 2.4, Color(0.9, 0.95, 1.0))         # monocle
		"knight":
			_bust(c, Color(0.32, 0.34, 0.4), Color(0.55, 0.58, 0.66))
			_canvas.draw_rect(Rect2(c.x - 14, c.y - 30, 28, 6), Color(0.5, 0.52, 0.6))    # helm
			_canvas.draw_rect(Rect2(c.x - 2, c.y - 30, 4, 14), Color(0.2, 0.2, 0.26))     # visor slit
			_canvas.draw_rect(Rect2(c.x - 16, c.y - 38, 32, 4), Color(0.7, 0.6, 0.35))    # crest
		"sovereign":
			_bust(c, Color(0.55, 0.55, 0.62, 0.55), Color(0.85, 0.86, 0.95, 0.6))
			for k in 3:
				_canvas.draw_colored_polygon(PackedVector2Array([
					Vector2(c.x - 10 + k * 8, c.y - 30), Vector2(c.x - 7 + k * 8, c.y - 38),
					Vector2(c.x - 4 + k * 8, c.y - 30)]), Color(0.8, 0.7, 0.4, 0.8))
			_canvas.draw_circle(c + Vector2(-6, -16), 2.0, Color(0.5, 0.95, 1.0))
			_canvas.draw_circle(c + Vector2(6, -16), 2.0, Color(0.5, 0.95, 1.0))
		"merchant":
			_bust(c, Color(0.42, 0.32, 0.36), Color(0.68, 0.55, 0.58))
			_canvas.draw_rect(Rect2(c.x - 12, c.y - 4, 24, 8), Color(0.55, 0.45, 0.25))   # coin tray
			_canvas.draw_circle(c + Vector2(-5, 0), 2.0, Color(0.9, 0.8, 0.45))
			_canvas.draw_circle(c + Vector2(3, -1), 2.0, Color(0.9, 0.8, 0.45))


func _bust(c: Vector2, robe: Color, skin: Color) -> void:
	_canvas.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-20, 28), c + Vector2(-14, -8), c + Vector2(14, -8), c + Vector2(20, 28)]), robe)
	_canvas.draw_circle(c + Vector2(0, -18), 11.0, skin)
	_canvas.draw_rect(Rect2(c.x - 11, c.y - 14, 22, 5), robe.darkened(0.2))
