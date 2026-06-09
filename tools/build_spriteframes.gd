extends SceneTree
## Dev tool: build the player's SpriteFrames from the hooded-character sheet.
## Run: godot --headless --path . -s res://tools/build_spriteframes.gd
##
## The sheet (assets/sprites/player/hooded.png) is a 32px grid where each ROW is
## an animation of varying length. We pick cells [col,row] explicitly so we only
## grab the frames that belong to each clip. Re-run after changing the mapping.
## Output: res://scenes/player/player_frames.tres

const SHEET := "res://assets/sprites/player/hooded.png"
const CELL := 32

# name -> { "cells": [[col,row],...], "fps": float, "loop": bool }
const ANIMS := {
	"idle":   {"cells": [[0,0],[1,0],[0,1],[1,1]], "fps": 5.0,  "loop": true},
	"run":    {"cells": [[0,3],[1,3],[2,3],[3,3],[4,3],[5,3],[6,3],[7,3]], "fps": 12.0, "loop": true},
	"jump":   {"cells": [[0,5],[1,5],[2,5],[3,5]], "fps": 8.0,  "loop": false},
	"crouch": {"cells": [[2,4],[3,4]], "fps": 5.0,  "loop": true},
	"hurt":   {"cells": [[0,6],[1,6],[2,6]], "fps": 9.0,  "loop": false},
}


func _initialize() -> void:
	var sheet: Texture2D = load(SHEET)
	if sheet == null:
		push_error("Missing sheet: %s" % SHEET)
		quit()
		return

	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	for anim_name in ANIMS:
		var cfg: Dictionary = ANIMS[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, cfg["fps"])
		frames.set_animation_loop(anim_name, cfg["loop"])
		for cell in cfg["cells"]:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(cell[0] * CELL, cell[1] * CELL, CELL, CELL)
			frames.add_frame(anim_name, atlas)
		print("  %-7s %d frames @ %s fps" % [anim_name, cfg["cells"].size(), cfg["fps"]])

	var err := ResourceSaver.save(frames, "res://scenes/player/player_frames.tres")
	print("SAVED player_frames.tres (err=%d)" % err)
	quit()
