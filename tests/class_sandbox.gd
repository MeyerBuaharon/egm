extends SceneTree
var failures := 0
func check(ok: bool, text: String) -> void:
	if not ok: failures+=1
	print("%s %s" % ["PASS" if ok else "FAIL",text])
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world: Node2D=load("res://class_sandbox.tscn").instantiate()
	world.training_mode=false
	root.add_child(world)
	await process_frame
	check(not world.in_run and world.panel.visible,"sandbox starts at loadout selection")
	world.selected_slot=1
	world.start_selected()
	check(not world.in_run,"locked starting item cannot start run")
	world.mastery=2
	world.unlock_selected()
	check("axe" in world.unlocked and world.mastery==0,"unlock consumes mastery once")
	world.unlock_selected()
	check(world.mastery==0,"duplicate unlock cannot spend")
	for row in world.Catalog.ITEMS:
		for entry in row:
			if not entry.id in world.unlocked: world.unlocked.append(entry.id)
	for job in 4:
		for slot in 4:
			world.show_choices()
			world.selected_job=job
			world.selected_slot=slot
			world.start_selected()
			await physics_frame
			var p: CharacterBody2D=world.player
			p.set_physics_process(false)
			p.position=Vector2(565,681)
			p.velocity=Vector2(0,1)
			p.move_and_slide()
			for enemy in world.combat_targets: enemy.set_physics_process(false)
			var target: Node2D=world.combat_targets[0]
			target.position=Vector2(625,682)
			target.health=1000
			target.max_health=1000
			var before: int=target.health
			for combo in 3:
				p.stamina=100
				p.mana=100
				if not p.combat.start(): check(false,"start job %d item %d combo %d" % [job,slot,combo])
				for step in 70:
					if p.combat.active: p.combat.tick(1.0/60)
					await physics_frame
				p.position=Vector2(565,681)
				p.velocity=Vector2(0,1)
				p.move_and_slide()
			check(target.health<before,"job %d item %d deals damage through combo" % [job,slot])
			p.combat.cancel()
			p.burrowed=true
			p.stamina=100
			p.mana=100
			check(p.combat.start(),"job %d item %d starts digging attack" % [job,slot])
			for step in 100:
				if p.combat.active: p.combat.tick(1.0/60)
				await physics_frame
			check(not p.burrowed and p.collision_mask==1 and p.air_jump,"dig attack restores collision and air jump")
			var id: String=world.current_item().id
			world.selected_slot=(slot+1)%4
			world.start_selected()
			check(world.current_item().id==id,"starting item remains locked mid-run")
			var key: String=world.female_visual.key
			world.power=3
			world.female_visual._process(0)
			check(world.modify_damage(20,40,40)==29,"power gem increases damage")
			if job in [0,3]: check(world.female_visual.key==key,"build upgrades preserve appearance")
	world.show_choices()
	world.selected_job=3
	world.selected_slot=2
	world.start_selected()
	var p: CharacterBody2D=world.player
	p.set_physics_process(false)
	p.position=Vector2(450,681)
	p.facing=1
	for enemy in world.combat_targets: enemy.set_physics_process(false)
	var target: Node2D=world.combat_targets[0]
	target.position=Vector2(600,681)
	p.combat.direction=1
	p.combat.combo_index=2
	p.combat.strike_style()
	check(target.position.x==600,"root grapple does not teleport on contact")
	for step in 24: await physics_frame
	check(target.position.x<600 and target.ailments.has("root"),"root tendril grapple pulls and immobilizes")
	world.show_choices()
	world.selected_job=1
	world.selected_slot=1
	world.start_selected()
	p.set_physics_process(false)
	p.position=Vector2(560,681)
	for enemy in world.combat_targets: enemy.set_physics_process(false)
	target=world.combat_targets[0]
	target.position=Vector2(600,681)
	p.combat.direction=1
	p.combat.combo_index=1
	p.combat.strike_style()
	check(target.ailments.has("poison"),"Venom includes close-range poisoned needle")
	print("Class sandbox: %d failures" % failures)
	quit(failures)
