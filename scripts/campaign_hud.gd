extends Control
var world: Node2D
func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_dt: float) -> void: queue_redraw()
func label(at: Vector2,value: String,size: int,tint: Color) -> void:
	draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,tint)
func _draw() -> void:
	var gold := Color("e7c989")
	var objectives := ["Find forest memories. Follow the eastern portal.","Explore the high ruins. Reach the mansion gate.","Defeat the Hollow Regent."]
	var objective: String=objectives[world.map_index]
	if world.map_index==2 and world.progress.boss_defeated:
		objective="The gate is yours. Claim the mansion seal." if not "mansion_seal" in world.progress.collected else "Mansion seal claimed. The forest is free."
	label(Vector2(35,96),objective,14,Color("e2dac3"))
	label(Vector2(35,118),"%d embers   ·   %d passive point%s   ·   P: living roots" % [world.progress.embers,world.progress.points,"" if world.progress.points==1 else "s"],13,gold)
	if is_instance_valid(world.boss) and world.boss.engaged and world.boss.health>0:
		var rect := Rect2(390,139,500,15)
		draw_rect(Rect2(380,127,520,64),Color(0.03,0.045,0.05,0.92))
		draw_rect(rect,Color("33252b"))
		draw_rect(Rect2(rect.position,Vector2(rect.size.x*world.boss.health/world.boss.MAX_HEALTH,rect.size.y)),Color("b76c62") if not world.boss.enraged else Color("bd506d"))
		label(Vector2(394,150),"Hollow Regent  %d / %d" % [world.boss.health,world.boss.MAX_HEALTH],11,Color.WHITE)
		label(Vector2(390,177),world.boss.tell if world.boss.tell!="" else ("Enraged" if world.boss.enraged else "Rooted guardian · resists launch and burial"),13,gold)
	if world.notice_time>0:
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(world.notice,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x+36
		var rect := Rect2(640-width/2,641,width,36)
		draw_rect(rect,Color(0.03,0.07,0.075,0.94))
		draw_line(rect.position,rect.position+Vector2(width,0),gold,1)
		label(rect.position+Vector2(18,24),world.notice,16,gold)
