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
	enemy.reset()
	enemy.health=100
	enemy.apply_ailment("poison",1.0,3)
	enemy.tick_ailments(0.4)
	enemy.apply_ailment("poison",1.0,2)
	enemy.tick_ailments(0.1)
	check(enemy.health==97,"Reapplying poison preserves tick progress and stronger damage")
	enemy.tick_ailments(2.0)
	check(enemy.health==94 and enemy.ailments.is_empty(),"Poison stops at expiry, including a long frame")
	enemy.apply_ailment("bleed",3,4)
	enemy.reset()
	enemy.health=100
	check(enemy.ailments.is_empty(),"Reset clears ailments")
	var projectile_script=preload("res://scripts/thorn_projectile.gd")
	check(projectile_script.segment_contact(Vector2.ZERO,Vector2(100,0),Rect2(45,-5,10,10))==Vector2(45,0),"Swept thorn detects a crossed narrow enemy")
	check(projectile_script.segment_contact(Vector2.ZERO,Vector2(100,0),Rect2(45,15,10,10))==null,"Swept thorn rejects a missed enemy")
	p.position=Vector2(500,681)
	enemy.position=Vector2(550,682)
	var thorn=projectile_script.new()
	thorn.actor=p
	thorn.position=Vector2(500,680)
	room.add_child(thorn)
	thorn.set_physics_process(false)
	thorn._physics_process(0.2)
	check(enemy.health==92,"Fast thorn contacts enemy exactly once")
	await process_frame
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size=Vector2(8,80)
	shape.shape=box
	wall.add_child(shape)
	wall.position=Vector2(520,660)
	room.add_child(wall)
	await physics_frame
	await physics_frame
	thorn=projectile_script.new()
	thorn.actor=p
	thorn.position=Vector2(500,680)
	room.add_child(thorn)
	thorn.set_physics_process(false)
	thorn._physics_process(0.2)
	check(enemy.health==92 and thorn.is_queued_for_deletion(),"Terrain blocks thorn before the enemy")
	room.remove_child(wall)
	wall.queue_free()
	await physics_frame
	for class_id in [1,3]:
		room.select_class(class_id)
		for style in 4:
			p.combat.cancel()
			p.reset()
			p.position=Vector2(500,720)
			p.burrowed=true
			p.facing=1
			enemy.reset()
			enemy.health=100
			enemy.position=Vector2(548,682)
			p.combat.select_style(style)
			check(p.combat.start(),"Burrow starts class %d style %d" % [class_id,style])
			p.combat.tick(p.combat.combo_duration()*0.37)
			check(not p.burrowed and p.air_jump and p.burrow_cooldown>0 and enemy.health<100,"Eruption hits, restores collision/jump and starts cooldown")
			if class_id==1 and style<2: check(enemy.ailments.has("bleed" if style==0 else "poison"),"Strider eruption applies selected ailment")
			if class_id==3 and style==2: check(enemy.half_buried and enemy.buried>0,"Root eruption leaves target half buried")
			p.combat.cancel()
		p.reset()
		p.stamina=0
		check(not p.combat.start(),"Empty stamina prevents a new attack")
	var effect=preload("res://scripts/skirmisher_effect.gd").new()
	room.add_child(effect)
	room.load_map(1)
	check(not effect.is_inside_tree(),"Map changes remove previous combat effects")
	print("Roster systems: %d failures" % failures)
	quit(failures)
