extends SceneTree
## Dev tool: print an occupancy map of a sprite sheet on a fixed cell grid,
## so we can see how many frames each animation row has before slicing.
## Run: godot --headless -s res://tools/analyze_sheet.gd

const PATH := "/Users/shrinivas46608/Downloads/AnimationSheet_Character.png"
const CELL := 32


func _initialize() -> void:
	var img := Image.new()
	var err := img.load(PATH)
	if err != OK:
		print("load failed: ", err)
		quit()
		return
	var w := img.get_width()
	var h := img.get_height()
	print("image: %dx%d  cells: %dx%d (%dpx)" % [w, h, w / CELL, h / CELL, CELL])
	var cols := w / CELL
	var rows := h / CELL
	for cy in rows:
		var line := ""
		for cx in cols:
			var count := 0
			for y in range(cy * CELL, cy * CELL + CELL):
				for x in range(cx * CELL, cx * CELL + CELL):
					if img.get_pixel(x, y).a > 0.1:
						count += 1
			# show a rough density bucket per cell
			if count == 0:
				line += " . "
			elif count < 60:
				line += " o "
			else:
				line += " X "
		print("row %d:%s" % [cy, line])
	quit()
