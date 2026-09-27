extends "res://scripts/player.gd"

# Keep the existing movement/animation controller; this preview has its own spawn.
func reset() -> void:
	super.reset()
	position = Vector2(90, 160)
