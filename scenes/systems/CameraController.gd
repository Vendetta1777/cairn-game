extends Camera2D
class_name CameraController
## Cairn — Camera controller (STUB, expands in M5).
##
## M1: Player.tscn ships a plain Camera2D with position smoothing, which is
## enough to test movement. This script exists for when the camera needs
## screen-shake (combat feel — light on hit, heavy on boss hits; GDD Section 5)
## and room-bounded framing.

## Call from combat: trauma in [0,1]. Decays over time; shake = trauma^2.
func add_trauma(_amount: float) -> void:
	pass  # M5: accumulate trauma, apply offset/rotation noise in _process
