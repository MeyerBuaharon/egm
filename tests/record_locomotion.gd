extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://main.tscn").instantiate()
	root.add_child(room)
	var actors: Array[CharacterBody2D] = []
	for row in 4:
		var actor: CharacterBody2D = load("res://scripts/player.gd").new()
		actor.world = room
		root.add_child(actor)
		actor.reset()
		actors.append(actor)
	await create_timer(0.15).timeout
	room.camera.enabled = false
	room.visible = false
	room.set_process(false)
	room.player.set_physics_process(false)
	for child in room.get_children():
		if child is CanvasLayer:
			child.visible = false
	var title := Label.new()
	title.position = Vector2(35,45)
	title.add_theme_font_size_override("font_size",26)
	root.add_child(title)
	for row in 4:
		var actor: CharacterBody2D = actors[row]
		actor.set_physics_process(false)
		actor.position = Vector2(140+row*320,480)
		actor.scale = Vector2(3.5,3.5)
		actor.air_jump = false
		actor.appearance.class_index = row
		actor.appearance.weapon_index = row
		actor.appearance.heavy = row==1
		actor.appearance.set_process(false)
		var label := Label.new()
		label.text = actor.appearance.NAMES[row]
		label.position = Vector2(85+row*320,600)
		root.add_child(label)
	DirAccess.make_dir_recursive_absolute("/tmp/underfoot-run-preview")
	for frame in 75:
		var t := frame/30.0
		var speed := clampf((t-0.25)/0.15,0,1)*340 if t < 1.6 else maxf(0,340-(t-1.6)*2400)
		for actor in actors:
			actor.velocity.x = speed
			actor.appearance._process(1.0/30)
		title.text = "Stand → push off → run → settle     |     " + actors[0].appearance.pose
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/underfoot-run-preview/frame-%03d.png" % frame)
	quit()
