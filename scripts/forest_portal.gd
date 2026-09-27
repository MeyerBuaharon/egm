extends Node2D

var destination := 0
var destination_name := ""
var nearby := false
var clock := 0.0

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var outline := PackedVector2Array()
	for i in 65:
		var angle := TAU * i / 64.0
		outline.append(Vector2(cos(angle)*26,sin(angle)*47-48))
	draw_colored_polygon(outline,Color(0.08,0.22,0.34,0.75))
	for width in [16,9,3]:
		draw_polyline(outline,Color(0.28,0.8,1.0,0.12 if width>3 else 0.95),width,true)
	for j in 3:
		var spiral := PackedVector2Array()
		for i in 35:
			var angle := i*0.13+clock*1.6+j*TAU/3
			var radius := 4+i*0.52
			spiral.append(Vector2(cos(angle)*radius,sin(angle)*radius*1.65-48))
		draw_polyline(spiral,Color(0.65,0.9,1,0.45),1.5,true)
	draw_line(Vector2(-32,0),Vector2(32,0),Color("b6dfe9"),3)
	var text := "↑ / E  " + destination_name if nearby else destination_name
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13)
	draw_string(font,Vector2(-size.x*0.5,-112),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("d4f4ff"))
