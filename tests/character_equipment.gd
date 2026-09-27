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
	for class_id in [0,2]:
		room.select_class(class_id)
		check(not p.equipment.has_equipped(class_id,1),"Class starts with base body")
		check(not p.equipment.set_worn(class_id,0,true),"Cannot equip uncollected item")
		p.position = Vector2(1000,681)
		check(not room.pickup_nearest(),"Distant pickup rejected")
		for slot in 4:
			p.position = Vector2(185+slot*62,681)
			check(room.pickup_nearest(),"Collect class %d slot %d" % [class_id,slot])
			check(p.equipment.has_equipped(class_id,slot),"Pickup equips the correct slot")
			check(not p.equipment.pickup(class_id,slot),"Duplicate pickup rejected")
			room.equipment_panel.rows[slot].pressed.emit()
			check(not p.equipment.has_equipped(class_id,slot) and p.equipment.owned[class_id][slot],"Remove keeps item in inventory")
			room.equipment_panel.rows[slot].pressed.emit()
			check(p.equipment.has_equipped(class_id,slot),"Inventory re-equips item")
		p.reset()
		check(p.equipment.has_equipped(class_id,3),"Reset preserves equipment")
	room.load_map(1)
	check(room.pickups.is_empty() and p.equipment.has_equipped(2,1),"Next map keeps outfit")
	room.load_map(0)
	check(room.pickups.is_empty(),"Collected gear does not respawn on return")
	room.select_class(0)
	check(p.equipment.has_equipped(0,1),"Warden loadout survives switching classes")
	check(not p.equipment.pickup(0,9) and not p.equipment.set_worn(7,0,true),"Invalid equipment requests rejected")
	print("Character equipment: %d failures" % failures)
	quit(failures)
