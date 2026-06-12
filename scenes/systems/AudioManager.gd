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
	for bus_name in ["Music", "SFX", "Ambient", "UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")
	_chain_effects()


## The professional chain, built in code so it ships with the project:
##   Master: compressor -> limiter · Music: EQ + room reverb + light comp ·
##   SFX: EQ + a short slap of reverb · Ambient: heavy reverb + low-pass ·
##   UI: bone dry. The SFX reverb + low-pass are also the live knobs the
##   ReverbZones drive (cathedral wet / underwater muffle).
func _chain_effects() -> void:
	var master := AudioServer.get_bus_index(&"Master")
	if AudioServer.get_bus_effect_count(master) == 0:
		var comp := AudioEffectCompressor.new()
		comp.threshold = -12.0
		comp.ratio = 3.0
		AudioServer.add_bus_effect(master, comp)
		var lim := AudioEffectLimiter.new()
		AudioServer.add_bus_effect(master, lim)
	var music := AudioServer.get_bus_index(&"Music")
	if AudioServer.get_bus_effect_count(music) == 0:
		var eq := AudioEffectEQ.new()
		AudioServer.add_bus_effect(music, eq)
		var rev := AudioEffectReverb.new()
		rev.wet = 0.18
		rev.room_size = 0.7
		AudioServer.add_bus_effect(music, rev)
		var comp := AudioEffectCompressor.new()
		comp.threshold = -16.0
		comp.ratio = 2.0
		AudioServer.add_bus_effect(music, comp)
	var sfx := AudioServer.get_bus_index(&"SFX")
	if AudioServer.get_bus_effect_count(sfx) == 0:
		var eq := AudioEffectEQ.new()
		AudioServer.add_bus_effect(sfx, eq)
		var rev := AudioEffectReverb.new()
		rev.wet = 0.08
		rev.room_size = 0.3
		AudioServer.add_bus_effect(sfx, rev)          # index 1: the zone knob
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 20000.0
		AudioServer.add_bus_effect(sfx, lp)            # index 2: underwater knob
	var amb := AudioServer.get_bus_index(&"Ambient")
	if AudioServer.get_bus_effect_count(amb) == 0:
		var rev := AudioEffectReverb.new()
		rev.wet = 0.4
		rev.room_size = 0.9
		AudioServer.add_bus_effect(amb, rev)
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 6000.0
		AudioServer.add_bus_effect(amb, lp)


# --- reverb zones drive these ---------------------------------------------------

var _zone_tween: Tween

## preset: "default" · "cathedral" (long wet) · "small" (tight) · "flooded"
## (muffled low-pass). Transitions over 1.5s.
func set_reverb_zone(preset: String) -> void:
	var sfx := AudioServer.get_bus_index(&"SFX")
	var rev := AudioServer.get_bus_effect(sfx, 1) as AudioEffectReverb
	var lp := AudioServer.get_bus_effect(sfx, 2) as AudioEffectLowPassFilter
	if rev == null or lp == null:
		return
	var wet := 0.08
	var room := 0.3
	var cutoff := 20000.0
	match preset:
		"cathedral":
			wet = 0.32; room = 0.95
		"small":
			wet = 0.05; room = 0.15
		"flooded":
			wet = 0.2; room = 0.6; cutoff = 2200.0
	if _zone_tween and _zone_tween.is_valid():
		_zone_tween.kill()
	_zone_tween = create_tween().set_parallel(true)
	_zone_tween.tween_property(rev, "wet", wet, 1.5)
	_zone_tween.tween_property(rev, "room_size", room, 1.5)
	_zone_tween.tween_property(lp, "cutoff_hz", cutoff, 1.5)


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

## Sounds with recorded variations — play() rotates them at random.
const VARIANTS := {
	"step_stone": ["step_stone", "step_stone_2", "step_stone_3"],
	"hurt": ["hurt", "hurt_2", "hurt_3"],
	"swipe": ["swipe", "swipe_2", "swipe_3"],
}


func play(name: String, vol_db: float = 0.0, pitch_jitter: float = 0.05,
		bus: StringName = &"SFX", pitch: float = 1.0) -> void:
	if VARIANTS.has(name):
		name = VARIANTS[name][randi() % VARIANTS[name].size()]
	var s := _stream(name)
	if s == null:
		return
	var p := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % POOL_SIZE
	p.stream = s
	p.bus = bus
	p.volume_db = vol_db
	p.pitch_scale = pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	p.play()


## UI clicks ride the dry bus.
func ui(name: String, vol_db: float = -10.0) -> void:
	play(name, vol_db, 0.02, &"UI")


func play_at(name: String, pos: Vector2, vol_db: float = 0.0, max_dist: float = 700.0) -> void:
	if VARIANTS.has(name):
		name = VARIANTS[name][randi() % VARIANTS[name].size()]
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
	p.max_distance = max_dist
	p.attenuation = 1.4
	p.pitch_scale = 1.0 + randf_range(-0.05, 0.05)
	scene.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


## A looping positional ambience that lives (and dies) with its owner node.
## Rides the Ambient bus (heavy reverb + low-pass — the cave hum).
func attach_loop(owner_node: Node2D, name: String, vol_db: float = -14.0,
		max_dist: float = 380.0) -> void:
	var s := _looped(name)
	if s == null:
		return
	var p := AudioStreamPlayer2D.new()
	p.stream = s
	p.bus = &"Ambient"
	p.volume_db = vol_db
	p.max_distance = max_dist
	p.attenuation = 1.6
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


# --- the combat layer -------------------------------------------------------------

var _combat_player: AudioStreamPlayer
var _combat_heat := 0.0   ## seconds of combat-energy left


## Enemies ping this when they aggro / strike; the percussion bed fades in over
## the area track and fades back out after ~5 quiet seconds.
func combat_ping() -> void:
	_combat_heat = 5.0
	if _combat_player == null:
		_combat_player = AudioStreamPlayer.new()
		_combat_player.bus = &"Music"
		_combat_player.volume_db = -80.0
		add_child(_combat_player)
		var s := _looped("music_combat_layer")
		if s:
			_combat_player.stream = s
	if not _combat_player.playing and _combat_player.stream:
		_combat_player.play()


func _process(delta: float) -> void:
	if _combat_player == null or not _combat_player.playing:
		return
	_combat_heat = maxf(0.0, _combat_heat - delta)
	var target := -10.0 if (_combat_heat > 0.0 and _current_track != "boss") else -80.0
	_combat_player.volume_db = move_toward(_combat_player.volume_db, target,
		delta * (28.0 if target > -70.0 else 14.0))
	if _combat_player.volume_db <= -79.0 and _combat_heat <= 0.0:
		_combat_player.stop()


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
