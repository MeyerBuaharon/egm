extends Node2D

const Player = preload("res://scripts/player.gd")
var player: CharacterBody2D
# Rootworks stays first: it is the movement lab the regression suites load.
const LEVELS := [
	"res://levels/01-rootworks.json", "res://levels/02-cistern.json", "res://levels/03-emberworks.json",
	"res://levels/f1-forest-edge.json", "res://levels/f2-deep-grove.json",
	"res://levels/f3-thornwood.json", "res://levels/f4-blackroot.json"
]
const BIOMES := "res://levels/biomes.json"
var level_index := 0
var level := {}
var theme := {}
var targets: Array[Vector2] = []
var blocks: Array[Rect2] = []
var labels: Array = []
var terrain: Array[Node] = []
var combat_targets: Array[Node2D] = []
var particles: Array[Dictionary] = []
var hud: Label
var hint: Label
var wardrobe: Label
var camera: Camera2D
var background: TextureRect
var tuning: PanelContainer
var shake := 0.0
var clock := 0.0
var reduce_motion := false
var recent := "Find a rhythm. Every movement can become the next."

func _ready() -> void:
	bind("left", [KEY_A, KEY_LEFT])
	bind("right", [KEY_D, KEY_RIGHT])
	bind("jump", [KEY_SPACE, KEY_W, KEY_UP])
	bind("dash", [KEY_SHIFT])
	bind("dig", [KEY_S, KEY_DOWN])
	bind("reset", [KEY_R])
	bind("motion", [KEY_M])
	bind("kit", [KEY_E])
	bind("weapon", [KEY_Q])
	bind("flourish", [KEY_J])
	bind("slow_motion", [KEY_T])
	bind("tuning", [KEY_F2])
	for i in 4:
		bind("class_%d" % i, [KEY_1 + i])
	bind("level", [KEY_TAB])
	var background_layer := CanvasLayer.new()
	background_layer.layer = -1
	add_child(background_layer)
	background = TextureRect.new()
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_layer.add_child(background)
	load_level(3 if "--forest-preview" in OS.get_cmdline_user_args() else 0)
	player = Player.new()
	player.world = self
	add_child(player)
	player.reset()
	player.feedback.connect(on_feedback)
	spawn_dummies()
	camera = Camera2D.new()
	camera.zoom = Vector2(1.5,1.5)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1280
	camera.limit_bottom = 800
	camera.position = player.position + Vector2(0,-90)
	add_child(camera)
	camera.reset_smoothing()
	var layer := CanvasLayer.new()
	add_child(layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.055,0.075,0.11,0.96)
	backdrop.size = Vector2(1280,111)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(backdrop)
	var footer := ColorRect.new()
	footer.color = backdrop.color
	footer.position = Vector2(0,754)
	footer.size = Vector2(1280,46)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(footer)
	var title := Label.new()
	title.text = "UNDERFOOT  /  Warden lab"
	title.position = Vector2(35, 20)
	title.add_theme_font_size_override("font_size", 25)
	layer.add_child(title)
	var controls := Label.new()
	controls.text = "A D Move · Space Jump ×2 · Shift Dash (ground/air) · Hold S Burrow · J Attack · Q Weapon · R Reset · M Motion"
	controls.position = Vector2(35, 61)
	controls.add_theme_font_size_override("font_size", 16)
	controls.modulate = Color("a6b7c8")
	layer.add_child(controls)
	hud = Label.new()
	hud.position = Vector2(880, 23)
	hud.add_theme_font_size_override("font_size", 17)
	layer.add_child(hud)
	hint = Label.new()
	hint.position = Vector2(35, 761)
	hint.add_theme_font_size_override("font_size", 16)
	layer.add_child(hint)
	wardrobe = Label.new()
	wardrobe.position = Vector2(35, 86)
	wardrobe.add_theme_font_size_override("font_size", 15)
	wardrobe.modulate = Color("e8c48b")
	layer.add_child(wardrobe)
	build_tuning(layer)

func build_tuning(layer: CanvasLayer) -> void:
	tuning = PanelContainer.new()
	tuning.position = Vector2(850,125)
	tuning.custom_minimum_size = Vector2(390,260)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	tuning.add_child(content)
	var heading := Label.new()
	heading.text = "Warden movement · F2 to close"
	content.add_child(heading)
	add_tuning_slider(content,"Acceleration","warden_acceleration",400,2000,50)
	add_tuning_slider(content,"Run speed","warden_run_speed",100,260,10)
	add_tuning_slider(content,"Run frames / second","warden_run_fps",5,12,0.5)
	add_tuning_slider(content,"Running attack threshold","running_threshold",40,180,10,player.combat)
	var note := Label.new()
	note.text = "Changes apply immediately. Session only."
	content.add_child(note)
	tuning.visible = false
	layer.add_child(tuning)

func add_tuning_slider(parent: VBoxContainer,title: String,property: String,low: float,high: float,step: float,target: Node = null) -> void:
	if target == null: target = player
	var label := Label.new()
	label.text = "%s: %.1f" % [title,target.get(property)]
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = target.get(property)
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(value: float) -> void:
		target.set(property,value)
		label.text = "%s: %.1f" % [title,value])
	parent.add_child(slider)

func bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)

func on_feedback(kind: String, at: Vector2) -> void:
	var color := Color("75edca")
	var count := 8
	match kind:
		"hammer_slam":
			count = 28
			shake = 5
			color = Color("d6ab7c")
			recent = "Slam → knockdown → buried for 2 seconds on the main floor."
		"regular_hit":
			count = 5
			recent = "Regular combo · press J again to chain · no status effects"
		"combat_hit":
			count = 10
			shake = 2
			recent = "Sword: stun · Axe/Spear: knock-up · Hammer: knockdown + bury"
		"heavy_step":
			count = 3
			color = Color("98816a")
		"burrow_impact":
			count = 20
			color = Color("ba9473")
			shake = 2
			recent = "Gauntlet impact → tunnel → release to burst upward."
		"bounce":
			recent = "Bounce ×%d — air jump restored" % player.combo
			color = Color("ffc17a")
			count = 18
			shake = 3
		"emerge":
			recent = "Emerge → air jump → wall jump → bounce. Keep it going."
			count = 24
			shake = 3
		"dig":
			recent = "Underground — move with A / D. Release S to launch."
			color = Color("ba9473")
		"wall": recent = "Wall jump — steer away, or return to climb."
		"dash": recent = "Dash · invulnerable during the burst · works in midair"
		"hurt":
			color = Color("ee6d69")
			recent = "Hit · use Shift to dash through contact damage"
		"air_impact":
			count = 22
			shake = 4
			recent = "Air finisher impact"
		"sword_shockwave":
			count = 20
			shake = 4
			recent = "Sheathe → delayed path damage + stun"
		"air": recent = "Air jump spent. Land, wall jump, or bounce to restore it."
		"land": count = 7
	for i in range(count):
		particles.append({"p": at, "v": Vector2(randf_range(-150, 150), randf_range(-160, -35)), "life": 0.45, "color": color})

func _process(dt: float) -> void:
	clock += dt
	if Input.is_action_just_pressed("reset"):
		for target in combat_targets: target.reset()
	if Input.is_action_just_pressed("level"):
		load_level((level_index + 1) % LEVELS.size())
		spawn_dummies()
		player.reset()
	if Input.is_action_just_pressed("tuning"):
		tuning.visible = not tuning.visible
	if Input.is_action_just_pressed("slow_motion"):
		Engine.time_scale = 0.35 if Engine.time_scale > 0.5 else 1.0
	for i in 4:
		if Input.is_action_just_pressed("class_%d" % i) and not player.combat.active:
			player.appearance.class_index = i
	if Input.is_action_just_pressed("kit"):
		player.appearance.heavy = not player.appearance.heavy
	if Input.is_action_just_pressed("weapon"):
		if player.appearance.class_index == 0:
			if not player.combat.active: player.combat.selected = (player.combat.selected+1)%4
		else:
			player.appearance.weapon_index = (player.appearance.weapon_index + 1) % 4
	if Input.is_action_just_pressed("flourish"):
		if player.appearance.class_index == 0:
			player.appearance.get_child(0).start_slash()
		else:
			player.appearance.swing = 0.28
	var look: Node2D = player.appearance
	wardrobe.text = "1–4  Class: %s     E  Outfit: %s     Q  Weapon: %s     J  Flourish    T  Slow motion" % [look.NAMES[look.class_index], "Heavy" if look.heavy else "Light", look.WEAPONS[look.weapon_index]]
	if look.class_index == 0:
		wardrobe.text = "Warden · Q Weapon: %s     J Attack / burrow attack     T Slow motion     F2 Tune     R Reset targets" % player.combat.NAMES[player.combat.selected]
	if Input.is_action_just_pressed("motion"):
		reduce_motion = not reduce_motion
		recent = "Reduced motion enabled" if reduce_motion else "Motion effects enabled"
	shake = move_toward(shake, 0, dt * 18)
	# Visual-only displacement: collision and input remain untouched.
	camera.position = player.position + Vector2(clampf(player.velocity.x * 0.13,-55,55), -90)
	camera.offset = Vector2(sin(clock * 55), cos(clock * 71)) * shake if not reduce_motion else Vector2.ZERO
	update_background()
	for i in range(particles.size() - 1, -1, -1):
		particles[i].life -= dt
		particles[i].p += particles[i].v * dt
		particles[i].v.y += dt * 400
		if particles[i].life <= 0:
			particles.remove_at(i)
	hud.text = "%s | HP %d" % [player.state,player.health]
	hint.text = recent
	queue_redraw()

func _draw() -> void:
	var grid: Color = theme["grid"]
	if not level.has("background_texture"):
		for x in range(30, 1250, 40):
			draw_line(Vector2(x, 125), Vector2(x, 700), grid)
		for y in range(140, 700, 40):
			draw_line(Vector2(30, y), Vector2(1250, y), grid)
	var fill: Color = theme["block"]
	var edge: Color = theme["edge"]
	for rect in blocks:
		draw_rect(rect, fill)
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), edge, 2)
	draw_rect(Rect2(30, 703, 1220, 49), theme["floor"])
	var detail: Color = theme["floor_detail"]
	for x in range(40, 1240, 19):
		draw_line(Vector2(x, 719), Vector2(x + 9, 728), detail, 2)
	var font := ThemeDB.fallback_font
	for entry in labels:
		var at: Array = entry["at"]
		draw_string(font, Vector2(at[0], at[1]), entry["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(entry["color"]) if entry.has("color") else theme["label"])
	for target in targets:
		draw_circle(target, 19, Color("594735"))
		draw_arc(target, 20, PI, TAU, 20, Color("ffc17a"), 3)
		draw_circle(target + Vector2(-6, -3), 2, Color("ffc17a"))
		draw_circle(target + Vector2(6, -3), 2, Color("ffc17a"))
		draw_line(target + Vector2(0, 22), target + Vector2(0, 30), Color("77604b"), 2)
	for p in particles:
		var tint: Color = p.color
		tint.a = p.life / 0.45
		draw_rect(Rect2(p.p, Vector2(3, 3)), tint)


func load_level(index: int) -> void:
	level_index = index
	var text := FileAccess.get_file_as_string(LEVELS[index])
	level = JSON.parse_string(text)
	assert(level != null, "Unreadable level: %s" % LEVELS[index])
	theme = resolve_theme()
	if background != null:
		background.texture = load(level["background_texture"]) if level.has("background_texture") else null
		background.visible = background.texture != null
	labels = level.get("labels", [])
	RenderingServer.set_default_clear_color(theme["background"])
	blocks.clear()
	for b in level["blocks"]:
		blocks.append(Rect2(b[0], b[1], b[2], b[3]))
	targets.clear()
	for t in level.get("targets", []):
		targets.append(Vector2(t[0], t[1]))
	for node in terrain:
		node.queue_free()
	terrain.clear()
	for rect in blocks:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		body.position = rect.get_center()
		body.add_child(shape)
		add_child(body)
		terrain.append(body)
	recent = "%s — TAB for the next map" % level.get("name", "Level")

func update_background() -> void:
	if background == null or background.texture == null:
		return
	# Frame the lower canopy rather than the distant skyline. Background travel
	# is a small fraction of camera travel, independent of the panorama width.
	var viewport_size := get_viewport_rect().size
	var image_size := background.texture.get_size()
	var scale_factor := maxf(viewport_size.x / image_size.x, viewport_size.y / image_size.y) * float(level.get("background_scale", 1.0))
	background.size = image_size * scale_factor
	var half_view := viewport_size.x / camera.zoom.x * 0.5
	var camera_travel := maxf(camera.get_screen_center_position().x - camera.limit_left - half_view, 0.0)
	var offset_x := camera_travel * camera.zoom.x * float(level.get("background_scroll", 0.04))
	background.position = Vector2(-clampf(offset_x, 0.0, background.size.x - viewport_size.x), viewport_size.y - background.size.y)

func spawn_dummies() -> void:
	for node in combat_targets:
		node.queue_free()
	combat_targets.clear()
	for at in level.get("dummies", []):
		var target := preload("res://scripts/combat_dummy.gd").new()
		target.world = self
		target.spawn = Vector2(at[0], at[1])
		add_child(target)
		target.reset()
		combat_targets.append(target)

	var air_target := preload("res://scripts/combat_dummy.gd").new()
	air_target.world = self
	air_target.spawn = player.position+Vector2(180,-100)
	air_target.hovering = true
	add_child(air_target)
	air_target.reset()
	combat_targets.append(air_target)

# A level either states its own theme, or names a biome and how far along its
# corruption ramp it sits. Only the biome endpoints need authored art.
func resolve_theme() -> Dictionary:
	var out := {}
	if level.has("theme"):
		for key in level["theme"]: out[key] = Color(level["theme"][key])
		return out
	var biomes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BIOMES))
	var biome: Dictionary = biomes[level["biome"]]
	var t := clampf(float(level.get("corruption", 0.0)), 0.0, 1.0)
	for key in biome["early"]:
		out[key] = Color(biome["early"][key]).lerp(Color(biome["late"][key]), t)
	return out
