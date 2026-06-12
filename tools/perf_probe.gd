extends SceneTree
## Dev-only: load an area and measure frame times over a few seconds, so
## anything creeping past the 4ms-per-frame budget gets flagged before export.
## Run: SHOT_SCENE=res://...tscn godot --path . -s res://tools/perf_probe.gd

var _frames := 0
var _samples: Array[float] = []
var _last_us := 0


func _initialize() -> void:
	var scene_path := OS.get_environment("SHOT_SCENE")
	if scene_path == "":
		scene_path = "res://scenes/world/area_01_hollowed_gate/Area1.tscn"
	var packed: PackedScene = load(scene_path)
	get_root().add_child(packed.instantiate())
	_last_us = Time.get_ticks_usec()


func _process(_delta: float) -> bool:
	_frames += 1
	var now := Time.get_ticks_usec()
	if _frames > 30:   # skip warm-up
		_samples.append((now - _last_us) / 1000.0)
	_last_us = now
	if _frames >= 330:
		_samples.sort()
		var total := 0.0
		for s in _samples:
			total += s
		var avg := total / _samples.size()
		var p95: float = _samples[int(_samples.size() * 0.95)]
		var worst: float = _samples[-1]
		print("PERF %s : avg %.2f ms · p95 %.2f ms · worst %.2f ms (%d frames)" % [
			OS.get_environment("SHOT_SCENE"), avg, p95, worst, _samples.size()])
		if p95 > 16.6:
			print("  !! p95 over 60fps budget")
		quit()
	return false
