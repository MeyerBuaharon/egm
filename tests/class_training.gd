extends SceneTree
var failures := 0
func check(ok: bool, text: String) -> void:
	if not ok: failures+=1
	print("%s %s" % ["PASS" if ok else "FAIL",text])
func key(world: Node, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.pressed=true
	world._input(event)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world: Node2D=load("res://class_sandbox.tscn").instantiate()
	root.add_child(world)
	for i in 4: await physics_frame
	var p: CharacterBody2D=world.player
	check(world.in_run and not world.panel.visible,"starts directly in arena")
	check(world.unlocked.size()==16,"all sixteen combat items unlocked")
	check(world.combat_targets.size()==1,"one training dummy")
	var dummy: Node2D=world.combat_targets[0]
	var defeats := [0]
	dummy.defeated.connect(func(): defeats[0]+=1)
	dummy.regular_hit(2000000000)
	dummy.apply_ailment("poison",2,1000000000)
	dummy.apply_element(0,1)
	for i in 150: await physics_frame
	check(dummy.health==dummy.max_health and defeats[0]==0 and dummy.death_time<0,"dummy survives lethal direct and DOT damage")
	check(dummy.total_damage>0,"dummy records damage")
	p.health=1
	p.stamina=0
	p.mana=0
	p.refill()
	p.take_damage(10000)
	check(p.health==100 and p.spend_mana(10000) and p.spend_stamina(10000),"unlimited health, mana and stamina")
	check(p.mana==p.max_mana and p.stamina==p.max_stamina,"spending does not drain resources")
	check(p.use_gem(1) and p.use_gem(1),"Renewal works repeatedly at full health")
	check(p.use_gem(0) and p.use_gem(0),"Nova has no recharge")
	for entry in [[KEY_F1,0],[KEY_F2,2],[KEY_F3,1],[KEY_F4,3]]:
		key(world,entry[0])
		check(world.locked_job==entry[1],"class shortcut %d" % entry[0])
		for slot in 7: check(p.equipment.has_equipped(entry[1],slot),"supplied equipment slot %d" % slot)
	for slot in 4:
		key(world,KEY_F5+slot)
		check(world.locked_slot==slot,"direct item shortcut %d" % slot)
	key(world,KEY_Q)
	check(world.locked_slot==0,"Q cycles item")
	key(world,KEY_K)
	check(world.item_library.visible and not p.is_physics_processing(),"item library pauses actors")
	check(world.item_library.list.get_child_count()==29,"all sixteen weapons, seven equipment items and power gem listed")
	# Click Hexbinder's fire grimoire entry through its actual Use button.
	world.item_library.list.get_child(6).get_child(2).pressed.emit()
	check(world.locked_job==2 and world.locked_slot==0 and not world.item_library.visible,"library Use changes class and item")
	key(world,KEY_K)
	# First jewelry row follows 4 headers+16 items and the equipment header.
	world.item_library.list.get_child(21).get_child(2).pressed.emit()
	check(not p.equipment.has_equipped(2,0),"library Unequip works")
	world.item_library.list.get_child(21).get_child(2).pressed.emit()
	check(p.equipment.has_equipped(2,0),"library Equip works")
	key(world,KEY_ESCAPE)
	check(not world.item_library.visible and p.is_physics_processing(),"Escape resumes training")
	print("Class training: %d failures" % failures)
	quit(failures)
