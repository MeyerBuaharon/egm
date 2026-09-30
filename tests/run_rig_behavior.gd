extends SceneTree
const Rig = preload("res://scripts/roster_run.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1
	print("%s %s" % ["PASS" if ok else "FAIL",label])
func _initialize() -> void: call_deferred("run")
func run() -> void:
	check(Rig.foot(0).x > Rig.foot(0.5).x and Rig.foot(0.5).x < Rig.foot(1).x,"near and far feet exchange the leading position")
	check(Rig.foot(0).is_equal_approx(Rig.foot(1)),"seamless foot-loop wrap")
	check(Rig.foot(0.25).y == -6 and Rig.foot(0.75).y < -20,"support stays grounded while opposite foot recovers")
	for index in 2:
		var pieces := Rig.parts(index)
		var a := Rig.part_length(pieces[0])
		var b := Rig.part_length(pieces[1])
		var stable := true
		for sample in 240:
			var phase := sample/240.0
			var hip := Vector2(0,-30+cos(phase*TAU*2)*1.3)
			var target := Rig.foot(phase,index)
			var joint := Rig.knee(hip,target,a,b)
			stable = stable and absf(hip.distance_to(joint)-a)<0.02 and absf(joint.distance_to(target)-b)<0.02
		var slip: float = (Rig.foot(0.1,index).x-Rig.foot(0.2,index).x)-Rig.CYCLE_DISTANCE[index]*0.1
		check(absf(slip)<0.001,"planted foot matches ground travel")
		check(stable,"class %d maintains rigid thigh/shin lengths through whole stride" % index)
	var room: Node2D=load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for i in 10: await physics_frame
	var p: CharacterBody2D=room.player
	p.set_physics_process(false)
	for class_id in [1,3]:
		room.select_class(class_id)
		p.position=Vector2(210,681)
		p.velocity=Vector2(0,1)
		p.move_and_slide()
		var visual: Node2D=p.appearance.get_child(3)
		p.velocity.x=p.current_run_speed()
		visual._process(0.1)
		check(visual.run_frame>=0,"class %d uses new run on ground" % class_id)
		p.velocity.x=0
		visual._process(0)
		check(visual.run_frame<0 and visual.run_clock==0,"idle resets stride")
		p.position.y=500
		p.velocity=Vector2(0,-100)
		p.move_and_slide()
		visual._process(0)
		check(visual.run_frame<0,"airborne uses jump art")
		p.burrowed=true
		visual._process(0)
		check(visual.frame==11 and visual.run_frame<0,"burrow keeps dedicated pose")
		p.burrowed=false
	print("Run rig: %d failures" % failures)
	quit(failures)
