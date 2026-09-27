extends SceneTree

# Renders each level to previews/level-<n>-<name>.png at full room size.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://main.tscn").instantiate()
	root.add_child(room)
	await create_timer(0.2).timeout
	room.camera.enabled = false
	for child in room.get_children():
		if child is CanvasLayer: child.visible = false
	for i in room.LEVELS.size():
		room.load_level(i)
		room.spawn_dummies()
		room.player.reset()
		room.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://previews/level-%d-%s.png" % [i + 1, str(room.level["name"]).to_lower()]
		root.get_texture().get_image().save_png(path)
		print("wrote %s" % path)
	quit()
