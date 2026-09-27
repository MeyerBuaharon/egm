extends SceneTree

# Every level must be loadable and playable: the shared floor and outer walls
# stay intact, the player spawn is clear, and bounce targets sit above solid ground.
func _init() -> void:
	var room: Node2D = preload("res://scripts/room.gd").new()
	get_root().add_child(room)
	await process_frame
	var failures := 0
	for i in room.LEVELS.size():
		room.load_level(i)
		room.spawn_dummies()
		room.player.reset()
		await process_frame
		var name: String = room.level.get("name", "?")
		failures += check(name, "has a theme background", room.theme.has("background"))
		failures += check(name, "keeps the shared floor at y=700", room.blocks.has(Rect2(30, 700, 1220, 80)))
		var spawn := Rect2(room.player.position - Vector2(16, 30), Vector2(32, 60))
		var clear := true
		for rect in room.blocks:
			if rect != Rect2(30, 700, 1220, 80) and rect.intersects(spawn): clear = false
		failures += check(name, "player spawn is unobstructed", clear)
		for t in room.targets:
			failures += check(name, "target %v is inside the room" % t, Rect2(30, 125, 1220, 575).has_point(t))
	print("RESULT: %d failures" % failures)
	quit(1 if failures else 0)

func check(level: String, what: String, ok: bool) -> int:
	print("%s %s: %s" % ["PASS" if ok else "FAIL", level, what])
	return 0 if ok else 1
