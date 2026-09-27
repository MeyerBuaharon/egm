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
	DirAccess.make_dir_recursive_absolute("/tmp/underfoot-warden-preview")
	for frame in 120:
		var t := frame/30.0
		actor.velocity.x = clampf((t-0.3)*actor.warden_acceleration,0,actor.warden_run_speed) if t < 1.65 else 0
		if frame >= 65 and frame < 94:
			actor.burrowed = true
			actor.burrow_time = (frame-65)/30.0
			actor.position.y = 480+44*3
		else:
			actor.burrowed = false
			actor.position.y = 480
		if frame == 94: rig.on_feedback("emerge",actor.position)
		rig._process(1.0/30)
		title.text = "WARDEN · " + rig.pose + "\n180 px/s · acceleration 900 · sheathed weapon"
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/underfoot-warden-preview/frame-%03d.png" % frame)
	quit()
