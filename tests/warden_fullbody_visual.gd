extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func shot() -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	room.player.warden_fullbody_enabled=true
	await create_timer(0.15).timeout
	var p: CharacterBody2D = room.player
	p.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
	p.position = Vector2(210,681)
	p.velocity = Vector2(0,1)
	p.move_and_slide()
	var visual: Node2D = p.appearance.get_child(2)
	visual.set_process(false)
	visual.frame = 0
	for slot in 7: p.equipment.pickup(0,slot)
	var base: Image
	for outfit in 6:
		for slot in 4: p.equipment.set_worn(0,slot,outfit==5 or outfit==slot+1)
		visual.queue_redraw()
		var capture: Image = await shot()
		var region := capture.get_region(Rect2i(155,565,130,136))
		if outfit==0: base=region
		else:
			var changed := 0
			for y in 136:
				for x in 130:
					var a := region.get_pixel(x,y)
					var b := base.get_pixel(x,y)
					if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.1: changed+=1
			print("%s Warden outfit %d changed %d pixels" % ["PASS" if changed>8 else "FAIL",outfit,changed])
			if changed<=8: failures+=1
	for slot in 4: p.equipment.set_worn(0,slot,false)
	visual.queue_redraw()
	var restored: Image = await shot()
	if restored.get_region(Rect2i(155,565,130,136)).get_data()!=base.get_data():
		print("FAIL outfit removal restores base")
		failures+=1
	var montage := Image.create(1280,1200,false,Image.FORMAT_RGBA8)
	for gear in 2:
		for slot in 4: p.equipment.set_worn(0,slot,gear==1)
		for side in 2:
			p.facing = 1 if side==0 else -1
			for frame in 16:
				visual.frame=frame
				visual.queue_redraw()
				var capture: Image = await shot()
				var index := gear*32+side*16+frame
				montage.blit_rect(capture,Rect2i(130,555,160,150),Vector2i(index%8*160,index/8*150))
	montage.save_png("res://previews/warden-fullbody-motion.png")
	var attacks := Image.create(1440,1200,false,Image.FORMAT_RGBA8)
	for weapon in 4:
		p.combat.weapon=weapon
		for side in 2:
			p.facing=1 if side==0 else -1
			for frame in 9:
				visual.combat_frame=frame
				visual.frame=12+frame%3
				visual.queue_redraw()
				var capture: Image = await shot()
				attacks.blit_rect(capture,Rect2i(130,555,160,150),Vector2i(frame*160,(weapon*2+side)*150))
	attacks.save_png("res://previews/warden-fullbody-combos.png")
	p.facing=1
	p.combat.weapon=0
	visual.combat_frame=-1
	visual.frame=0
	visual.queue_redraw()
	room.camera.zoom=Vector2(3,3)
	room.camera.position=Vector2(210,650)
	(await shot()).save_png("res://previews/warden-fullbody-equipped.png")
	for slot in 4: p.equipment.set_worn(0,slot,false)
	visual.queue_redraw()
	(await shot()).save_png("res://previews/warden-fullbody-base.png")
	room.camera.zoom=Vector2.ONE
	room.camera.position=Vector2(640,400)
	room.character_creation.open()
	(await shot()).save_png("res://previews/warden-creation.png")
	room.character_creation.hide()
	print("Warden visual checks: %d failures" % failures)
	quit(failures)
