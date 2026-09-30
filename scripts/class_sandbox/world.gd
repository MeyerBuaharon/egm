extends Node2D
const Catalog = preload("res://scripts/class_sandbox/catalog.gd")
@export var training_mode := true
var item_library: Control
var blocks: Array[Rect2]=[Rect2(0,700,1280,120),Rect2(490,520,300,80)]
var targets: Array[Vector2]=[]
var combat_targets: Array[Node2D]=[]
var player: CharacterBody2D
var selected_job := 0
var selected_slot := 0
var locked_job := 0
var locked_slot := 0
var in_run := false
var unlocked: Array[String]=["sword","daggers","fire","claws"]
var mastery := 0
var power := 0
var kills := 0
var effects: Array[Dictionary]=[]
var panel: PanelContainer
var item_buttons: Array[Button]=[]
var job_buttons: Array[Button]=[]
var details: Label
var status: Label
var resources: Label
var start_button: Button
var unlock_button: Button
var female_visual: Node2D
var item_visual: Node2D
var equipment_panel: Control
var elapsed := 0.0
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("101c23"))
	for entry in [["left",[KEY_A,KEY_LEFT]],["right",[KEY_D,KEY_RIGHT]],["jump",[KEY_SPACE,KEY_W]],["dash",[KEY_SHIFT]],["dig",[KEY_S,KEY_DOWN]],["reset",[KEY_R]],["flourish",[KEY_J]]]: bind(entry[0],entry[1])
	for i in 4: bind("ability_%d" % i,[KEY_1+i])
	var bg := Sprite2D.new()
	bg.texture=preload("res://assets/levels/forest-kit/background.png")
	bg.centered=false
	bg.scale=Vector2.ONE*0.83
	bg.modulate=Color(0.4,0.47,0.51)
	bg.z_index=-10
	add_child(bg)
	for rect in blocks:
		var floor_piece := preload("res://scripts/forest_terrain.gd").new()
		floor_piece.position=rect.position
		floor_piece.width=rect.size.x
		floor_piece.one_way=rect.position.y<700
		add_child(floor_piece)
	player=preload("res://scripts/class_sandbox/training_player.gd").new() if training_mode else preload("res://scripts/player.gd").new()
	player.world=self
	player.stamina_enabled=true
	player.modular_equipment=true
	add_child(player)
	player.reset()
	female_visual=preload("res://scripts/class_sandbox/visual.gd").new()
	female_visual.actor=player
	add_child(female_visual)
	item_visual=preload("res://scripts/class_sandbox/item_visual.gd").new()
	item_visual.world=self
	add_child(item_visual)
	build_ui()
	if training_mode:
		for row in Catalog.ITEMS:
			for item in row:
				if not item.id in unlocked: unlocked.append(item.id)
		mastery=999999
		start_selected()
	else: show_choices()
func bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode=key
		if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)
func box(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left=18
	style.content_margin_right=18
	style.content_margin_top=14
	style.content_margin_bottom=14
	return style
func label(text: String, size: int=16) -> Label:
	var node := Label.new()
	node.text=text
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",Color("e4ddc9"))
	return node
func button(text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text=text
	node.add_theme_stylebox_override("normal",box(Color("162a32"),Color("53656c")))
	node.add_theme_stylebox_override("hover",box(Color("243d42"),Color("d7b66d")))
	node.add_theme_stylebox_override("focus",box(Color(0,0,0,0),Color("ecd095")))
	node.pressed.connect(action)
	return node
func build_ui() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var title := label("TRAINING ROOM   /   EVERYTHING UNLOCKED" if training_mode else "CLASS SANDBOX   /   STARTING RELICS",25)
	title.position=Vector2(32,22)
	hud.add_child(title)
	var subtitle := label("F1 Warden · F2 Hexbinder · F3 Strider · F4 Wildborn    |    F5–F8 choose weapon    |    K all items" if training_mode else "Choose once. Your combat item and silhouette stay with you for the run.",15)
	subtitle.position=Vector2(33,57)
	hud.add_child(subtitle)
	status=label("",16)
	status.position=Vector2(33,89)
	hud.add_child(status)
	resources=label("",16)
	resources.position=Vector2(32,737)
	hud.add_child(resources)
	var controls := label("A/D move · Space jump · J combo · Shift dash · S dig · B new loadout · T targets · R reset · U power · I jewelry · 1/2 gems",13)
	if training_mode:
		controls.text="A/D move · Space jump · J combo · Shift dash · S dig · Q next item · F5–F8 item 1–4 · T reset dummy
I jewelry · K item list / use · 1 Nova · 2 Renewal · U power gem · B loadout menu"
	controls.position=Vector2(32,759 if training_mode else 769)
	hud.add_child(controls)
	equipment_panel=preload("res://scripts/equipment_panel.gd").new()
	equipment_panel.world=self
	hud.add_child(equipment_panel)
	equipment_panel.position=Vector2(260,160)
	equipment_panel.visibility_changed.connect(func():
		player.set_physics_process(in_run and not equipment_panel.visible)
		for enemy in combat_targets: enemy.set_physics_process(in_run and not equipment_panel.visible))
	for node in equipment_panel.get_child(0).get_children():
		if node is Label and node.text.begins_with("F collects"):
			node.text="Sandbox supply: equip any jewelry or gem from the bag. No appearance changes."
	item_library=preload("res://scripts/class_sandbox/item_library.gd").new()
	item_library.world=self
	hud.add_child(item_library)
	item_library.visibility_changed.connect(sync_actor_processing)
	equipment_panel.visibility_changed.connect(sync_actor_processing)
	panel=PanelContainer.new()
	panel.position=Vector2(80,138)
	panel.custom_minimum_size=Vector2(1120,530)
	panel.add_theme_stylebox_override("panel",box(Color("0e1c25"),Color("bba370")))
	hud.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",14)
	panel.add_child(layout)
	layout.add_child(label("01  CHOOSE YOUR JOB",19))
	var jobs := HBoxContainer.new()
	layout.add_child(jobs)
	for index in [0,2,1,3]:
		var tab := button(Catalog.JOBS[index]+"  /  "+Catalog.GENDERS[index],func(): selected_job=index; selected_slot=0; refresh_choices())
		tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		jobs.add_child(tab)
		job_buttons.append(tab)
	layout.add_child(label("02  CHOOSE AN UNLOCKED STARTING ITEM",19))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation",12)
	layout.add_child(cards)
	for slot in 4:
		var card := button("",func(): selected_slot=slot; refresh_choices())
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		card.custom_minimum_size=Vector2(254,144)
		card.expand_icon=true
		card.add_theme_constant_override("icon_max_width",62)
		cards.add_child(card)
		item_buttons.append(card)
	details=label("",16)
	details.custom_minimum_size=Vector2(0,98)
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(details)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",12)
	layout.add_child(footer)
	unlock_button=button("",unlock_selected)
	footer.add_child(unlock_button)
	var all_button := button("Unlock all · sandbox only",func():
		for row in Catalog.ITEMS:
			for entry in row:
				if not entry.id in unlocked: unlocked.append(entry.id)
		refresh_choices())
	footer.add_child(all_button)
	start_button=button("Begin test run →",start_selected)
	start_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer.add_child(start_button)
	layout.add_child(label("Unlocks are session-only in this sandbox. Defeat targets for mastery. No campaign save is read or written.",13))
func refresh_choices() -> void:
	for slot in 4:
		var entry := Catalog.item(selected_job,slot)
		item_buttons[slot].text=("✓ " if slot==selected_slot else "")+entry.name+"\n"+entry.type+"\n"+("Available" if entry.id in unlocked else "Locked · 2 mastery")
		item_buttons[slot].icon=preload("res://scripts/class_sandbox/item_visual.gd").icon(selected_job,slot)
		item_buttons[slot].modulate=Color.WHITE if slot==selected_slot else Color("b1bbc1")
	var entry := Catalog.item(selected_job,selected_slot)
	details.text=entry.role+"\nCombo: "+entry.combo+"\nDig: "+entry.dig+"\nBuild upgrades: rings, amulets and gems; they never replace your selected look."
	start_button.disabled=not entry.id in unlocked
	unlock_button.text="Unlocked" if entry.id in unlocked else "Unlock · 2 mastery (%d owned)" % mastery
	unlock_button.disabled=entry.id in unlocked or mastery<2
	for tab in job_buttons: tab.modulate=Color.WHITE if tab.text.begins_with(Catalog.JOBS[selected_job]) else Color("86949c")
func unlock_selected() -> void:
	var id: String=Catalog.item(selected_job,selected_slot).id
	if in_run or id in unlocked or mastery<2: return
	mastery-=2
	unlocked.append(id)
	refresh_choices()
func current_item() -> Dictionary: return Catalog.item(locked_job,locked_slot)
func start_selected() -> void:
	if in_run or not Catalog.item(selected_job,selected_slot).id in unlocked: return
	locked_job=selected_job
	locked_slot=selected_slot
	var old: Node=player.combat
	old.cancel()
	player.remove_child(old)
	old.queue_free()
	if locked_job==0:
		player.combat=preload("res://scripts/warden_combat.gd").new()
		player.combat.selected=locked_slot
		player.combat.weapon=locked_slot
	elif locked_job==2:
		player.combat=preload("res://scripts/class_sandbox/grimoire_combat.gd").new()
		player.combat.element=locked_slot
	else:
		player.combat=preload("res://scripts/class_sandbox/combat.gd").new()
		player.combat.wildborn=locked_job==3
		player.combat.style=locked_slot
	player.combat.actor=player
	player.add_child(player.combat)
	player.appearance.class_index=locked_job
	player.appearance.weapon_index=locked_slot if locked_job==0 else 0
	player.reset()
	if training_mode: player.position.x=580
	player.appearance.visible=locked_job in [1,2]
	for slot in player.equipment.SLOTS.size():
		player.equipment.owned[locked_job][slot]=true
		player.equipment.worn[locked_job][slot]=training_mode
	player.equipment.changed.emit()
	power=0
	panel.hide()
	in_run=true
	player.set_physics_process(true)
	reset_targets()
	get_viewport().gui_release_focus()
func show_choices() -> void:
	in_run=false
	if is_instance_valid(equipment_panel): equipment_panel.hide()
	if is_instance_valid(item_library): item_library.hide()
	player.combat.cancel()
	player.set_physics_process(false)
	for enemy in combat_targets: enemy.set_physics_process(false)
	for effect in get_tree().get_nodes_in_group("sandbox_effects"): effect.queue_free()
	panel.show()
	refresh_choices()
func reset_targets() -> void:
	for enemy in combat_targets: enemy.queue_free()
	combat_targets.clear()
	for effect in get_tree().get_nodes_in_group("sandbox_effects"): effect.queue_free()
	for x in ([660] if training_mode else [630,850,1070]):
		var enemy = preload("res://scripts/class_sandbox/training_dummy.gd").new() if training_mode else preload("res://scripts/forest_mob.gd").new()
		enemy.world=self
		enemy.spawn=Vector2(x,682)
		enemy.patrol=Vector2(x-25,x+25)
		enemy.defeated.connect(func(): mastery+=1; kills+=1)
		add_child(enemy)
		combat_targets.append(enemy)
func modify_damage(amount: int, _health: int, _max_health: int) -> int: return roundi(amount*(1.0+power*0.15))
func on_player_defeated() -> void: reset_targets()
func item_color() -> Color:
	if locked_job==2: return [Color("ed855a"),Color("9cdaff"),Color("93e3ce"),Color("c5a17a")][locked_slot]
	return [Color("eabd70"),Color("d194e9"),Color("9cdaff"),Color("a8cf7d")][locked_job]
func flash_effect(at: Vector2, kind: String, radius: float, facing: float=1) -> void:
	effects.append({"at":at,"kind":kind,"radius":radius,"life":0.35,"facing":facing})
func _process(dt: float) -> void:
	elapsed+=dt
	for i in range(effects.size()-1,-1,-1):
		effects[i].life-=dt
		if effects[i].life<=0: effects.remove_at(i)
	status.text=(Catalog.JOBS[locked_job]+" · "+current_item().name+" · locked for this run") if in_run else "Select a job and starting item below"
	resources.text="HP %d    MP %d    STAMINA %d    |    Mastery %d    |    Power gems %d (+%d%% damage)" % [player.health,player.mana,player.stamina,mastery,power,power*15]
	if training_mode:
		resources.text="∞ HP / MP / STAMINA    ·    ZERO RECHARGE    ·    All items available    ·    Power +%d%%" % (power*15)
		status.text=Catalog.JOBS[locked_job]+" · "+current_item().name+" · "+current_item().combo
	queue_redraw()
func sync_actor_processing() -> void:
	var playing := in_run and not equipment_panel.visible and not item_library.visible
	player.set_physics_process(playing)
	for enemy in combat_targets: enemy.set_physics_process(playing)
func quick_select(job: int, slot: int) -> void:
	if not training_mode: return
	show_choices()
	selected_job=clampi(job,0,3)
	selected_slot=clampi(slot,0,3)
	start_selected()
func _input(event: InputEvent) -> void:
	if not training_mode or not event is InputEventKey or not event.pressed or event.echo: return
	var handled := true
	match event.keycode:
		KEY_F1: quick_select(0,0)
		KEY_F2: quick_select(2,0)
		KEY_F3: quick_select(1,0)
		KEY_F4: quick_select(3,0)
		KEY_F5, KEY_F6, KEY_F7, KEY_F8: quick_select(locked_job,event.keycode-KEY_F5)
		KEY_Q: quick_select(locked_job,(locked_slot+1)%4)
		KEY_K:
			if not in_run: start_selected()
			equipment_panel.hide()
			item_library.visible=not item_library.visible
			if item_library.visible: item_library.refresh()
		KEY_ESCAPE:
			item_library.hide()
			equipment_panel.hide()
			if not in_run: start_selected()
		_: handled=false
	if handled: get_viewport().set_input_as_handled()
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_B: show_choices()
	elif in_run and event.keycode==KEY_I:
		item_library.hide()
		equipment_panel.visible=not equipment_panel.visible
		equipment_panel.refresh()
	elif in_run and not equipment_panel.visible and not item_library.visible and event.keycode==KEY_1: player.use_gem(0)
	elif in_run and not equipment_panel.visible and not item_library.visible and event.keycode==KEY_2: player.use_gem(1)
	elif in_run and not equipment_panel.visible and not item_library.visible and event.keycode==KEY_J: player.combat.start()
	elif in_run and not equipment_panel.visible and not item_library.visible and event.keycode==KEY_T: reset_targets()
	elif in_run and event.keycode==KEY_U: power=mini(5,power+1)
func _draw() -> void:
	for effect in effects:
		var color := Color(item_color(),effect.life/0.35)
		var origin: Vector2=effect.at
		var reach: float=effect.radius*effect.facing
		if effect.kind in ["whip","roots"]:
			var points := PackedVector2Array()
			for i in 16: points.append(origin+Vector2(reach*i/15.0,sin(i*0.4+effect.life*14)*12))
			draw_polyline(points,color,4,true)
			draw_circle(points[-1],8 if effect.kind=="whip" else 4,color)
		elif effect.kind=="earth":
			for i in 5:
				var p := origin+Vector2(reach*(i+1)/5.0,20)
				draw_colored_polygon(PackedVector2Array([p+Vector2(-12,0),p+Vector2(0,-45),p+Vector2(12,0)]),color)
		else: draw_arc(origin,effect.radius*(1-effect.life/0.7),-1.2,1.2,24,color,3,true)
