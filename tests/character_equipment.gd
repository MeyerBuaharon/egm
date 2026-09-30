extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL",label])
	if not ok: failures += 1
func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	var p: CharacterBody2D = room.player
	p.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
	await process_frame
	for class_id in 4:
		room.select_class(class_id)
		check(not p.equipment.has_equipped(class_id,1),"Class starts without jewelry or gems")
		check(not p.equipment.set_worn(class_id,0,true),"Cannot equip uncollected item")
		p.position = Vector2(1000,681)
		check(not room.pickup_nearest(),"Distant pickup rejected")
		for slot in 7:
			p.position = Vector2(185+slot*62,681)
			check(room.pickup_nearest(),"Collect class %d slot %d" % [class_id,slot])
			check(p.equipment.has_equipped(class_id,slot),"Pickup equips the correct slot")
			check(not p.equipment.pickup(class_id,slot),"Duplicate pickup rejected")
			room.equipment_panel.rows[slot].pressed.emit()
			check(not p.equipment.has_equipped(class_id,slot) and p.equipment.owned[class_id][slot],"Remove keeps item in inventory")
			check(p.equipment.bag_slots(class_id)==[slot],"Removed gear appears in bag")
			room.equipment_panel.bag_buttons[0].pressed.emit()
			check(p.equipment.has_equipped(class_id,slot),"Inventory re-equips item")
		p.reset()
		check(p.equipment.has_equipped(class_id,3),"Reset preserves equipment")
	room.load_map(1)
	check(room.pickups.all(func(item): return item.class_id<0) and p.equipment.has_equipped(2,1),"Next map keeps loadout")
	room.load_map(0)
	check(room.pickups.all(func(item): return item.class_id<0),"Collected gear does not respawn on return")
	room.select_class(0)
	check(p.equipment.has_equipped(0,1),"Warden loadout survives switching classes")
	check(not p.equipment.pickup(0,9) and not p.equipment.set_worn(7,0,true),"Invalid equipment requests rejected")
	room.select_class(2)
	var creator: Control = room.character_creation
	creator.open()
	check(paused,"Character creation pauses gameplay")
	creator.name_input.text = "  Rowan  "
	creator.apply_choice()
	check(not paused and p.character_name=="Rowan","Saving a name resumes gameplay")
	creator.open()
	creator.name_input.text="Discarded"
	creator.hide()
	check(p.character_name=="Rowan","Cancel preserves name")
	p.reset()
	check(p.character_name=="Rowan","Reset preserves name")
	room.select_class(0)
	creator.open()
	creator.name_input.text="Bram"
	creator.apply_choice()
	room.select_class(2)
	check(p.character_name=="Rowan","Mage name survives class changes")
	room.select_class(0)
	check(p.character_name=="Bram","Warden name survives class changes")
	print("Character equipment: %d failures" % failures)
	quit(failures)
