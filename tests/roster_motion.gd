extends SceneTree
# Deterministic 30 fps review: idle, run/glide, reversal, fixed-model combo.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var room: Node2D=load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for i in 12: await physics_frame
	var p: CharacterBody2D=room.player
	p.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
	room.camera.zoom=Vector2(3,3)
	room.camera.position=Vector2(210,648)
	DirAccess.make_dir_recursive_absolute("/tmp/roster-motion")
	for class_id in 4:
		p.combat.cancel()
		room.select_class(class_id)
		p.reset()
		for slot in 4:
			p.equipment.pickup(class_id,slot)
		for child in p.appearance.get_children():
			if child.has_method("_process"):
				child._process(0)
				child.set_process(false)
		var visual: Node2D=p.appearance.get_child(0 if class_id==0 else (1 if class_id==2 else 3))
		var montage := Image.create(1440,1500,false,Image.FORMAT_RGBA8)
		for frame in 180:
			p.position=Vector2(210,681)
			p.velocity=Vector2(0,1)
			p.move_and_slide()
			if frame<12: p.facing=1
			elif frame<84:
				p.facing=1 if frame<48 else -1
				p.velocity.x=p.facing*p.current_run_speed()
			elif frame==84:
				p.facing=1
				p.combat.start()
			if p.combat.active:
				if p.combat.time>0.12 and p.combat.combo_index<3 and not p.combat.queued: p.combat.start()
				p.combat.tick(1.0/30)
			visual._process(1.0/30)
			await process_frame
			await RenderingServer.frame_post_draw
			var capture := root.get_texture().get_image()
			capture.save_png("/tmp/roster-motion/frame-%04d.png" % (class_id*180+frame))
			if frame%6==0:
				var index := frame/6
				montage.blit_rect(capture,Rect2i(520,280,240,300),Vector2i((index%6)*240,int(index/6)*300))
		montage.save_png("res://previews/roster-%d-motion.png" % class_id)
		print("Captured class %d idle, forward/reverse motion, combo, fixed appearance" % class_id)
	quit()
