extends PanelContainer

var world: Node2D
var title: Label
var bag_title: Label
var outfit_note: Label
var rows: Array[Button] = []
var bag_buttons: Array[Button] = []
var last_class := -1

func _ready() -> void:
	position = Vector2(28,105)
	custom_minimum_size = Vector2(738,485)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102025")
	style.border_color = Color("a88c58")
	style.set_border_width_all(1)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	add_theme_stylebox_override("panel",style)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation",12)
	add_child(list)
	var top := HBoxContainer.new()
	list.add_child(top)
	title = Label.new()
	title.add_theme_font_size_override("font_size",22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close := Button.new()
	close.text = "Close · I"
	close.pressed.connect(func(): hide())
	top.add_child(close)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",22)
	list.add_child(columns)
	var equipped := VBoxContainer.new()
	equipped.add_theme_constant_override("separation",6)
	columns.add_child(equipped)
	var heading := Label.new()
	heading.text = "Equipment"
	heading.add_theme_color_override("font_color",Color("e7c989"))
	equipped.add_child(heading)
	for slot in world.player.equipment.SLOTS.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(205,44)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",30)
		button.pressed.connect(toggle.bind(slot))
		var row := HBoxContainer.new()
		equipped.add_child(row)
		row.add_child(button)
		rows.append(button)
	var bag := VBoxContainer.new()
	columns.add_child(bag)
	bag_title = Label.new()
	bag_title.add_theme_color_override("font_color",Color("e7c989"))
	bag.add_child(bag_title)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation",6)
	grid.add_theme_constant_override("v_separation",6)
	bag.add_child(grid)
	for index in 16:
		var button := Button.new()
		button.custom_minimum_size = Vector2(92,75)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",36)
		button.pressed.connect(equip_from_bag.bind(index))
		grid.add_child(button)
		bag_buttons.append(button)
	var hint := Label.new()
	hint.text = "F collects jewelry and gems. Click an equipped item to store it; click a bag item to equip."
	hint.add_theme_font_size_override("font_size",12)
	list.add_child(hint)
	outfit_note = Label.new()
	outfit_note.text = "Gems socket into your body. Equipment changes abilities and stats, never your appearance."
	outfit_note.add_theme_font_size_override("font_size",12)
	list.add_child(outfit_note)
	world.player.equipment.changed.connect(refresh)
	refresh()
	visible = false

func _process(_dt: float) -> void:
	if last_class!=world.player.appearance.class_index: refresh()

func toggle(slot: int) -> void:
	var p: CharacterBody2D = world.player
	var c: int = p.appearance.class_index
	if p.equipment.has_equipped(c,slot): p.equipment.set_worn(c,slot,false)

func equip_from_bag(index: int) -> void:
	var p: CharacterBody2D = world.player
	var c: int = p.appearance.class_index
	var items: Array[int] = p.equipment.bag_slots(c)
	if index>=0 and index<items.size(): p.equipment.set_worn(c,items[index],true)

func refresh() -> void:
	var p: CharacterBody2D = world.player
	last_class = p.appearance.class_index
	outfit_note.visible = true
	if not p.equipment.owned.has(last_class): return
	outfit_note.text="Defense +%d · Speed +%d%% · MP +%d/s · Stamina +%d/s. Appearance stays fixed." % [p.equipment.defense(last_class),roundi((p.equipment.speed_multiplier(last_class)-1)*100),p.equipment.mana_regen(last_class),p.equipment.stamina_regen(last_class)]
	title.text = preload("res://scripts/class_roster.gd").NAMES[last_class] + " · Jewelry & Gems"
	for slot in p.equipment.SLOTS.size():
		var worn: bool = p.equipment.has_equipped(last_class,slot)
		rows[slot].text = p.equipment.SLOTS[slot]+(" · Slotted" if worn else " · Empty")
		rows[slot].disabled = not worn
		rows[slot].icon = p.equipment.item_icon(slot) if worn else null
		rows[slot].tooltip_text = p.equipment.NAMES[slot]+" — "+p.equipment.DETAILS[slot]+" Click to store" if worn else "Equip an item from your bag"
	var items: Array[int] = p.equipment.bag_slots(last_class)
	bag_title.text = "Bag · %d / 16" % items.size()
	for index in 16:
		var button := bag_buttons[index]
		button.disabled = index>=items.size()
		button.icon = null
		button.text = "·"
		button.tooltip_text = "Empty space"
		if index<items.size():
			button.text = ""
			button.icon = p.equipment.item_icon(items[index])
			button.tooltip_text = p.equipment.NAMES[items[index]]+" — "+p.equipment.DETAILS[items[index]]+" Click to equip"
