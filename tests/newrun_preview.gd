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
	actor.position = Vector2(200,470)
	actor.scale = Vector2(2.4,2.4)
	var rig: Node2D = actor.appearance.get_child(0)
	rig.set_process(false)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.09,0.11,0.15)
	backdrop.size = Vector2(1280,800)
	backdrop.z_index = -10
	root.add_child(backdrop)
	DirAccess.make_dir_recursive_absolute("/tmp/newrun")
	actor.position = Vector2(640,470)
	var names := ["idle","run0","run1","run2","run3"]
	var frames := [-1, 0, 1, 2, 3]  # -1 = idle
	for i in frames.size():
		if frames[i] < 0:
			rig.run_frame = -1
			rig.frame = 0
		else:
			rig.run_frame = frames[i]
		rig.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/newrun/%s.png" % names[i])
	quit()
