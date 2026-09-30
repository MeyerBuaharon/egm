extends Node2D

const BACKGROUND = preload("res://assets/levels/forest-kit/background.png")
const MANSION_GATE = preload("res://assets/levels/forest-kit/mansion-gate.png")
const OAK = preload("res://assets/levels/forest-kit/oak.png")
const Progress = preload("res://scripts/forest_progress.gd")
const Save = preload("res://scripts/forest_save.gd")
const Terrain = preload("res://scripts/forest_terrain.gd")
const MAPS := [
	{"name":"Forest Edge", "blocks":[Rect2(0,700,1280,120),Rect2(340,555,320,80),Rect2(760,425,300,80)], "tint":Color(0.72,0.81,0.78)},
	{"name":"Deep Grove", "blocks":[Rect2(0,700,1280,120),Rect2(240,570,270,80),Rect2(620,455,270,80),Rect2(1010,550,230,80)], "tint":Color(0.43,0.55,0.72)},
	{"name":"Mansion Gate", "blocks":[Rect2(0,700,1280,120),Rect2(280,560,250,80),Rect2(610,445,240,80)], "tint":Color(0.39,0.37,0.52)}
]
var progress := Progress.new()
var passive_tree: Control
var boss: Node2D
var notice := ""
var notice_time := 0.0
var saving_enabled := false
var loading_save := true
var map_props: Array[Node2D]=[]
var map_index := 0
var terrain_nodes: Array[Node2D] = []
var portals: Array[Node2D] = []
var heading: Label
var minimap: Control
var fade: ColorRect
var transitioning := false
var character_creation: Control
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
	for entry in [["left",[KEY_A,KEY_LEFT]],["right",[KEY_D,KEY_RIGHT]],["jump",[KEY_SPACE,KEY_W]],["portal",[KEY_UP,KEY_E]],["dash",[KEY_SHIFT]],["reset",[KEY_R]],["flourish",[KEY_J]],["layers",[KEY_F8]],["dig",[KEY_S,KEY_DOWN]]]:
		bind(entry[0],entry[1])
	bind("warden_class",[KEY_F1])
	bind("mage_class",[KEY_F2])
	bind("strider_class",[KEY_F3])
	bind("wildborn_class",[KEY_F4])
	for i in 4:
		bind("ability_%d" % i,[KEY_1+i])
	bind("cycle_element",[KEY_Q])
	bind("pickup",[KEY_F])
	bind("equipment",[KEY_I])
	bind("passive_tree",[KEY_P])
	bind("character_creation",[KEY_C])
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
	controls.text = "A/D Move   Space Jump   J Attack   Shift Dash   S Dig   Q Style   ↑ Portal   F Loot   I Bag   P Passives   F1–F4 Class"
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
	character_creation = preload("res://scripts/character_creation.gd").new()
	character_creation.world = self
	hud.add_child(character_creation)
	passive_tree=preload("res://scripts/passive_tree.gd").new()
	passive_tree.world=self
	hud.add_child(passive_tree)
	var campaign_hud := preload("res://scripts/campaign_hud.gd").new()
	campaign_hud.world=self
	hud.add_child(campaign_hud)
	# Tree overlays the world HUD while open.
	hud.move_child(passive_tree,hud.get_child_count()-1)
	fade = ColorRect.new()
	fade.color = Color(0.015,0.025,0.04,0)
	fade.size = Vector2(1280,800)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(fade)
	load_map(0)
	saving_enabled=not "--script" in OS.get_cmdline_args() and not "-s" in OS.get_cmdline_args() and not "--fresh" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	if saving_enabled:
		var saved := Save.load_data()
		if not saved.is_empty(): Save.apply(self,saved)
		elif FileAccess.file_exists(Save.SAVE_PATH):
			saving_enabled=false
			notify_player("Save could not be read. This session will not overwrite it.")
	loading_save=false
	player.equipment.changed.connect(save_progress)
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
		mob.defeated.connect(award_mob_xp.bind(mob))
		add_child(mob)
		combat_targets.append(mob)

func award_mob_xp(mob: Node2D = null) -> void:
	award_experience(25)
	if progress.has("siphon"): player.health=mini(100,player.health+8)
	if is_instance_valid(mob):
		add_map_item("ember",mob.position+Vector2(-12,18),"",6)
		if mob.hit_count%3==0: add_map_item("potion",mob.position+Vector2(16,18))
	save_progress()

func award_experience(amount: int) -> void:
	experience+=amount
	while experience>=experience_needed:
		experience-=experience_needed
		character_level+=1
		experience_needed+=50
		progress.points+=1
		notify_player("Level %d · +1 passive point" % character_level)

func notify_player(message: String) -> void:
	notice=message
	notice_time=4.5

func save_progress() -> void:
	if not saving_enabled or loading_save: return
	var error := Save.write(Save.capture(self))
	if error!=OK:
		push_warning("Progress save failed: %s" % error_string(error))
		notify_player("Could not save progress. Your current session is still active.")

func modify_damage(amount: int, target_health: int, target_max: int) -> int:
	return progress.damage(amount,target_health,target_max)

func add_map_item(kind: String, at: Vector2, id: String = "", amount: int = 6) -> Node2D:
	var item := preload("res://scripts/map_item.gd").new()
	item.world=self
	item.kind=kind
	item.item_id=id
	item.amount=amount
	item.position=at
	add_child(item)
	pickups.append(item)
	return item

func spawn_map_content() -> void:
	if map_index>0:
		var gate := Sprite2D.new()
		gate.texture=MANSION_GATE
		gate.centered=false
		var scale_factor := 0.42 if map_index==2 else 0.25
		gate.scale=Vector2.ONE*scale_factor
		gate.position=Vector2(950-768*scale_factor,700-943*scale_factor)
		gate.modulate=Color.WHITE if map_index==2 else Color(0.65,0.7,0.8,0.65)
		gate.z_index=-4
		add_child(gate)
		map_props.append(gate)
	if map_index==0:
		add_map_item("cache",Vector2(280,700),"edge_cache",18)
		add_map_item("memory",Vector2(560,555),"edge_memory")
		add_map_item("shrine",Vector2(95,700))
	elif map_index==1:
		add_map_item("cache",Vector2(1060,550),"grove_cache",26)
		add_map_item("memory",Vector2(745,455),"grove_memory")
		add_map_item("potion",Vector2(400,570),"grove_tonic")
		add_map_item("shrine",Vector2(1140,700))
	else:
		add_map_item("memory",Vector2(720,445),"gate_memory")
		add_map_item("shrine",Vector2(170,700))
		if not progress.boss_defeated:
			boss=preload("res://scripts/hollow_regent.gd").new()
			boss.world=self
			boss.spawn=Vector2(980,682)
			boss.defeated.connect(on_boss_defeated)
			add_child(boss)
			combat_targets.append(boss)
		elif not "mansion_seal" in progress.collected:
			add_map_item("seal",Vector2(1010,700),"mansion_seal")

func on_boss_defeated() -> void:
	if progress.boss_defeated: return
	progress.boss_defeated=true
	clear_boss_adds()
	award_experience(180)
	add_map_item("seal",Vector2(1010,700),"mansion_seal")
	notify_player("The Hollow Regent falls. Claim the seal at the gate.")
	save_progress()

func clear_boss_adds() -> void:
	for mob in combat_targets.duplicate():
		if mob!=boss:
			combat_targets.erase(mob)
			remove_child(mob)
			mob.queue_free()

func on_player_defeated() -> void:
	if is_instance_valid(boss) and not progress.boss_defeated:
		boss.reset()
		clear_boss_adds()
	for hazard in get_tree().get_nodes_in_group("boss_hazards"):
		hazard.set_physics_process(false)
		hazard.queue_free()
	notify_player("Returned to the wayshrine. Your loot and passives are safe.")

func add_portal(destination: int, x: float) -> void:
	var portal := preload("res://scripts/forest_portal.gd").new()
	portal.position=Vector2(x,700)
	portal.destination=destination
	portal.destination_name=MAPS[destination].name
	add_child(portal)
	portals.append(portal)

func select_class(index: int) -> void:
	if index<0 or index>=4: return
	if player.combat.active or player.burrowed or transitioning:
		return
	var old: Node = player.combat
	old.cancel()
	player.remove_child(old)
	old.queue_free()
	if index in [1,3]:
		player.combat = preload("res://scripts/skirmisher_combat.gd").new()
		player.combat.wildborn = index==3
	else:
		player.combat = preload("res://scripts/mage_combat.gd").new() if index==2 else preload("res://scripts/warden_combat.gd").new()
	player.combat.actor = player
	player.add_child(player.combat)
	player.appearance.class_index = index
	player.appearance.weapon_index = 2 if index == 2 else 0
	player.appearance.swing = 0
	player.appearance.phase = 0
	if is_instance_valid(action_hud):
		action_hud.update_tooltips()
	save_progress()

func load_map(index: int) -> void:
	for transient in get_tree().get_nodes_in_group("map_combat_transients"):
		if transient.get_parent()==self:
			remove_child(transient)
			transient.queue_free()
	for node in terrain_nodes + combat_targets + portals + pickups + map_props:
		remove_child(node)
		node.queue_free()
	map_props.clear()
	boss=null
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
	if index<2: spawn_mobs()
	if index==0: spawn_equipment()
	spawn_map_content()
	if index>0: add_portal(index-1,70)
	if index<MAPS.size()-1: add_portal(index+1,1210)
	player.reset()
	player.position.x = 130 if index == 0 else 165

func spawn_equipment() -> void:
	for class_id in 4:
		for slot in player.equipment.SLOTS.size():
			if player.equipment.owned[class_id][slot]: continue
			var item := preload("res://scripts/equipment_pickup.gd").new()
			item.world = self
			item.class_id = class_id
			item.slot = slot
			item.position = Vector2(185+slot*62,700)
			item.icon = player.equipment.item_icon(slot)
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
	var previous_map := map_index
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
	if index < previous_map:
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
	save_progress()

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
	notice_time=maxf(0,notice_time-delta)
	player.appearance.modulate = Color(1.0,0.55,0.5) if player.hurt_time > 0.3 else Color.WHITE
	for portal in portals:
		portal.nearby = can_enter(portal)
	if transitioning:
		return
	if Input.is_action_just_pressed("warden_class"):
		select_class(0)
	if Input.is_action_just_pressed("mage_class"):
		select_class(2)
	if Input.is_action_just_pressed("strider_class"): select_class(1)
	if Input.is_action_just_pressed("wildborn_class"): select_class(3)
	if Input.is_action_just_pressed("cycle_element") and not player.combat.active:
		if player.appearance.class_index==2:
			player.combat.select_element((player.combat.element+1)%4)
		elif player.appearance.class_index in [1,3]:
			player.combat.select_style((player.combat.style+1)%4)
		else:
			var next_style: int = (player.combat.selected+1)%4
			player.combat.cancel()
			player.combat.selected = next_style
			player.combat.weapon = player.combat.selected
			player.appearance.weapon_index = player.combat.selected
	if character_creation.visible and character_creation.name_input.has_focus():
		return
	if Input.is_action_just_pressed("character_creation"):
		if character_creation.visible: character_creation.hide()
		else:
			equipment_panel.hide()
			character_creation.open()
		return
	if Input.is_action_just_pressed("passive_tree"):
		character_creation.hide()
		equipment_panel.hide()
		passive_tree.open()
		return
	if Input.is_action_just_pressed("equipment"):
		character_creation.hide()
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
	for i in 2:
		if Input.is_action_just_pressed("ability_%d" % i): player.use_gem(i)
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

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST: save_progress()
