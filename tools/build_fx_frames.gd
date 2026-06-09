extends SceneTree
## Dev tool: build combat VFX SpriteFrames (slash + hit spark).
## Run: godot --headless --path . -s res://tools/build_fx_frames.gd
## Output: res://scenes/fx/fx_frames.tres

# name -> [file, frame_w, frame_h, count, fps]
const ANIMS := {
	"slash": ["res://assets/fx/slash.png", 65, 40, 5, 24.0],  # flat crescent — rotated per attack direction
	"hit":   ["res://assets/fx/hit.png",   31, 32, 3, 18.0],
}


func _initialize() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name in ANIMS:
		var cfg: Array = ANIMS[anim_name]
		var sheet: Texture2D = load(cfg[0])
		if sheet == null:
			push_error("Missing: " + cfg[0])
			continue
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, cfg[4])
		frames.set_animation_loop(anim_name, false)
		for i in cfg[3]:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(i * cfg[1], 0, cfg[1], cfg[2])
			frames.add_frame(anim_name, atlas)
		print("  %-6s %d frames" % [anim_name, cfg[3]])
	var err := ResourceSaver.save(frames, "res://scenes/fx/fx_frames.tres")
	print("SAVED fx_frames.tres (err=%d)" % err)
	quit()
