extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL",label])
	if not ok: failures+=1
func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	room.player.warden_fullbody_enabled=true
	for mob in room.combat_targets: mob.set_physics_process(false)
	var p: CharacterBody2D = room.player
	for i in 10: await physics_frame
	var visual: Node2D = p.appearance.get_child(2)
	check(visual.visible and not p.appearance.get_child(0).visible,"Forest Warden uses intact body renderer")
	p.set_physics_process(false)
	visual.set_process(false)
	p.velocity.x=180
	for dt in [1.0/60,1.0/240]:
		var seen: Array[int] = []
		visual.run_clock=0
		for i in int(1.0/dt):
			visual._process(dt)
			if not visual.frame in seen: seen.append(visual.frame)
		check(seen.size()==6,"Six running frames play at normal/slow preview rate")
	p.velocity.x=0
	visual._process(0.016)
	check(visual.frame==0,"Stopping returns to upright idle")
	p.facing=-1
	p.velocity.x=-180
	visual._process(0.2)
	check(visual.frame in visual.RUN,"Reversal keeps running poses")
	p.velocity.x=0
	for hit in 3:
		p.combat.active=true
		p.combat.combo_index=hit+1
		var seen: Array[int] = []
		for i in 60:
			p.combat.time=p.combat.combo_duration()*float(i)/60
			visual._process(0.016)
			if not visual.combat_frame in seen: seen.append(visual.combat_frame)
		check(seen==[hit*3,hit*3+1,hit*3+2],"Each combo hit selects anticipation/strike/recovery")
	p.combat.cancel()
	p.burrowed=true
	p.burrow_time=0.1
	visual._process(0.016)
	check(visual.frame==11,"Burrow selects grounded digging pose")
	p.burrowed=false
	p.feedback.emit("emerge",p.position)
	visual._process(0.016)
	check(visual.frame==15,"Emergence selects upward burst pose")
	print("Warden full-body motion: %d failures" % failures)
	quit(failures)
