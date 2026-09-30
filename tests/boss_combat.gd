extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var room: Node2D=load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	room.load_map(2)
	var p: CharacterBody2D=room.player
	p.set_physics_process(false)
	var boss: Node2D=room.boss
	boss.set_physics_process(false)
	for class_id in 4:
		p.combat.cancel()
		room.select_class(class_id)
		for style in 4:
			p.reset()
			p.position=Vector2(933,681)
			p.velocity=Vector2(0,1)
			p.move_and_slide()
			p.facing=1
			boss.reset()
			if class_id==2: p.combat.select_element(style)
			elif class_id in [1,3]: p.combat.select_style(style)
			else:
				p.combat.selected=style
				p.combat.weapon=style
			var started: bool=p.combat.start()
			for i in 130:
				if p.combat.active: p.combat.tick(0.01)
				await physics_frame
			var ok: bool=started and boss.health<boss.MAX_HEALTH
			if not ok: failures+=1
			print("%s class %d style %d damages boss through normal combat (%d HP remaining)" % ["PASS" if ok else "FAIL",class_id,style,boss.health])
	print("Boss combat: %d failures" % failures)
	quit(failures)
