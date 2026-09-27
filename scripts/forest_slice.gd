extends Node2D

const BACKGROUND = preload("res://assets/levels/forest-kit/background.png")
const OAK = preload("res://assets/levels/forest-kit/oak.png")
const Terrain = preload("res://scripts/forest_terrain.gd")
const MAPS := [
	{"name":"Forest Edge", "blocks":[Rect2(0,700,1280,120),Rect2(340,555,320,80),Rect2(760,425,300,80)], "tint":Color(0.72,0.81,0.78)},
	{"name":"Deep Grove", "blocks":[Rect2(0,700,1280,120),Rect2(240,570,270,80),Rect2(620,455,270,80),Rect2(1010,550,230,80)], "tint":Color(0.43,0.55,0.72)}
]
var map_index := 0
var terrain_nodes: Array[Node2D] = []
var portals: Array[Node2D] = []
var heading: Label
var minimap: Control
var fade: ColorRect
var transitioning := false
var equipment_panel: Control
var pickups: Array[Node2D] = []
var action_hud: Control
var experience := 0
var character_level := 1
var experience_needed := 100
var blocks: Array[Rect2] = [Rect2(0,700,1280,120),Rect2(340,555,320,80),Rect2(760,425,300,80)]
var targets: Array[Vector2] = []
var combat_targets: Array[Node2D] = []
var player: CharacterBody2D
var dust: Array[Dictionary] = []
var camera: Camera2D
var backdrop: Sprite2D
var elapsed := 0.0
var inspect_layers := false
var scenery: Array[Node2D] = []

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("142623"))
	for entry in [["left",[KEY_A,KEY_LEFT]],["right",[KEY_D,KEY_RIGHT]],["jump",[KEY_SPACE,KEY_W]],["portal",[KEY_UP,KEY_E]],["dash",[KEY_SHIFT]],["reset",[KEY_R]],["flourish",[KEY_J]],["layers",[KEY_F3]],["dig",[KEY_S,KEY_DOWN]]]:
		bind(entry[0],entry[1])
	bind("warden_class",[KEY_F1])
	bind("mage_class",[KEY_F2])
	for i in 4:
		bind("ability_%d" % i,[KEY_1+i])
	bind("cycle_element",[KEY_Q])
	bind("pickup",[KEY_F])
	bind("equipment",[KEY_I])
	backdrop = Sprite2D.new()
	backdrop.texture = BACKGROUND
	backdrop.centered = false
	backdrop.scale = Vector2.ONE * 0.83
	backdrop.position = Vector2(-18,-20)
	backdrop.z_index = -20
	backdrop.modulate = Color(0.72,0.81,0.78)
	add_child(backdrop)
	# Each oak is an independent transparent sprite behind the solid terrain.
	add_tree(Vector2(-225,-275),0.64,false,Color(0.66,0.72,0.61))
	add_tree(Vector2(1050,-345),0.70,true,Color(0.50,0.62,0.56))
	player = preload("res://scripts/player.gd").new()
	player.stamina_enabled = true
	player.modular_equipment = true
	player.world = self
	add_child(player)
	player.reset()
	player.feedback.connect(on_feedback)
	camera = Camera2D.new()
	camera.position = Vector2(640,400)
	add_child(camera)
	var hud := CanvasLayer.new()
	add_child(hud)
	heading = Label.new()
	heading.position = Vector2(34,25)
	heading.text = "FOREST EDGE"
	heading.add_theme_font_size_override("font_size",23)
	heading.add_theme_color_override("font_color",Color("ead9a8"))
	heading.add_theme_color_override("font_shadow_color",Color.BLACK)
	heading.add_theme_constant_override("shadow_offset_x",2)
	heading.add_theme_constant_override("shadow_offset_y",2)
	hud.add_child(heading)
	var controls := Label.new()
	controls.position = Vector2(35,59)
	controls.text = "A/D Move   ↑/E Portal   F1 Warden / F2 Mage   F Pickup   I Equipment   R Reset"
	controls.add_theme_font_size_override("font_size",14)
	controls.add_theme_color_override("font_color",Color("c3cfbd"))
	controls.add_theme_color_override("font_shadow_color",Color.BLACK)
	controls.add_theme_constant_override("shadow_offset_x",1)
	controls.add_theme_constant_override("shadow_offset_y",1)
	hud.add_child(controls)
	action_hud = preload("res://scripts/forest_action_hud.gd").new()
	action_hud.world = self
	action_hud.position = Vector2(310,702)
	hud.add_child(action_hud)
	minimap = preload("res://scripts/forest_minimap.gd").new()
	minimap.world = self
	minimap.position = Vector2(996,20)
	hud.add_child(minimap)
	equipment_panel = preload("res://scripts/equipment_panel.gd").new()
	equipment_panel.world = self
	hud.add_child(equipment_panel)
	fade = ColorRect.new()
	fade.color = Color(0.015,0.025,0.04,0)
	fade.size = Vector2(1280,800)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(fade)
	load_map(0)
	if "--mage" in OS.get_cmdline_user_args():
		select_class(2)
	if "--capture-slice" in OS.get_cmdline_user_args():
		await get_tree().create_timer(1).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://previews/forest-slice.png")

func bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action,event)

func spawn_mobs() -> void:
	var setups := [[Vector2(590,682),Vector2(460,735),1.0],[Vector2(1080,682),Vector2(960,1140),-1.0]]
	for rect in blocks.slice(1):
		setups.append([Vector2(rect.get_center().x,rect.position.y-18),Vector2(rect.position.x+27,rect.end.x-27),-1.0])
	for setup in setups:
		var mob := preload("res://scripts/forest_mob.gd").new()
		mob.world = self
		mob.spawn = setup[0]
		mob.patrol = setup[1]
		mob.direction = setup[2]
		mob.defeated.connect(award_mob_xp)
		add_child(mob)
		combat_targets.append(mob)

func award_mob_xp() -> void:
	experience += 25
	while experience >= experience_needed:
		experience -= experience_needed
		character_level += 1
		experience_needed += 50

func select_class(index: int) -> void:
	if player.combat.active or player.burrowed or transitioning:
		return
	var old: Node = player.combat
	old.cancel()
	player.remove_child(old)
	old.queue_free()
	player.combat = preload("res://scripts/mage_combat.gd").new() if index==2 else preload("res://scripts/warden_combat.gd").new()
	player.combat.actor = player
	player.add_child(player.combat)
	player.appearance.class_index = index
	player.appearance.weapon_index = 2 if index == 2 else 0
	player.appearance.swing = 0
	player.appearance.phase = 0
	if is_instance_valid(action_hud):
		action_hud.update_tooltips()

func load_map(index: int) -> void:
	for node in terrain_nodes + combat_targets + portals + pickups:
		remove_child(node)
		node.queue_free()
	terrain_nodes.clear()
	combat_targets.clear()
	portals.clear()
	pickups.clear()
	dust.clear()
	map_index = index
	blocks.assign(MAPS[index].blocks)
	backdrop.modulate = MAPS[index].tint
	heading.text = MAPS[index].name.to_upper()
	for rect in blocks:
		var terrain := Terrain.new()
		terrain.position = rect.position
		terrain.width = rect.size.x
		terrain.one_way = rect.position.y < 700
		terrain.modulate = Color.WHITE if index == 0 else Color(0.73,0.82,0.94)
		add_child(terrain)
		terrain_nodes.append(terrain)
	spawn_mobs()
	if index==0:
		spawn_equipment()
	var portal := preload("res://scripts/forest_portal.gd").new()
	portal.position = Vector2(1210 if index == 0 else 70,700)
	portal.destination = 1-index
	portal.destination_name = MAPS[portal.destination].name
	add_child(portal)
	portals.append(portal)
	player.reset()
	player.position.x = 130 if index == 0 else 165

func spawn_equipment() -> void:
	for class_id in [0,2]:
		for slot in 4:
			if player.equipment.owned[class_id][slot]: continue
			var item := preload("res://scripts/equipment_pickup.gd").new()
			item.world = self
			item.class_id = class_id
			item.slot = slot
			item.position = Vector2(185+slot*62,700)
			item.icon = preload("res://scripts/modular_character.gd").item_icon(class_id,slot)
			add_child(item)
			pickups.append(item)

func nearest_pickup() -> Node2D:
	var closest: Node2D
	var distance := INF
	for item in pickups:
		if item.can_collect() and item.position.distance_squared_to(player.position)<distance:
			closest = item
			distance = item.position.distance_squared_to(player.position)
	return closest

func pickup_nearest() -> bool:
	var closest := nearest_pickup()
	return closest.collect() if is_instance_valid(closest) else false

func can_enter(portal: Node2D) -> bool:
	return not transitioning and not player.burrowed and not player.combat.active and player.is_on_floor() and absf(player.position.x-portal.position.x)<45 and absf(player.position.y+19-portal.position.y)<10

func try_portal() -> void:
	for portal in portals:
		if can_enter(portal):
			change_map(portal.destination)
			return

func change_map(index: int) -> void:
	if transitioning or index < 0 or index >= MAPS.size():
		return
	transitioning = true
	player.set_physics_process(false)
	for mob in combat_targets:
		mob.set_physics_process(false)
	var health: int = player.health
	var stamina: float = player.stamina
	var mana: float = player.mana
	var burrow_cooldown: float = player.burrow_cooldown
	var regen_wait: float = player.stamina_regen_wait
	var tween := create_tween()
	tween.tween_property(fade,"color:a",1.0,0.18)
	await tween.finished
	load_map(index)
	player.health = health
	player.stamina = stamina
	player.mana = mana
	player.burrow_cooldown = burrow_cooldown
	player.stamina_regen_wait = regen_wait
	# Arrival stays away from the return portal, so a held key cannot bounce back.
	if index == 0:
		player.position.x = 1135
	for mob in combat_targets:
		mob.set_physics_process(false)
	tween = create_tween()
	tween.tween_property(fade,"color:a",0.0,0.18)
	await tween.finished
	player.set_physics_process(true)
	for mob in combat_targets:
		mob.set_physics_process(true)
	transitioning = false

func add_tree(at: Vector2, size: float, flipped: bool, tint: Color) -> void:
	var tree := Sprite2D.new()
	tree.texture = OAK
	tree.centered = false
	tree.position = at
	tree.scale = Vector2.ONE * size
	tree.flip_h = flipped
	tree.modulate = tint
	tree.z_index = -5
	add_child(tree)
	scenery.append(tree)

func on_feedback(kind: String, at: Vector2) -> void:
	if player.appearance.class_index == 2 and kind in ["heavy_step","land"]:
		return
	if kind not in ["heavy_step","land"]:
		return
	for i in range(14 if kind == "land" else 6):
		dust.append({"p":at,"v":Vector2(randf_range(-25,25)-player.velocity.x*0.1,randf_range(-32,-12)),"life":0.5,"radius":randf_range(1.0,3.2)})

func _process(delta: float) -> void:
	elapsed += delta
	player.appearance.modulate = Color(1.0,0.55,0.5) if player.hurt_time > 0.3 else Color.WHITE
	for portal in portals:
		portal.nearby = can_enter(portal)
	if transitioning:
		return
	if Input.is_action_just_pressed("warden_class"):
		select_class(0)
	if Input.is_action_just_pressed("mage_class"):
		select_class(2)
	if player.appearance.class_index==2:
		if Input.is_action_just_pressed("cycle_element"):
			player.combat.select_element((player.combat.element+1)%4)
	if Input.is_action_just_pressed("equipment"):
		equipment_panel.visible = not equipment_panel.visible
	if Input.is_action_just_pressed("pickup"):
		pickup_nearest()
	if Input.is_action_just_pressed("portal"):
		try_portal()
	if Input.is_action_just_pressed("reset"):
		for mob in combat_targets:
			mob.reset()
	if Input.is_action_just_pressed("flourish"):
		player.combat.start()
	if Input.is_action_just_pressed("layers"):
		inspect_layers = not inspect_layers
		backdrop.visible = not inspect_layers
		for tree in scenery:
			tree.visible = not inspect_layers
	player.position.x = clampf(player.position.x,24,1256)
	# A single composed screen, with only a few pixels of distant-layer drift.
	backdrop.position.x = -18 - (player.position.x - 130) * 0.008
	for i in range(dust.size()-1,-1,-1):
		dust[i].life -= delta
		dust[i].p += dust[i].v * delta
		dust[i].v.y += delta * 28
		if dust[i].life <= 0:
			dust.remove_at(i)
	queue_redraw()

func _draw() -> void:
	# Sparse ambient motes and reactive footstep dust are independent of artwork.
	if not inspect_layers:
		for i in 18:
			var x := fposmod(i*137.0 + sin(elapsed*0.15+i)*18,1280)
			var y := 170 + fposmod(i*71.0-elapsed*3,480)
			draw_circle(Vector2(x,y),1.1,Color(0.9,0.8,0.48,0.12+0.1*sin(elapsed+i)))
	for mote in dust:
		var tint := Color("d9bb81")
		tint.a = mote.life * 1.3
		draw_circle(mote.p,mote.radius*(1.4-mote.life),tint)
