extends SceneTree
## Dev-only: synthesize Cairn's entire soundscape procedurally and write WAVs to
## assets/audio/. No recorded samples — every sound is built from noise bursts,
## tuned partials and slow pads, so the whole audio layer is license-free and
## regenerable. Run:  godot --headless --path . -s res://tools/gen_audio.gd
##
## 22050 Hz, 16-bit mono. Music tracks are seamless loops (AudioManager sets
## loop_mode at runtime).

const SR := 22050.0
const DIR := "res://assets/audio"

var _rng := RandomNumberGenerator.new()


## Optional selective generation: GEN_ONLY=name1,name2 regenerates just those.
var _only: PackedStringArray = []


func _initialize() -> void:
	_rng.seed = 7
	var filt := OS.get_environment("GEN_ONLY")
	if filt != "":
		_only = filt.split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))

	# --- player ---
	_save("step_stone", _step(0.09, 900.0, 0.5))
	_save("step_ash", _step(0.13, 420.0, 0.35))
	_save("step_water", _splash_step())
	_save("jump", _whoosh(0.16, 300.0, 900.0, 0.5))
	_save("land", _thud(0.16, 110.0, 0.8))
	_save("swipe", _whoosh(0.13, 1400.0, 500.0, 0.45))
	_save("impact", _impact())
	_save("dash", _whoosh(0.22, 700.0, 1800.0, 0.55))
	_save("parry", _clang())
	_save("hurt", _grunt(160.0, 0.18))
	_save("death_player", _death_fall())
	_save("heal", _pulse(440.0, 0.5))
	_save("bolt", _bolt())

	# --- enemies ---
	_save("aggro", _chirp())
	_save("enemy_hurt", _thud(0.1, 220.0, 0.5))
	_save("enemy_death", _dissolve())
	_save("boss_slam", _boss_slam())
	_save("boss_sweep", _whoosh(0.5, 200.0, 1100.0, 0.8))

	# --- world ---
	_save("chest", _chime([660.0, 990.0], 0.5))
	_save("relic", _chime([220.0, 330.0, 440.0, 660.0], 1.6))
	_save("door", _grind())
	_save("checkpoint", _chime([330.0, 495.0], 0.9))
	_save("torch_loop", _crackle_loop(2.0))
	_save("shrine_loop", _hum_loop(3.0))

	# --- music (seamless loops) ---
	_save("music_menu", _pad_track(36.0, [55.0, 82.5, 110.0], 0.10, 0.0, 0.0))
	_save("music_crypts", _pad_track(40.0, [49.0, 73.5, 98.0], 0.10, 0.05, 0.0))
	_save("music_ashpits", _pad_track(40.0, [41.2, 61.8, 82.4], 0.09, 0.0, 0.16))
	_save("music_nave", _pad_track(44.0, [43.7, 65.5, 87.3], 0.10, 0.10, 0.0))
	_save("music_sanctum", _pad_track(36.0, [65.4, 98.0, 130.8], 0.09, 0.03, 0.0))
	_save("music_boss", _boss_track(32.0))
	_save("music_library", _pad_track(42.0, [58.3, 87.3, 116.5], 0.1, 0.08, 0.0))
	_save("music_warrens", _pad_track(40.0, [38.9, 58.3, 77.8], 0.08, 0.0, 0.2))
	_save("music_throne", _pad_track(46.0, [46.2, 69.3, 92.5], 0.11, 0.06, 0.05))

	print("AUDIO DONE")
	quit()


# === WAV out ====================================================================

func _save(name: String, samples: PackedFloat32Array) -> void:
	if not _only.is_empty() and not (name in _only):
		return
	# Normalize gently, convert to 16-bit PCM, write a minimal WAV.
	var peak := 0.0001
	for s in samples:
		peak = maxf(peak, absf(s))
	var gain := minf(0.92 / peak, 4.0)
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i] * gain, -1.0, 1.0) * 32760.0)
		data.encode_s16(i * 2, v)
	var f := FileAccess.open("%s/%s.wav" % [DIR, name], FileAccess.WRITE)
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(36 + data.size())
	f.store_buffer("WAVEfmt ".to_ascii_buffer())
	f.store_32(16)
	f.store_16(1)            # PCM
	f.store_16(1)            # mono
	f.store_32(int(SR))
	f.store_32(int(SR) * 2)  # byte rate
	f.store_16(2)            # block align
	f.store_16(16)           # bits
	f.store_buffer("data".to_ascii_buffer())
	f.store_32(data.size())
	f.store_buffer(data)
	f.close()
	print("  wrote ", name, ".wav  (", samples.size(), " samples)")


func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * SR))
	return b


# === building blocks ============================================================

## Filtered noise burst with exponential decay — the bones of most SFX.
func _noise_burst(b: PackedFloat32Array, t0: float, dur: float, cutoff: float,
		amp: float, decay: float = 6.0) -> void:
	var i0 := int(t0 * SR)
	var n := int(dur * SR)
	var lp := 0.0
	var k := clampf(cutoff / SR * TAU, 0.0, 1.0)
	for i in n:
		var idx := i0 + i
		if idx >= b.size():
			break
		var t := float(i) / SR
		lp += k * (_rng.randf_range(-1.0, 1.0) - lp)
		b[idx] += lp * amp * exp(-decay * t / dur)


## Sine partial with attack/decay envelope.
func _tone(b: PackedFloat32Array, t0: float, dur: float, freq: float, amp: float,
		attack: float = 0.01, bend: float = 0.0) -> void:
	var i0 := int(t0 * SR)
	var n := int(dur * SR)
	var ph := 0.0
	for i in n:
		var idx := i0 + i
		if idx >= b.size():
			break
		var t := float(i) / SR
		var f := freq * (1.0 + bend * t / dur)
		ph += TAU * f / SR
		var env := minf(t / maxf(attack, 0.001), 1.0) * exp(-4.5 * t / dur)
		b[idx] += sin(ph) * amp * env


# === SFX recipes ================================================================

func _step(dur: float, cutoff: float, amp: float) -> PackedFloat32Array:
	var b := _buf(dur)
	_noise_burst(b, 0.0, dur, cutoff, amp, 9.0)
	_tone(b, 0.0, dur * 0.5, 95.0, amp * 0.5, 0.002)
	return b

func _splash_step() -> PackedFloat32Array:
	var b := _buf(0.2)
	_noise_burst(b, 0.0, 0.06, 2400.0, 0.4, 5.0)
	_noise_burst(b, 0.04, 0.16, 900.0, 0.35, 4.0)
	return b

func _whoosh(dur: float, f0: float, f1: float, amp: float) -> PackedFloat32Array:
	var b := _buf(dur)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / SR
		var p := t / dur
		var cutoff := lerpf(f0, f1, p)
		var k := clampf(cutoff / SR * TAU, 0.0, 1.0)
		lp += k * (_rng.randf_range(-1.0, 1.0) - lp)
		b[i] = lp * amp * sin(PI * p)   # swell in and out
	return b

func _thud(dur: float, freq: float, amp: float) -> PackedFloat32Array:
	var b := _buf(dur)
	_tone(b, 0.0, dur, freq, amp, 0.002, -0.5)
	_noise_burst(b, 0.0, dur * 0.4, 500.0, amp * 0.4, 8.0)
	return b

func _impact() -> PackedFloat32Array:
	var b := _buf(0.18)
	_tone(b, 0.0, 0.12, 150.0, 0.7, 0.001, -0.4)
	_noise_burst(b, 0.0, 0.1, 3200.0, 0.5, 10.0)
	return b

func _clang() -> PackedFloat32Array:
	# Inharmonic metal partials — a parry bell.
	var b := _buf(0.55)
	for f in [523.0, 1244.0, 1873.0, 2510.0]:
		_tone(b, 0.0, 0.55, f + _rng.randf_range(-6, 6), 0.28, 0.001)
	_noise_burst(b, 0.0, 0.04, 5000.0, 0.5, 8.0)
	return b

func _grunt(freq: float, dur: float) -> PackedFloat32Array:
	var b := _buf(dur)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / SR
		var f := freq * (1.0 - 0.4 * t / dur)
		ph += TAU * f / SR
		var saw := 2.0 * fmod(ph / TAU, 1.0) - 1.0
		b[i] = (saw * 0.5 + _rng.randf_range(-0.2, 0.2)) * 0.5 * exp(-7.0 * t / dur)
	return b

func _death_fall() -> PackedFloat32Array:
	var b := _buf(1.1)
	_tone(b, 0.0, 1.1, 320.0, 0.5, 0.01, -0.72)
	_tone(b, 0.0, 1.1, 161.0, 0.4, 0.01, -0.72)
	_noise_burst(b, 0.6, 0.5, 600.0, 0.3, 4.0)
	return b

func _pulse(freq: float, dur: float) -> PackedFloat32Array:
	var b := _buf(dur)
	_tone(b, 0.0, dur, freq, 0.4, 0.08)
	_tone(b, 0.0, dur, freq * 1.5, 0.25, 0.1)
	return b

func _bolt() -> PackedFloat32Array:
	var b := _buf(0.3)
	_noise_burst(b, 0.0, 0.3, 1100.0, 0.5, 4.0)
	_tone(b, 0.0, 0.25, 130.0, 0.45, 0.004, 0.8)
	return b

func _chirp() -> PackedFloat32Array:
	var b := _buf(0.18)
	_tone(b, 0.0, 0.09, 700.0, 0.4, 0.004, 0.7)
	_tone(b, 0.08, 0.1, 980.0, 0.3, 0.004, -0.3)
	return b

func _dissolve() -> PackedFloat32Array:
	var b := _buf(0.5)
	_noise_burst(b, 0.0, 0.5, 1600.0, 0.45, 3.0)
	_tone(b, 0.0, 0.5, 392.0, 0.2, 0.01, -0.6)
	return b

func _boss_slam() -> PackedFloat32Array:
	var b := _buf(0.7)
	_tone(b, 0.0, 0.6, 55.0, 0.9, 0.002, -0.3)
	_tone(b, 0.0, 0.3, 110.0, 0.5, 0.002, -0.4)
	_noise_burst(b, 0.0, 0.35, 700.0, 0.5, 5.0)
	return b

func _chime(freqs: Array, dur: float) -> PackedFloat32Array:
	var b := _buf(dur)
	for j in freqs.size():
		_tone(b, j * 0.07, dur - j * 0.07, freqs[j], 0.3, 0.004)
	return b

func _grind() -> PackedFloat32Array:
	var b := _buf(0.9)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / SR
		var k := clampf((260.0 + sin(t * 30.0) * 120.0) / SR * TAU, 0.0, 1.0)
		lp += k * (_rng.randf_range(-1.0, 1.0) - lp)
		b[i] = lp * 0.55 * sin(PI * minf(t / 0.9, 1.0))
	_tone(b, 0.75, 0.15, 88.0, 0.5, 0.004)
	return b

func _crackle_loop(dur: float) -> PackedFloat32Array:
	var b := _buf(dur)
	# Bed of soft low noise + random pops.
	_noise_burst(b, 0.0, dur, 300.0, 0.12, 0.0)
	for i in range(26):
		_noise_burst(b, _rng.randf() * (dur - 0.05), _rng.randf_range(0.01, 0.04),
			_rng.randf_range(1500, 4000), _rng.randf_range(0.1, 0.3), 6.0)
	return _make_loopable(b)

func _hum_loop(dur: float) -> PackedFloat32Array:
	var b := _buf(dur)
	for i in b.size():
		var t := float(i) / SR
		b[i] = (sin(TAU * 98.0 * t) * 0.35 + sin(TAU * 147.0 * t) * 0.2 \
			+ sin(TAU * 196.0 * t + sin(t * 2.0)) * 0.12) \
			* (0.8 + 0.2 * sin(TAU * t / dur))
	return b


## Crossfade the last 0.4s into the first so loops are seamless.
func _make_loopable(b: PackedFloat32Array) -> PackedFloat32Array:
	var n := int(0.4 * SR)
	var sz := b.size()
	for i in n:
		var f := float(i) / n
		b[i] = b[i] * f + b[sz - n + i] * (1.0 - f)
	return b.slice(0, sz - n)


# === music ======================================================================

## A slow evolving pad over a root chord, with optional sparse bell strikes and
## optional furnace rumble. Built additively, faded loop-seamless.
func _pad_track(dur: float, chord: Array, pad_amp: float, bell_amp: float,
		rumble_amp: float) -> PackedFloat32Array:
	var b := _buf(dur)
	# Detuned pad partials, each with its own slow LFO so the bed breathes.
	for j in chord.size():
		var f: float = chord[j]
		for det in [-0.4, 0.0, 0.5]:
			var ph := _rng.randf() * TAU
			var lfo_r := 0.05 + _rng.randf() * 0.05
			var lfo_p := _rng.randf() * TAU
			var fr: float = f * 2.0 + det
			for i in b.size():
				var t := float(i) / SR
				var lfo := 0.5 + 0.5 * sin(TAU * lfo_r * t + lfo_p)
				b[i] += sin(TAU * fr * t + ph) * pad_amp * 0.33 * (0.35 + 0.65 * lfo)
	# Sparse far-off bell strikes (crypts/nave colour).
	if bell_amp > 0.0:
		var strikes := int(dur / 7.0)
		for s in strikes:
			var t0 := s * 7.0 + _rng.randf() * 3.0
			var f: float = chord[_rng.randi() % chord.size()] * (4.0 if _rng.randf() > 0.5 else 8.0)
			_tone(b, t0, 4.0, f, bell_amp, 0.01)
			_tone(b, t0, 4.0, f * 2.41, bell_amp * 0.4, 0.01)
	# Low furnace rumble (ashpits colour): brown-ish noise, heavily lowpassed.
	if rumble_amp > 0.0:
		var lp := 0.0
		var lp2 := 0.0
		for i in b.size():
			lp += 0.02 * (_rng.randf_range(-1.0, 1.0) - lp)
			lp2 += 0.01 * (lp - lp2)
			var t := float(i) / SR
			b[i] += lp2 * rumble_amp * 12.0 * (0.7 + 0.3 * sin(TAU * 0.07 * t))
	return _make_loopable(b)


## The boss track: a driving low pulse, dissonant high tension tones.
func _boss_track(dur: float) -> PackedFloat32Array:
	var b := _buf(dur)
	var bpm := 64.0
	var beat := 60.0 / bpm
	var nbeats := int(dur / beat)
	for k in nbeats:
		var t0 := k * beat
		_tone(b, t0, 0.34, 49.0, 0.5, 0.002, -0.25)          # pulse
		if k % 4 == 2:
			_tone(b, t0, 0.3, 98.0, 0.3, 0.002, -0.2)        # off-accent
		if k % 8 == 7:
			_noise_burst(b, t0, 0.25, 1500.0, 0.18, 5.0)      # rasp
	# Tension bed: tritone shimmer.
	for f in [196.0, 277.2]:
		var ph := _rng.randf() * TAU
		for i in b.size():
			var t := float(i) / SR
			b[i] += sin(TAU * f * t + ph + sin(t * 0.5) * 2.0) * 0.045 \
				* (0.6 + 0.4 * sin(TAU * 0.06 * t))
	return _make_loopable(b)
