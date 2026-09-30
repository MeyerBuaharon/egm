extends PanelContainer
var world: Node2D
var list: VBoxContainer
func _ready() -> void:
	position=Vector2(120,120)
	custom_minimum_size=Vector2(1040,585)
	add_theme_stylebox_override("panel",world.box(Color("0e1c25"),Color("bba370")))
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",10)
	add_child(layout)
	var top := HBoxContainer.new()
	layout.add_child(top)
	var title: Label=world.label("ALL ITEMS  /  CLICK USE OR EQUIP",22)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(title)
	top.add_child(world.button("Close · K / Esc",hide))
	layout.add_child(world.label("Starting items change your class/moveset. Jewelry and gems change stats or abilities.\nNormal effects are listed below; training waives resource costs and recharge.",14))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(995,470)
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	list=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",10)
	scroll.add_child(list)
	hide()
func refresh() -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	for job in [0,2,1,3]:
		list.add_child(world.label(world.Catalog.JOBS[job].to_upper(),19))
		for slot in 4:
			var item: Dictionary=world.Catalog.item(job,slot)
			add_row(item.name+" · "+item.type,item.role+"\nCombo: "+item.combo+"\nDig: "+item.dig,preload("res://scripts/class_sandbox/item_visual.gd").icon(job,slot),"Using" if world.locked_job==job and world.locked_slot==slot else "Use",func(): hide(); world.quick_select(job,slot))
	list.add_child(world.label("JEWELRY & BODY GEMS — ALL CLASSES",19))
	var gear: RefCounted=world.player.equipment
	for slot in 7:
		var equipped: bool=gear.has_equipped(world.locked_job,slot)
		add_row(gear.NAMES[slot]+" · "+gear.SLOTS[slot],gear.DETAILS[slot],gear.item_icon(slot),"Unequip" if equipped else "Equip",func(): gear.set_worn(world.locked_job,slot,not gear.has_equipped(world.locked_job,slot)); refresh())
	add_row("Power test gem","+15% damage per level, up to five levels. U also adds a level. Appearance is unchanged.",null,"Add level",func(): world.power=mini(5,world.power+1))
func add_row(title: String, description: String, icon: Texture2D, action: String, callback: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	list.add_child(row)
	if icon!=null:
		var art := TextureRect.new()
		art.texture=icon
		art.custom_minimum_size=Vector2(54,64)
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(art)
	var text := VBoxContainer.new()
	text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(world.label(title,16))
	var body: Label=world.label(description,13)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size=Vector2(700,0)
	text.add_child(body)
	var use: Button=world.button(action,callback)
	use.custom_minimum_size=Vector2(100,48)
	row.add_child(use)
