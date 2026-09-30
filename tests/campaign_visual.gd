extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var room: Node2D=load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for i in 10: await physics_frame
	room.player.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
	room.player.position=Vector2(280,681)
	await capture("res://previews/campaign-forest.png")
	room.progress.embers=45
	room.progress.points=4
	room.progress.buy("edge")
	room.passive_tree.open()
	await capture("res://previews/passive-tree.png")
	room.passive_tree.close_tree()
	room.load_map(1)
	room.player.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
	await capture("res://previews/campaign-grove.png")
	room.load_map(2)
	room.player.set_physics_process(false)
	room.player.position=Vector2(760,681)
	room.boss.set_physics_process(false)
	room.boss.engaged=true
	room.boss.choose_attack()
	for hazard in get_nodes_in_group("boss_hazards"):
		hazard.set_physics_process(false)
		hazard.age=0.6
		hazard.queue_redraw()
	await capture("res://previews/campaign-boss-warning.png")
	for hazard in get_nodes_in_group("boss_hazards"):
		hazard.fired=true
		hazard.age=hazard.warning+0.1
		hazard.queue_redraw()
	room.boss.health=220
	room.boss.enraged=true
	await capture("res://previews/campaign-boss-eruption.png")
	room.boss.regular_hit(10000)
	room.boss._physics_process(2.5)
	room.player.position=Vector2(1010,681)
	await capture("res://previews/campaign-victory.png")
	print("Campaign visual captures complete")
	quit()
