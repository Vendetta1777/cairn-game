extends SceneTree
## Cairn — persistence suite (golden-portal round trip), event-driven.
## Scratch slot 9; prints a ✓/✗ line per spec test case.

const AREA1 := "res://scenes/world/area_01_hollowed_gate/Area1.tscn"
const SANCTUM := "res://scenes/world/sanctum/Sanctum.tscn"

var _frames := 0
var _state := 0
var _results: Array = []
var _prog
var _save
var _gm
var _quest
var _flow
var _wait := 0


func _check(name: String, ok: bool, detail := "") -> void:
	_results.append([name, ok])
	print(("  ✓ " if ok else "  ✗ ") + name + ("" if detail == "" else "   [" + detail + "]"))


func _player():
	var s = current_scene
	return s.find_child("Player", false, false) if s else null


func _key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventKey.new()
	up.physical_keycode = code
	up.pressed = false
	Input.parse_input_event(up)


func _flow_idle() -> bool:
	return _flow.get("_busy") == false


func _process(_d: float) -> bool:
	_frames += 1
	if _frames > 4000:
		print("=== TIMED OUT in state ", _state, " ===")
		quit(1)
		return false
	if _wait > 0:
		_wait -= 1
		return false
	match _state:
		0:
			if _frames < 5:
				return false
			_prog = get_root().get_node("PlayerProgress")
			_save = get_root().get_node("SaveManager")
			_gm = get_root().get_node("GameManager")
			_quest = get_root().get_node("QuestTracker")
			_flow = get_root().get_node("SceneFlow")
			print("=== CAIRN PERSISTENCE SUITE (scratch slot 9) ===")
			_prog.reset()
			_save.start_session(9)
			_save.save_slot(9)
			var scene = (load(AREA1) as PackedScene).instantiate()
			get_root().add_child(scene)
			current_scene = scene
			_state = 1
		1:
			if _gm.current_area_id == "hollowed_gate" and _player() != null:
				_prog.grant_ability("dash")                # ability pickup
				_quest.report_boss_defeated("mother_bat")  # boss kill
				_prog.add_shards(50)
				var ok = _prog.unlock("blade_0")           # skill purchase
				print("setup: dash + boss + blade_0(", ok, ") + 50 shards")
				_player().global_position = Vector2(2245, 120)   # walk onto cache
				_wait = 25
				_state = 2
		2:
			_check("setup: shard cache collected (cache_a1_tides_loft)",
				_prog.has_flag("cache_a1_tides_loft"))
			_player().global_position = Vector2(1345, 240)       # touch the stone
			_wait = 25
			_state = 3
		3:
			_check("setup: shrine activated (checkpoint registered)", _gm.has_checkpoint)
			_player().get_node("Stats").take_damage(99)          # die
			_state = 4
		4:
			# Wait for the death screen to arm, then any-key respawn.
			var ds = current_scene.find_child("DeathScreen", true, false)
			if ds and ds.get("_armed") == true:
				_key(KEY_SPACE)
				_wait = 30
				_state = 5
		5:
			var p = _player()
			var stats = p.get_node("Stats")
			_check("die -> respawn at activated shrine, world saved",
				not paused and stats.health == stats.max_health
				and p.global_position.distance_to(Vector2(1345, 246)) < 30.0,
				"hp=%d pos=%s" % [stats.health, p.global_position])
			# --- golden portal OUT (what Portal.gd does) ---
			_save.autosave()
			_flow.travel(SANCTUM, "up")
			_state = 6
		6:
			if _gm.current_area_id == "sanctum" and _flow_idle() and _player() != null:
				print("arrived in sanctum; taking 1 heart of damage there")
				_player().get_node("Stats").take_damage(2)
				# --- golden portal BACK ---
				_save.autosave()
				_flow.travel(AREA1, "up")
				_state = 7
		7:
			if _gm.current_area_id == "hollowed_gate" and _flow_idle() and _player() != null:
				_wait = 10
				_state = 8
		8:
			var scene = current_scene
			_check("dash still unlocked after portal round trip", _prog.has_ability("dash"))
			_check("dash relic does NOT respawn", scene.get_node_or_null("DashRelic") == null)
			_check("boss flag survives + boss does NOT respawn",
				_prog.boss_defeated("mother_bat") and scene.get_node_or_null("MotherBat") == null)
			var gate = scene.get_node_or_null("SealedGate")
			_check("boss door still open", gate != null and gate.get("_sealed") == false)
			_check("skill node blade_0 still purchased", _prog.is_unlocked("blade_0"))
			_check("shard cache does NOT respawn", scene.get_node_or_null("TidesLoftCache") == null)
			_check("checkpoint restored in this area after round trip", _gm.has_checkpoint
				and _gm.checkpoint_position.distance_to(Vector2(1345, 246)) < 10.0)
			var stone = scene.find_child("CheckpointGaps", true, false)
			_check("activated shrine still lit", stone != null and stone.get("_active") == true)
			var stats = _player().get_node("Stats")
			_check("current health persisted (1 heart lost in Sanctum)",
				stats.health == _prog.max_half_hearts() - 2,
				"hp=%d/%d" % [stats.health, _prog.max_half_hearts()])
			_state = 9
		9:
			var f := FileAccess.open("user://cairn_save_9.json", FileAccess.READ)
			var d: Dictionary = JSON.parse_string(f.get_as_text())
			f.close()
			_check("disk: abilities array has dash", "dash" in (d.get("abilities", []) as Array))
			_check("disk: boss ledger lists EVERY boss, mother_bat=true",
				d.has("bosses") and d.bosses.get("mother_bat", false) == true
				and d.bosses.has("ashen_warden") and d.bosses.has("drowned_choir"))
			_check("disk: skill node in unlocked array", "blade_0" in (d.get("unlocked", []) as Array))
			_check("disk: cache flag written", d.get("flags", {}).get("cache_a1_tides_loft", false))
			_check("disk: current health written", d.has("health") and int(d.health) > 0)
			_check("disk: last_checkpoint written {area,x,y}",
				d.get("last_checkpoint", {}).get("area", "") == "hollowed_gate")
			_check("disk: shards written", int(d.get("shards", 0)) > 0)
			var passed := 0
			for r in _results:
				if r[1]:
					passed += 1
			print("=== RESULT: %d/%d PASSED ===" % [passed, _results.size()])
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://cairn_save_9.json"))
			quit(0 if passed == _results.size() else 1)
	return false
