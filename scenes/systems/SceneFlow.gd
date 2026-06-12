extends Node
## Cairn — SceneFlow (autoload): every scene change goes through here.
##   travel(path, dir) — a DIRECTIONAL WIPE matching the travel direction
##   ("down" for descents, "up" for returns, "left"/"right" for doors), then a
##   loading screen (threaded load + progress bar + a lore quote) while the next
##   area streams in, then the reverse wipe. Small scenes flash through it fast;
##   big ones get a real loading beat. The overlay lives on layer 60, above all.

const FONT := preload("res://assets/fonts/silkscreen.ttf")
const Quotes = preload("res://scenes/ui/DeathScreen.gd")

const WIPE_TIME := 0.32
const MIN_HOLD := 0.45    ## the loading card always shows at least this long

var _layer: CanvasLayer
var _cover: Control
var _busy := false
var _progress := 0.0
var _quote := ""
var _show_loading := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 60
	add_child(_layer)
	_cover = Control.new()
	_cover.anchors_preset = Control.PRESET_FULL_RECT
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.draw.connect(_draw_cover)
	_cover.visible = false
	_layer.add_child(_cover)


var _wipe_amt := 0.0      ## 0 = clear, 1 = fully covered
var _wipe_dir := Vector2.DOWN


func travel(path: String, dir: String = "down") -> void:
	if _busy or path == "":
		return
	_busy = true
	_wipe_dir = {"down": Vector2.DOWN, "up": Vector2.UP,
		"left": Vector2.LEFT, "right": Vector2.RIGHT}.get(dir, Vector2.DOWN)
	_quote = Quotes.QUOTES[randi() % Quotes.QUOTES.size()]
	_progress = 0.0
	_show_loading = false
	_cover.visible = true
	_run_travel(path)


func _run_travel(path: String) -> void:
	# Wipe in.
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	tw.tween_method(_set_wipe, 0.0, 1.0, WIPE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw.finished
	_show_loading = true
	# Threaded load with a progress bar and a minimum hold so it never strobes.
	ResourceLoader.load_threaded_request(path)
	var t0 := Time.get_ticks_msec()
	var prog := []
	while true:
		var status := ResourceLoader.load_threaded_get_status(path, prog)
		_progress = float(prog[0]) if prog.size() > 0 else 0.0
		_cover.queue_redraw()
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_warning("Cairn: failed to load %s" % path)
			_finish_uncovered()
			return
		await get_tree().process_frame
	while Time.get_ticks_msec() - t0 < int(MIN_HOLD * 1000.0):
		_progress = 1.0
		_cover.queue_redraw()
		await get_tree().process_frame
	var packed: PackedScene = ResourceLoader.load_threaded_get(path)
	get_tree().change_scene_to_packed(packed)
	await get_tree().process_frame
	await get_tree().process_frame
	# Wipe out the other way.
	_show_loading = false
	var tw2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	tw2.tween_method(_set_wipe, 1.0, 0.0, WIPE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw2.finished
	_finish_uncovered()


func _finish_uncovered() -> void:
	_cover.visible = false
	_wipe_amt = 0.0
	_busy = false


func _set_wipe(v: float) -> void:
	_wipe_amt = v
	_cover.queue_redraw()


func _draw_cover() -> void:
	var s := _cover.size
	if s.x <= 0.0:
		s = Vector2(960, 540)
	# The wipe: a black sheet sliding across in _wipe_dir, leading edge glowing.
	var black := Color(0.008, 0.01, 0.016)
	var r: Rect2
	var axis_v := _wipe_dir.y != 0.0
	var span := (s.y if axis_v else s.x) * _wipe_amt
	if _wipe_dir == Vector2.DOWN:
		r = Rect2(0, 0, s.x, span)
	elif _wipe_dir == Vector2.UP:
		r = Rect2(0, s.y - span, s.x, span)
	elif _wipe_dir == Vector2.RIGHT:
		r = Rect2(0, 0, span, s.y)
	else:
		r = Rect2(s.x - span, 0, span, s.y)
	_cover.draw_rect(r, black)
	if _wipe_amt > 0.01 and _wipe_amt < 0.99:
		var edge := Color(0.35, 0.45, 0.62, 0.5)
		if _wipe_dir == Vector2.DOWN:
			_cover.draw_rect(Rect2(0, r.size.y - 2, s.x, 2), edge)
		elif _wipe_dir == Vector2.UP:
			_cover.draw_rect(Rect2(0, r.position.y, s.x, 2), edge)
		elif _wipe_dir == Vector2.RIGHT:
			_cover.draw_rect(Rect2(r.size.x - 2, 0, 2, s.y), edge)
		else:
			_cover.draw_rect(Rect2(r.position.x, 0, 2, s.y), edge)

	if not _show_loading:
		return
	# Loading card: a slim progress bar and a lore quote in the dark.
	var cx := s.x * 0.5
	var cy := s.y * 0.5
	_cover.draw_string(FONT, Vector2(0, cy - 36), "DESCENDING", HORIZONTAL_ALIGNMENT_CENTER,
		s.x, 16, Color(0.6, 0.65, 0.8))
	var bw := 280.0
	var bar := Rect2(cx - bw * 0.5, cy - 10, bw, 6)
	_cover.draw_rect(bar, Color(0.1, 0.11, 0.17))
	_cover.draw_rect(Rect2(bar.position, Vector2(bw * clampf(_progress, 0.0, 1.0), 6)),
		Color(0.5, 0.62, 0.85))
	_cover.draw_rect(bar, Color(0.3, 0.34, 0.46), false, 1.0)
	_cover.draw_string(FONT, Vector2(cx - 320, cy + 40), "\"%s\"" % _quote,
		HORIZONTAL_ALIGNMENT_CENTER, 640, 10, Color(0.38, 0.4, 0.5))
