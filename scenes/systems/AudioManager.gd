extends Node
## Cairn — AudioManager (autoload): the single owner of all sound.
##   - Master / Music / SFX buses, created at boot; volumes persist in
##     user://settings.json (the title screen's Settings edits them live).
##   - play(name)        — pooled one-shot UI/player SFX.
##   - play_at(name,pos) — positional one-shot (AudioStreamPlayer2D), autofreed.
##   - attach_loop(node,name) — positional looping ambience pinned to a node
##     (shrine hum, torch crackle).
##   - play_music(track) — per-area ambient beds that CROSSFADE over 4s.
##   - boss_music(true)  — swaps to the boss track; restored automatically when
##     QuestTracker.boss_defeated fires.
##   - duck(db,time)     — momentary master dip (the death slow-mo uses it).
## All streams are the procedurally generated WAVs in assets/audio/ (see
## tools/gen_audio.gd); every lookup is graceful if a file is missing.

const AUDIO_DIR := "res://assets/audio"
const SETTINGS_PATH := "user://settings.json"
const CROSSFADE := 4.0
const POOL_SIZE := 12

var music_volume: float = 0.8
var sfx_volume: float = 0.9
var master_volume: float = 1.0
var fullscreen: bool = false

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_i := 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_live_is_a := true
var _current_track := ""
var _track_before_boss := ""
var _duck_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_buses()
	_load_settings()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_pool.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	for m in [_music_a, _music_b]:
		m.bus = &"Music"
		m.volume_db = -80.0
		add_child(m)
	QuestTracker.boss_defeated.connect(_on_boss_defeated)


func _make_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")


func _stream(name: String) -> AudioStream:
	if _streams.has(name):
		return _streams[name]
	var path := "%s/%s.wav" % [AUDIO_DIR, name]
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_streams[name] = s
	return s


## Mark a WAV as looping (music beds, torch/shrine loops).
func _looped(name: String) -> AudioStream:
	var s := _stream(name)
	if s is AudioStreamWAV and s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2   # 16-bit mono: 2 bytes per frame
	return s


# --- one-shots -----------------------------------------------------------------

func play(name: String, vol_db: float = 0.0, pitch_jitter: float = 0.05) -> void:
	var s := _stream(name)
	if s == null:
		return
	var p := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % POOL_SIZE
	p.stream = s
	p.volume_db = vol_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()


func play_at(name: String, pos: Vector2, vol_db: float = 0.0) -> void:
	var s := _stream(name)
	if s == null:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p := AudioStreamPlayer2D.new()
	p.stream = s
	p.bus = &"SFX"
	p.volume_db = vol_db
	p.max_distance = 700.0
	p.pitch_scale = 1.0 + randf_range(-0.05, 0.05)
	scene.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


## A looping positional ambience that lives (and dies) with its owner node.
func attach_loop(owner_node: Node2D, name: String, vol_db: float = -14.0) -> void:
	var s := _looped(name)
	if s == null:
		return
	var p := AudioStreamPlayer2D.new()
	p.stream = s
	p.bus = &"SFX"
	p.volume_db = vol_db
	p.max_distance = 380.0
	owner_node.add_child(p)
	p.play(randf() * 1.0)


# --- music ----------------------------------------------------------------------

func play_music(track: String) -> void:
	if track == _current_track:
		return
	_current_track = track
	var s := _looped("music_%s" % track)
	var incoming := _music_b if _music_live_is_a else _music_a
	var outgoing := _music_a if _music_live_is_a else _music_b
	_music_live_is_a = not _music_live_is_a
	if s:
		incoming.stream = s
		incoming.volume_db = -80.0
		incoming.play()
	var tw := create_tween().set_parallel(true)
	if s:
		tw.tween_property(incoming, "volume_db", -8.0, CROSSFADE)
	tw.tween_property(outgoing, "volume_db", -80.0, CROSSFADE)
	tw.chain().tween_callback(outgoing.stop)


func boss_music(on: bool) -> void:
	if on:
		if _current_track != "boss":
			_track_before_boss = _current_track
			play_music("boss")
	elif _current_track == "boss" and _track_before_boss != "":
		play_music(_track_before_boss)


func _on_boss_defeated(_id: String) -> void:
	boss_music(false)


## Momentary master dip (e.g. the death slow-mo), restored after `dur`.
func duck(db: float = -10.0, dur: float = 1.6) -> void:
	var master := AudioServer.get_bus_index(&"Master")
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	var base := linear_to_db(maxf(master_volume, 0.001))
	_duck_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	_duck_tween.tween_method(func(v): AudioServer.set_bus_volume_db(master, v), base, base + db, 0.25)
	_duck_tween.tween_interval(dur)
	_duck_tween.tween_method(func(v): AudioServer.set_bus_volume_db(master, v), base + db, base, 0.8)


# --- settings --------------------------------------------------------------------

func set_volume(which: String, linear: float) -> void:
	linear = clampf(linear, 0.0, 1.0)
	match which:
		"master": master_volume = linear
		"music": music_volume = linear
		"sfx": sfx_volume = linear
	_apply_volumes()
	save_settings()


func get_volume(which: String) -> float:
	match which:
		"master": return master_volume
		"music": return music_volume
		"sfx": return sfx_volume
	return 1.0


func set_fullscreen(v: bool) -> void:
	fullscreen = v
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()


func _apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"),
		linear_to_db(maxf(master_volume, 0.001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"),
		linear_to_db(maxf(music_volume, 0.001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"),
		linear_to_db(maxf(sfx_volume, 0.001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), master_volume <= 0.001)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Music"), music_volume <= 0.001)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"SFX"), sfx_volume <= 0.001)


func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"master": master_volume, "music": music_volume, "sfx": sfx_volume,
			"fullscreen": fullscreen,
		}))
		f.close()


func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(d) == TYPE_DICTIONARY:
			master_volume = clampf(float(d.get("master", 1.0)), 0.0, 1.0)
			music_volume = clampf(float(d.get("music", 0.8)), 0.0, 1.0)
			sfx_volume = clampf(float(d.get("sfx", 0.9)), 0.0, 1.0)
			fullscreen = bool(d.get("fullscreen", false))
			if fullscreen:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_apply_volumes()
