extends PanelContainer

var world: Node2D
var title: Label
var rows: Array[Button] = []
var last_class := -1

func _ready() -> void:
	position = Vector2(28,105)
	custom_minimum_size = Vector2(286,285)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102025")
	style.border_color = Color("a88c58")
	style.set_border_width_all(1)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel",style)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation",9)
	add_child(list)
	title = Label.new()
	title.add_theme_font_size_override("font_size",20)
	list.add_child(title)
	for slot in 4:
		var button := Button.new()
		button.custom_minimum_size = Vector2(260,42)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",30)
		button.pressed.connect(toggle.bind(slot))
		list.add_child(button)
		rows.append(button)
	var hint := Label.new()
	hint.text = "F: pick up & wear nearby gear\nClick a slot to equip / remove.  I: close"
	hint.add_theme_font_size_override("font_size",12)
	list.add_child(hint)
	world.player.equipment.changed.connect(refresh)
	refresh()
	visible = false

func _process(_dt: float) -> void:
	if last_class!=world.player.appearance.class_index: refresh()

func toggle(slot: int) -> void:
	var p: CharacterBody2D = world.player
	var c: int = p.appearance.class_index
	p.equipment.set_worn(c,slot,not p.equipment.has_equipped(c,slot))

func refresh() -> void:
	var p: CharacterBody2D = world.player
	last_class = p.appearance.class_index
	if not p.equipment.owned.has(last_class): return
	title.text = ("MAGE" if last_class==2 else "WARDEN") + "  •  EQUIPMENT"
	for slot in 4:
		var owned: bool = p.equipment.owned[last_class][slot]
		var worn: bool = p.equipment.has_equipped(last_class,slot)
		rows[slot].text = "%s · %s" % [p.equipment.SLOTS[slot],"Remove" if worn else ("Equip" if owned else "Not found")]
		rows[slot].disabled = not owned
		rows[slot].icon = preload("res://scripts/modular_character.gd").item_icon(last_class,slot)
		rows[slot].tooltip_text = p.equipment.ITEM_NAMES[last_class][slot]
