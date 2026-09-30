extends Control
const Progress = preload("res://scripts/forest_progress.gd")
const GOLD := Color("e7c989")
var world: Node2D
var summary: Label
var detail: Label
var buttons: Array[Button]=[]
var centers: Array[Vector2]=[]
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	position=Vector2(130,105)
	size=Vector2(1020,565)
	mouse_filter=Control.MOUSE_FILTER_STOP
	hide()
	var title := Label.new()
	title.position=Vector2(35,22)
	title.text="The living roots"
	title.add_theme_font_size_override("font_size",30)
	title.add_theme_color_override("font_color",GOLD)
	add_child(title)
	summary=Label.new()
	summary.position=Vector2(37,65)
	add_child(summary)
	detail=Label.new()
	detail.position=Vector2(440,23)
	detail.size=Vector2(400,67)
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size",15)
	detail.add_theme_color_override("font_color",Color("d4ddcf"))
	detail.text="Choose a root to inspect its effect."
	add_child(detail)
	var close := Button.new()
	close.position=Vector2(893,25)
	close.size=Vector2(90,34)
	close.text="Close · P"
	close.pressed.connect(close_tree)
	add_child(close)
	for branch in 3:
		var heading := Label.new()
		heading.position=Vector2(90+branch*310,104)
		heading.size.x=220
		heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		heading.text=["Might","Resolve","Wayfarer"][branch]
		heading.add_theme_font_size_override("font_size",19)
		heading.add_theme_color_override("font_color",[Color("e7ad8a"),Color("91c7ac"),Color("9bbce2")][branch])
		add_child(heading)
		for tier in 3:
			var entry: Dictionary=Progress.NODES[branch*3+tier]
			var button := Button.new()
			button.position=Vector2(76+branch*310,359-tier*102)
			button.size=Vector2(250,82)
			button.add_theme_font_size_override("font_size",15)
			button.mouse_entered.connect(func(): detail.text=entry.name+"\n"+entry.detail)
			button.focus_entered.connect(func(): detail.text=entry.name+"\n"+entry.detail)
			button.pressed.connect(func():
				if world.progress.buy(entry.id): world.save_progress()
				refresh())
			add_child(button)
			buttons.append(button)
			centers.append(button.position+button.size/2)
	var help := Label.new()
	help.position=Vector2(35,513)
	help.text="Level up or discover memories for points. Defeat enemies and open caches for embers."
	help.add_theme_color_override("font_color",Color("b9c8bd"))
	add_child(help)
func open() -> void:
	show()
	get_tree().paused=true
	refresh()
	for button in buttons:
		if not button.disabled:
			button.grab_focus()
			break
func close_tree() -> void:
	hide()
	get_tree().paused=false
func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_P,KEY_ESCAPE]:
		close_tree()
		get_viewport().set_input_as_handled()
func refresh() -> void:
	summary.text="%d point%s available     %d embers" % [world.progress.points,"" if world.progress.points==1 else "s",world.progress.embers]
	for i in buttons.size():
		var entry: Dictionary=Progress.NODES[i]
		var learned: bool=world.progress.has(entry.id)
		var reason: String=world.progress.reason(entry.id)
		buttons[i].text=entry.name+"\n"+("Learned" if learned else "%d point%s · %d embers" % [entry.cost,"s" if entry.cost>1 else "",entry.embers])
		buttons[i].tooltip_text=entry.detail+("\n"+reason if reason!="" else "\nClick to learn")
		buttons[i].disabled=reason!=""
		var style := StyleBoxFlat.new()
		style.bg_color=Color("26473c") if learned else Color("182526")
		style.border_color=GOLD if learned else (Color("97b29e") if reason=="" else Color("45534e"))
		style.set_border_width_all(2 if learned else 1)
		style.set_corner_radius_all(10)
		var focus_style := style.duplicate() as StyleBoxFlat
		focus_style.bg_color=Color.TRANSPARENT
		focus_style.border_color=Color("f5de9b")
		focus_style.set_border_width_all(2)
		buttons[i].add_theme_stylebox_override("focus",focus_style)
		buttons[i].add_theme_stylebox_override("normal",style)
		buttons[i].add_theme_stylebox_override("disabled",style)
		buttons[i].add_theme_color_override("font_disabled_color",GOLD if learned else Color("9aaba0"))
	queue_redraw()
func _draw() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color=Color("0c191c")
	panel.border_color=Color("8a8261")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(16)
	draw_style_box(panel,Rect2(Vector2.ZERO,size))
	var seed := Vector2(511,478)
	for branch in 3:
		var root := centers[branch*3]+Vector2(0,42)
		draw_line(seed,root,Color("627f65"),3,true)
		for tier in 2:
			var index := branch*3+tier
			var tint := GOLD if world.progress.has(Progress.NODES[index+1].id) else Color("496356")
			draw_line(centers[index]-Vector2(0,41),centers[index+1]+Vector2(0,41),tint,3,true)
	draw_circle(seed,12,Color("496356"))
	draw_arc(seed,16,0,TAU,32,GOLD,2,true)
