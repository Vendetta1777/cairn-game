extends SceneTree
## Dev tool: slice the player spritesheets into a SpriteFrames resource.
## Run: godot --headless --path . -s res://tools/build_spriteframes.gd
##
## Each sheet is a horizontal strip of FRAME_W-wide frames. We build one
## AtlasTexture per frame over the source sheet, so there's a single imported
## texture per animation and no duplicated pixels. Re-run any time the source
## art changes — output is res://scenes/player/player_frames.tres.

const FRAME_W := 128
const FRAME_H := 96
const OUT_PATH := "res://scenes/player/player_frames.tres"

# name: [file, frames, fps, loop]
const ANIMS := {
	"idle":   ["res://assets/sprites/player/idle.png",   4, 7.0,  true],
	"run":    ["res://assets/sprites/player/run.png",   12, 14.0, true],
	"jump":   ["res://assets/sprites/player/jump.png",   4, 10.0, false],
	"attack": ["res://assets/sprites/player/attack.png", 2, 14.0, false],
	"crouch": ["res://assets/sprites/player/crouch.png", 2, 6.0,  true],
	"hurt":   ["res://assets/sprites/player/hurt.png",   3, 10.0, false],
}


func _initialize() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")  # drop the auto-created empty anim

	for anim_name in ANIMS:
		var cfg: Array = ANIMS[anim_name]
		var sheet: Texture2D = load(cfg[0])
		if sheet == null:
			push_error("Missing sheet: %s" % cfg[0])
			continue
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, cfg[2])
		frames.set_animation_loop(anim_name, cfg[3])
		for i in cfg[1]:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
			frames.add_frame(anim_name, atlas)
		print("  %-7s %d frames @ %s fps" % [anim_name, cfg[1], cfg[2]])

	var err := ResourceSaver.save(frames, OUT_PATH)
	print("SAVED %s (err=%d)" % [OUT_PATH, err])
	quit()
