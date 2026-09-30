extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL",label])
	if not ok: failures+=1
func run() -> void:
	var room: Node2D=load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for i in 12:
		await physics_frame
		await process_frame
	var p: CharacterBody2D=room.player
	p.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
	var visual: Node2D=p.appearance.get_child(0)
	visual.set_process(false)
	check(visual.visible and not p.appearance.get_child(2).visible,"Original Warden is the forest default")
	for weapon in 4:
		p.combat.cancel()
		p.combat.selected=weapon
		p.velocity=Vector2(0,1)
		p.move_and_slide()
		check(p.combat.start(),"Original weapon attack starts: %d" % weapon)
		var seen: Array[int]=[]
		for i in 100:
			p.combat.tick(0.01)
			visual._process(0.01)
			if visual.slash_frame>=0 and not visual.slash_frame in seen: seen.append(visual.slash_frame)
			if not p.combat.active: break
		check(seen.size()==6,"Six authored combat phases retained: %d" % weapon)
	p.combat.cancel()
	room.character_creation.open()
	check("Warden" in room.character_creation.title.text,"Warden uses a name-only identity panel")
	room.character_creation.hide()
	room.select_class(2)
	room.character_creation.open()
	check("Hexbinder" in room.character_creation.title.text,"Mage uses a fixed model and name-only panel")
	room.character_creation.hide()
	room.select_class(0)
	visual._process(0)
	if DisplayServer.get_name()!="headless":
		room.camera.zoom=Vector2(3,3)
		room.camera.position=p.position+Vector2(0,-30)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://previews/warden-restored.png")
	quit(failures)
