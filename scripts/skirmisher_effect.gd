extends Node2D
var kind := "slash"
var tint := Color.WHITE
var radius := 70.0
var facing := 1.0
var time := 0.0
var duration := 0.32
func _ready() -> void:
	add_to_group("map_combat_transients")
func _process(dt: float) -> void:
	time+=dt
	if time>=duration: queue_free()
	queue_redraw()
func _draw() -> void:
	var u := clampf(time/duration,0,1)
	var opacity := 1-u
	draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
	if kind=="gem":
		draw_arc(Vector2.ZERO,radius*u,0,TAU,64,Color(tint,opacity),3,true)
		for i in 12:
			var angle := TAU*i/12.0
			draw_circle(Vector2.from_angle(angle)*radius*u,3*(1-u),Color(tint,opacity))
	elif kind in ["roots","ambush"]:
		for i in 7:
			var x := (i-3)*radius/4
			var height := (35+float(i%3)*13)*sin(u*PI)
			var points := PackedVector2Array([Vector2(x-5,18),Vector2(x+sin(float(i))*13,-height),Vector2(x+7,18)])
			draw_colored_polygon(points,Color(tint,opacity))
		draw_arc(Vector2(0,15),radius*u,PI,TAU,32,Color(tint,opacity),3,true)
	else:
		for layer in (3 if kind=="claw" else 2):
			var points := PackedVector2Array()
			var angle := lerpf(-1.7,0.7,u)
			for i in 14:
				var a := angle-1.0+float(i)/13
				points.append(Vector2(cos(a)*(radius-16-layer*8),sin(a)*(radius*0.45))+Vector2(-8,layer*7))
			draw_polyline(points,Color(tint.lightened(layer*0.2),opacity),4-layer,true)
