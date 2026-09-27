extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://main.tscn").instantiate()
	root.add_child(room)
	await process_frame
	room.player.position.x = 140
	for index in range(1, 4):
		var player: CharacterBody2D = load("res://scripts/player.gd").new()
		player.world = room
		room.add_child(player)
		player.reset()
		player.position.x = 140 + index * 240
		player.appearance.class_index = index
		player.appearance.weapon_index = index
		player.appearance.heavy = index % 2 == 1
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://character-lab.png")
	quit()
