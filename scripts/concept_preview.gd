extends Node2D

const ART = preload("res://assets/levels/forest-mansion-clean-preview.png")
const ART_SCALE := 2.0
const ART_ORIGIN := Vector2(0, -600)
var blocks: Array[Rect2] = []
var targets: Array[Vector2] = []
var combat_targets: Array[Node2D] = []
var player: CharacterBody2D
var camera: Camera2D
var dust: Array[Dictionary] = []
var overview := false

func _ready() -> void:
	bind("left", [KEY_A, KEY_LEFT])
	bind("right", [KEY_D, KEY_RIGHT])
	bind("jump", [KEY_SPACE, KEY_W, KEY_UP])
	bind("dash", [KEY_SHIFT])
	bind("reset", [KEY_R])
	bind("flourish", [KEY_J])
	bind("overview", [KEY_TAB])
	# Burrowing uses the lab's fixed floor, so it is not bound in this preview.
	bind("dig", [])
	var art := Sprite2D.new()
	art.texture = ART
	art.centered = false
	art.z_index = -1
	art.position = ART_ORIGIN
	art.scale = Vector2(2048,683) / ART.get_size() * ART_SCALE
	add_child(art)
	# Surface points are authored in source-image pixels, at the visible path edge.
	add_surface([Vector2(0,400),Vector2(170,407),Vector2(340,418),Vector2(460,418),Vector2(525,392),Vector2(565,380),Vector2(640,380),Vector2(710,417),Vector2(880,423),Vector2(1030,432),Vector2(1195,428),Vector2(1235,449),Vector2(1390,456)])
	add_surface([Vector2(1390,378),Vector2(1490,380),Vector2(1560,407),Vector2(1620,437),Vector2(2048,449)])
	add_surface([Vector2(130,525),Vector2(360,555),Vector2(525,577),Vector2(690,577),Vector2(800,553),Vector2(900,536),Vector2(1040,534),Vector2(1190,542)], true)
	add_surface([Vector2(75,296),Vector2(185,298),Vector2(230,260),Vector2(360,260),Vector2(480,262),Vector2(570,239),Vector2(635,204),Vector2(770,205)], true)
	add_surface([Vector2(760,307),Vector2(890,307),Vector2(950,278),Vector2(1145,280)], true)
	add_surface([Vector2(1125,342),Vector2(1260,343),Vector2(1340,350)], true)
	add_surface([Vector2(1240,284),Vector2(1450,285)], true)
	add_surface([Vector2(1600,298),Vector2(1680,297)], true)
	player = preload("res://scripts/concept_preview_player.gd").new()
	player.world = self
	add_child(player)
	player.reset()
	player.feedback.connect(on_feedback)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * native_zoom()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.limit_left = 0
	camera.limit_right = 4096
	camera.limit_top = -600
	camera.limit_bottom = 766
	camera.position = player.position + Vector2(0,-120)
	add_child(camera)
	camera.reset_smoothing()
	var hud := CanvasLayer.new()
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(16,16)
	hud.add_child(panel)
	var label := Label.new()
	label.text = "  FOREST CONCEPT • playable art preview\n  A/D Move   Space Jump ×2   Shift Dash   J Attack   R Reset   Tab Overview  "
	label.add_theme_font_size_override("font_size", 17)
	panel.add_child(label)
	if "--capture-preview" in OS.get_cmdline_user_args():
		await get_tree().create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://previews/forest-concept-game.png")

func bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)

func native_zoom() -> float:
	# One texture pixel per viewport pixel, instead of magnifying concept art.
	return ART.get_width() / 4096.0

func add_surface(points: Array[Vector2], one_way := false) -> void:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(point * ART_SCALE + ART_ORIGIN)
	polygon.append((points[-1] + Vector2(0,90)) * ART_SCALE + ART_ORIGIN)
	polygon.append((points[0] + Vector2(0,90)) * ART_SCALE + ART_ORIGIN)
	var body := StaticBody2D.new()
	var collision := CollisionPolygon2D.new()
	collision.polygon = polygon
	collision.one_way_collision = one_way
	body.add_child(collision)
	add_child(body)

func on_feedback(kind: String, at: Vector2) -> void:
	if kind not in ["heavy_step", "land"]:
		return
	for i in range(12 if kind == "land" else 5):
		dust.append({"position": at, "velocity": Vector2(randf_range(-24,24) - player.velocity.x * 0.08,randf_range(-26,-9)), "life": 0.45, "radius": randf_range(1.5,4.0)})

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("overview"):
		overview = not overview
		camera.zoom = Vector2.ONE * (get_viewport_rect().size.x / 4096.0 if overview else native_zoom())
	if Input.is_action_just_pressed("flourish"):
		player.combat.start()
	player.position.x = clampf(player.position.x, 20, 4070)
	camera.position = Vector2(2048,83) if overview else player.position + Vector2(0,-120)
	for i in range(dust.size()-1,-1,-1):
		dust[i].life -= delta
		dust[i].position += dust[i].velocity * delta
		if dust[i].life <= 0:
			dust.remove_at(i)
	queue_redraw()

func _draw() -> void:
	# Draw particles above the concept art and below the player's sprite.
	for mote in dust:
		var tint := Color("d9bf8e")
		tint.a = mote.life / 0.45 * 0.65
		draw_circle(mote.position, mote.radius * (1.5 - mote.life), tint)
