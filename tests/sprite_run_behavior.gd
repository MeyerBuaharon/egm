extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1
	print("%s %s" % ["PASS" if ok else "FAIL",label])
func _initialize() -> void: call_deferred("run")
func run() -> void:
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
	print("Sprite run: %d failures" % failures)
	quit(failures)
