extends Control

const MAP_RECT := Rect2(14,35,232,116)
var world: Node2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(260,178)

func project(at: Vector2) -> Vector2:
	return MAP_RECT.position + at / Vector2(1280,800) * MAP_RECT.size

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_style_box(panel_style(),Rect2(0,0,260,178))
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(14,23),world.MAPS[world.map_index].name,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("ead9a8"))
	for block in world.blocks:
		var from := project(block.position)
		var to := project(Vector2(block.end.x,block.position.y))
		draw_line(from,to,Color("93ad80"),3)
	for portal in world.portals:
		draw_arc(project(portal.position-Vector2(0,35)),4,0,TAU,16,Color("72d9ff"),2)
	for mob in world.combat_targets:
		if mob.health > 0:
			draw_circle(project(mob.position),2.5,Color("e4897b"))
	var point := project(world.player.position)
	draw_circle(point,5,Color(0.1,0.1,0.1,0.8))
	draw_circle(point,3.2,Color("ffe38e"))
	draw_string(font,Vector2(14,167),"● You     ● Mobs     ○ Portal",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("bdcdc7"))

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035,0.07,0.075,0.9)
	style.border_color = Color(0.48,0.61,0.57,0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style
