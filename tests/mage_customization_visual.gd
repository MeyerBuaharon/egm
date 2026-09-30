extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	room.select_class(2)
	await create_timer(0.1).timeout
	var p: CharacterBody2D = room.player
	p.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
	p.position = Vector2(210,681)
	p.velocity = Vector2(0,1)
	p.move_and_slide()
	var visual: Node2D = p.appearance.get_child(1)
	visual.set_process(false)
	visual.clock = 0
	room.camera.zoom = Vector2(3,3)
	room.camera.position = Vector2(210,643)
	for side in [1,-1]:
		p.facing = side
		p.velocity.x = side*160
		visual.queue_redraw()
		await capture("res://previews/mage-glide-%d.png" % side)
	for slot in 7: p.equipment.pickup(2,slot)
	visual.queue_redraw()
	await capture("res://previews/mage-glide-equipped.png")
	p.velocity.x = 0
	p.facing = 1
	visual.queue_redraw()
	room.camera.zoom = Vector2.ONE
	room.camera.position = Vector2(640,400)
	room.character_creation.open()
	await capture("res://previews/mage-creation.png")
	room.character_creation.hide()
	for slot in [0,4,6]: p.equipment.set_worn(2,slot,false)
	room.equipment_panel.show()
	await capture("res://previews/mage-inventory.png")
	quit()
