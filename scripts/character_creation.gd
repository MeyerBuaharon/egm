extends PanelContainer
# Character identity is fixed by class. This panel edits only the display name.
var world: Node2D
var previous_pause := false
var name_input: LineEdit
var title: Label
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	position=Vector2(365,275)
	custom_minimum_size=Vector2(550,0)
	var style := StyleBoxFlat.new()
	style.bg_color=Color("102025")
	style.border_color=Color("a88c58")
	style.set_border_width_all(1)
	style.content_margin_left=20
	style.content_margin_right=20
	style.content_margin_top=18
	style.content_margin_bottom=18
	add_theme_stylebox_override("panel",style)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",14)
	add_child(layout)
	title=Label.new()
	title.add_theme_font_size_override("font_size",22)
	layout.add_child(title)
	var hint := Label.new()
	hint.text="Your class has a fixed look. Gems change your powers."
	hint.add_theme_font_size_override("font_size",13)
	layout.add_child(hint)
	name_input=LineEdit.new()
	name_input.max_length=24
	name_input.placeholder_text="Character name"
	layout.add_child(name_input)
	var footer := HBoxContainer.new()
	layout.add_child(footer)
	var apply := Button.new()
	apply.text="Save name"
	apply.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	apply.pressed.connect(apply_choice)
	footer.add_child(apply)
	var cancel := Button.new()
	cancel.text="Cancel"
	cancel.pressed.connect(hide)
	footer.add_child(cancel)
	hide()
	visibility_changed.connect(func():
		if visible:
			previous_pause=get_tree().paused
			get_tree().paused=true
		else: get_tree().paused=previous_pause)
func open() -> void:
	title.text="Name your "+preload("res://scripts/class_roster.gd").NAMES[world.player.appearance.class_index]
	name_input.text=world.player.character_name
	show()
func apply_choice() -> void:
	var chosen := name_input.text.strip_edges()
	if not chosen.is_empty(): world.player.character_name=chosen
	if world.has_method("save_progress"): world.save_progress()
	hide()
func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		hide()
		get_viewport().set_input_as_handled()
