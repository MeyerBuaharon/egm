extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL",label])
	if not ok: failures+=1
func run() -> void:
	var room: Node2D=load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for i in 12: await physics_frame
	var p: CharacterBody2D=room.player
	p.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
	check(p.equipment.SLOTS==["Ring 1","Ring 2","Amulet","Heart socket","Lung socket","Hand socket","Core socket"],"Only jewelry and body gem slots remain")
	check(room.pickups.filter(func(item): return item.class_id>=0).size()==28,"All classes have seven non-armor pickups")
	for class_id in 4:
		room.select_class(class_id)
		p.reset()
		p.position=Vector2(500,681)
		var speed: float=p.current_run_speed()
		check(not p.use_gem(0),"An unsocketed gem cannot activate")
		for slot in 7: check(p.equipment.pickup(class_id,slot),"Collect %s for class %d" % [p.equipment.NAMES[slot],class_id])
		check(is_equal_approx(p.current_run_speed(),speed*1.15),"Gale provides movement bonus")
		p.take_damage(20)
		check(p.health==85,"Signet and heart gem reduce damage by five")
		p.mana=20
		p.stamina=20
		p.stamina_regen_wait=0
		p.tick_resources(1)
		check(p.mana==31 and p.stamina==42,"Jewelry adds mana and stamina regeneration")
		p.mana=100
		p.gem_cooldowns.fill(0.0)
		var enemy: Node2D=room.combat_targets[0]
		enemy.reset()
		enemy.position=Vector2(550,682)
		check(p.use_gem(0) and enemy.health==20 and p.mana==85,"Nova damages once and spends MP")
		check(not p.use_gem(0) and p.mana==85,"Cooldown blocks repeated Nova without spending MP")
		p.health=60
		check(p.use_gem(1) and p.health==85 and p.mana==65,"Renewal restores health and spends MP")
		p.equipment.set_worn(class_id,5,false)
		p.gem_cooldowns[0]=0
		check(not p.use_gem(0),"Removing a gem disables its active ability")
		p.equipment.set_worn(class_id,4,false)
		check(is_equal_approx(p.current_run_speed(),speed),"Removing Gale restores movement speed")
		p.equipment.set_worn(class_id,5,true)
		p.mana=0
		check(not p.use_gem(0),"Insufficient mana blocks gem ability")
		p.reset()
	room.load_map(1)
	check(p.equipment.owned[3][6],"Map change preserves gems")
	room.character_creation.open()
	room.character_creation.name_input.text="Rowan"
	room.character_creation.apply_choice()
	check(not paused and p.character_name=="Rowan","Name editor resumes gameplay")
	print("Gem equipment: %d failures" % failures)
	quit(failures)
