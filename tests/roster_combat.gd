extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL",label])
	if not ok: failures+=1
func run() -> void:
	var room: Node2D=load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for i in 10: await physics_frame
	var p: CharacterBody2D=room.player
	p.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
	var enemy: Node2D=room.combat_targets[0]
	for class_id in [1,3]:
		room.select_class(class_id)
		check(p.appearance.class_index==class_id,"Select new class %d" % class_id)
		for style in 4:
			p.combat.cancel()
			p.reset()
			p.position=Vector2(500,681)
			p.velocity=Vector2(0,1)
			p.move_and_slide()
			p.facing=1
			enemy.reset()
			enemy.position=Vector2(548,682)
			enemy.health=300
			p.combat.select_style(style)
			check(p.combat.start(),"Class %d style %d starts" % [class_id,style])
			var seen: Array[int]=[]
			for i in 400:
				if not p.combat.active: break
				if not p.combat.combo_index in seen: seen.append(p.combat.combo_index)
				if p.combat.time>0.1 and p.combat.combo_index<3 and not p.combat.queued: p.combat.start()
				p.combat.tick(0.01)
				await physics_frame
			check(seen==[1,2,3],"Three-hit combo for class %d style %d" % [class_id,style])
			check(enemy.health<300,"Style damages enemy")
			check(p.stamina<100,"Attack consumes stamina")
			if class_id==1 and style==0: check(enemy.ailments.has("bleed"),"Bloodletter applies bleed")
			if class_id==1 and style==1: check(enemy.ailments.has("poison"),"Venom applies poison")
			if class_id==3 and style==2: check(enemy.ailments.has("root"),"Wildborn roots target")
		p.combat.cancel()
		p.reset()
		p.position=Vector2(500,720)
		p.burrowed=true
		check(p.combat.start(),"Class %d burrow attack starts" % class_id)
		for i in 80:
			if p.combat.active: p.combat.tick(0.01)
		check(not p.burrowed and p.air_jump and p.burrow_cooldown>0,"Burrow attack emerges with air jump and cooldown")
	p.combat.cancel()
	room.select_class(0)
	check(p.appearance.class_index==0,"Original Warden still selectable")
	print("Roster combat: %d failures" % failures)
	quit(failures)
