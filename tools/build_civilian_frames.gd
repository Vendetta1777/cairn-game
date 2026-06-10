extends SceneTree
func _initialize():
	var sheet: Texture2D = load("res://assets/sprites/npc/civilian.png")
	var fr := SpriteFrames.new(); fr.remove_animation("default")
	fr.add_animation("idle"); fr.set_animation_speed("idle", 6.0); fr.set_animation_loop("idle", true)
	for i in 8:
		var a := AtlasTexture.new(); a.atlas = sheet; a.region = Rect2(i*39, 0, 39, 53); fr.add_frame("idle", a)
	print("err=", ResourceSaver.save(fr, "res://scenes/npc/civilian_frames.tres")); quit()
