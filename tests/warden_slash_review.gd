extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://main.tscn").instantiate()
	root.add_child(room)
	var actor: CharacterBody2D = load("res://scripts/player.gd").new()
	actor.world = room
	root.add_child(actor)
	actor.reset()
	await create_timer(0.15).timeout
	room.camera.enabled = false
	room.visible = false
	room.set_process(false)
	room.player.set_physics_process(false)
	for child in room.get_children():
		if child is CanvasLayer: child.visible = false
	actor.set_physics_process(false)
	actor.appearance.set_process(false)
	actor.position = Vector2(600,480)
	actor.scale = Vector2(3,3)
	var rig: Node2D = actor.appearance.get_child(0)
	rig.set_process(false)
	var title := Label.new()
	title.position = Vector2(50,40)
	title.add_theme_font_size_override("font_size",24)
	root.add_child(title)
	DirAccess.make_dir_recursive_absolute("/tmp/underfoot-warden-slash")
	for frame in 180:
		actor.velocity.x = 180 if frame < 85 else 0
		actor.facing = 1 if frame < 45 or frame >= 85 else -1
		if frame == 90: rig.start_slash()
		if frame == 135:
			actor.facing = -1
			rig.start_slash()
		rig._process(1.0/30)
		title.text = "WARDEN · " + rig.pose + "\n180 px/s · acceleration 900 · sheathed weapon"
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/underfoot-warden-slash/frame-%03d.png" % frame)
	quit()
