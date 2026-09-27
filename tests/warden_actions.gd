extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	for i in 10:
		await physics_frame
		await process_frame
	var rig = room.player.appearance.get_child(0)
	rig.set_process(false)
	check(rig.start_slash(),"slash can start")
	check(not rig.start_slash(),"repeated presses do not restart slash")
	var seen := []
	for i in 60:
		room.player.combat.tick(1.0/60)
		rig._process(1.0/60)
		if rig.slash_frame >= 0 and not rig.slash_frame in seen: seen.append(rig.slash_frame)
		if not room.player.combat.active: break
	check(seen == [0,1,2,3,4,5],"six sword windup strike follow-through recovery frames play in order")
	check(not room.player.combat.active,"attack returns to locomotion")
	room.player.burrowed = true
	room.player.position = Vector2(130,725)
	check(rig.start_slash() and not room.player.burrowed,"attack exits burrow")
	quit(failures)
