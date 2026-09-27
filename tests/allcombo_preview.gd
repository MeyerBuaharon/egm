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
	for child in room.get_children():
		if child is CanvasLayer: child.visible = false
	actor.set_physics_process(false)
	actor.appearance.set_process(false)
	actor.position = Vector2(640,460)
	actor.scale = Vector2(2.2,2.2)
	var rig: Node2D = actor.appearance.get_child(0)
	rig.set_process(false)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.09,0.11,0.15)
	backdrop.size = Vector2(1280,800)
	backdrop.z_index = -10
	root.add_child(backdrop)
	var combat = actor.combat
	combat.active = true
	combat.mode = combat.Mode.REGULAR
	actor.facing = 1.0
	DirAccess.make_dir_recursive_absolute("/tmp/allcombo")
	for weapon in 4:
		combat.weapon = weapon
		for cellidx in 18:
			var hit := cellidx / 6
			var phase := cellidx % 6
			combat.combo_index = hit + 1
			var frac: float = [0.08,0.25,0.39,0.50,0.68,0.90][phase]
			combat.time = combat.combo_duration() * frac
			rig._process(1.0/60)
			rig.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/allcombo/w%d-%02d.png" % [weapon, cellidx])
	quit()
