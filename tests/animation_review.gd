extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://main.tscn").instantiate()
	root.add_child(room)
	var actors: Array[CharacterBody2D] = []
	for row in 4:
		for col in 8:
			var actor: CharacterBody2D = load("res://scripts/player.gd").new()
			actor.world = room
			root.add_child(actor)
			actor.reset()
			actors.append(actor)
	await create_timer(0.2).timeout
	room.camera.enabled = false
	room.visible = false
	room.set_process(false)
	room.player.set_physics_process(false)
	for child in room.get_children():
		if child is CanvasLayer:
			child.visible = false
	for row in 4:
		var label := Label.new()
		label.text = ["Warden / sword", "Strider / heavy hammer", "Hexbinder / staff", "Wildborn / daggers"][row]
		label.position = Vector2(20, row*185+10)
		root.add_child(label)
		for col in 8:
			var actor: CharacterBody2D = actors[row*8+col]
			actor.set_physics_process(false)
			actor.position = Vector2(75+col*156, row*185+135)
			actor.scale = Vector2(2,2)
			actor.velocity.x = 340
			actor.air_jump = false
			var rig: Node2D = actor.appearance
			rig.set_process(false)
			rig.class_index = row
			rig.weapon_index = row
			rig.heavy = row == 1
			rig.phase = col / 8.0
			rig.run_blend = 1.0
			rig.update_pose(1)
			rig.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://animation-run-review.png")
	for row in 4:
		for col in 8:
			var actor: CharacterBody2D = actors[row*8+col]
			var rig: Node2D = actor.appearance
			actor.velocity.x = 0
			actor.burrowed = col < 4
			rig.on_action("dig" if col < 4 else "emerge",actor.position)
			rig.action_time = rig.action_duration * (1 - float(col%4)/4)
			rig.update_pose(0.1)
			if col < 4:
				actor.position.y += 44*2
			rig.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://animation-burrow-review.png")
	quit()
