extends Node2D
# Reuse the existing four weapon silhouettes, attached to the painted hand.
var weapon := 0
func _draw() -> void:
	var tint := Color.WHITE
	var metal := Color("a8bfca")*tint
	var gold := Color("d0a555")*tint
	draw_line(Vector2(0,8),Vector2(0,-8),Color("5e4331")*tint,3,true)
	match weapon:
		0:
			draw_colored_polygon(PackedVector2Array([Vector2(-3,-8),Vector2(-3,-32),Vector2(0,-39),Vector2(3,-32),Vector2(3,-8)]),metal)
			draw_line(Vector2(0,-8),Vector2(0,-36),Color(1,1,1,tint.a),1,true)
			draw_line(Vector2(-7,-7),Vector2(7,-7),gold,3,true)
		1:
			draw_line(Vector2(0,8),Vector2(0,-35),gold,3,true)
			draw_colored_polygon(PackedVector2Array([Vector2(-2,-35),Vector2(14,-39),Vector2(18,-26),Vector2(-2,-22)]),metal)
		2:
			draw_line(Vector2(0,8),Vector2(0,-30),gold,3,true)
			draw_rect(Rect2(-12,-37,24,13),metal)
		3:
			draw_line(Vector2(0,16),Vector2(0,-40),gold,3,true)
			draw_colored_polygon(PackedVector2Array([Vector2(-5,-38),Vector2(0,-53),Vector2(5,-38)]),metal)
