extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	room.select_class(2)
	var p: CharacterBody2D = room.player
	p.set_physics_process(false)
	for mob in room.combat_targets:
		mob.set_physics_process(false)
	await physics_frame
	var enemy: Node2D = room.combat_targets[0]
	for element in 4:
		p.reset()
		p.position = Vector2(400,681)
		p.velocity = Vector2(0,1)
		p.move_and_slide()
		p.facing = 1
		enemy.reset()
		enemy.position = Vector2(510,682)
		check(p.combat.select_element(element),"Select element %d" % element)
		for stage in range(1,4):
			check(p.combat.start(),"Element %d starts hit %d" % [element,stage])
			var budget := 200
			while p.combat.active and budget>0:
				p.combat.tick(1.0/120)
				budget -= 1
			if stage<3:
				check(enemy.frozen==0 and enemy.burning==0 and enemy.buried==0 and not enemy.knocked,"Early hits do not apply finisher status")
		check(enemy.health==18 and p.mana==74,"Three hits damage once each and spend 26 MP")
		match element:
			0:
				check(enemy.burning==4,"Fire applies burn")
				for i in 60:
					enemy._physics_process(1.0/120)
				check(enemy.health==16,"Burn damages over time")
			1:
				var at: Vector2 = enemy.position
				for i in 90:
					enemy._physics_process(1.0/120)
				check(enemy.frozen>0 and enemy.position==at and enemy.attack_time<0,"Ice freezes movement and attacks")
			2:
				var height: float = enemy.position.y
				for i in 15:
					enemy._physics_process(1.0/120)
				check(enemy.knocked and enemy.position.y<height-40,"Wind launches enemy upward")
			3:
				enemy._process(0)
				check(enemy.buried>0 and enemy.half_buried and enemy.sprite.visible,"Earth leaves upper body visible")
				check(enemy.sprite.material.get_shader_parameter("clip_y")<100,"Buried lower half is clipped at ground")
				for i in 310:
					enemy._physics_process(1.0/120)
				check(enemy.buried==0 and not enemy.half_buried,"Earth burial expires")
	# Three visible phases per attack, with hit detection aligned to release.
	p.reset()
	p.position = Vector2(400,681)
	enemy.reset()
	enemy.position = Vector2(510,682)
	p.combat.select_element(0)
	p.combat.start()
	check(p.combat.animation_frame()==0,"Attack begins with anticipation")
	p.combat.tick(p.combat.combo_duration()*0.41)
	check(enemy.health==40 and p.combat.animation_frame()==0,"Anticipation does not damage")
	p.combat.tick(p.combat.combo_duration()*0.02)
	check(enemy.health==34 and p.combat.animation_frame()==1,"Release frame deals damage")
	p.combat.tick(p.combat.combo_duration()*0.31)
	check(enemy.health==34 and p.combat.animation_frame()==2,"Recovery does not deal damage twice")
	p.combat.cancel()
	# Numbered leveling slots never change the basic attack element.
	room.set_process(false)
	await process_frame
	Input.action_press("ability_1")
	room._process(0)
	Input.action_release("ability_1")
	check(p.combat.element==0,"Ability key is independent from elements")
	Input.action_press("cycle_element")
	room._process(0)
	Input.action_release("cycle_element")
	check(p.combat.element==1,"Q cycles the basic attack element")
	room.character_level = 4
	room.experience = room.experience_needed-25
	room.action_hud.update_tooltips()
	check("unlocks at level 5" in room.action_hud.get_child(4).tooltip_text,"Leveling slot starts locked")
	room.award_mob_xp()
	room.action_hud.update_tooltips()
	check("unlocked, no ability equipped" in room.action_hud.get_child(4).tooltip_text,"Earning level 5 unlocks an empty ability slot")
	# Insufficient MP cannot start a cast; switching mid-cast cannot change effect.
	p.reset()
	p.mana = 2
	check(not p.combat.start(),"MP gates casting")
	p.mana = 100
	p.combat.start()
	check(not p.combat.select_element(0),"Element cannot change during a cast")
	p.combat.cancel()
	room.select_class(0)
	check(not ("element" in p.combat),"Switching to Warden restores original combat")
	print("Mage elements: %d failures" % failures)
	quit(failures)

func check(passed: bool, description: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL",description])
	if not passed:
		failures += 1
