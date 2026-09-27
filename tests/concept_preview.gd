extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://concept_preview.tscn").instantiate()
	root.add_child(room)
	var failures := 0
	for sample in [Vector2(100,404),Vector2(580,380),Vector2(900,424),Vector2(1280,451),Vector2(1800,443)]:
		room.player.reset()
		var feet: Vector2 = sample * 2.0 + Vector2(0,-600)
		room.player.position = feet - Vector2(0,80)
		for frame in 90:
			await physics_frame
		var error: float = absf(room.player.position.y + room.player.HALF_HEIGHT - feet.y)
		if not room.player.is_on_floor() or error > 10:
			push_error("Ground mismatch at %s: %.1f" % [sample,error])
			failures += 1
	Input.action_press("right")
	var emitted_dust := false
	for frame in 90:
		await physics_frame
		emitted_dust = emitted_dust or not room.dust.is_empty()
	Input.action_release("right")
	if not emitted_dust:
		push_error("Walking did not produce dust")
		failures += 1
	print("Concept preview: five ground samples and walking dust; %d failures" % failures)
	quit(failures)
