extends SceneTree
const W := 144
const H := 80
const ANIMS := {"idle":["idle",4,5.0,true],"walk":["walk",6,9.0,true],"attack":["attack",7,11.0,false]}
func _initialize():
	var fr := SpriteFrames.new(); fr.remove_animation("default")
	for n in ANIMS:
		var c = ANIMS[n]
		var sheet: Texture2D = load("res://assets/sprites/enemies/brute/%s.png" % c[0])
		fr.add_animation(n); fr.set_animation_speed(n, c[2]); fr.set_animation_loop(n, c[3])
		for i in c[1]:
			var a := AtlasTexture.new(); a.atlas = sheet; a.region = Rect2(i*W,0,W,H); fr.add_frame(n, a)
		print("  ", n, " ", c[1])
	print("err=", ResourceSaver.save(fr, "res://scenes/enemies/brute/brute_frames.tres")); quit()
