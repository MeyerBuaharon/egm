extends Node2D
var world: Node2D
var age := 0.0
var warning := 1.05
var radius := 45.0
var damage := 18
var fired := false
var wide := false
func _ready() -> void:
	add_to_group("map_combat_transients")
	add_to_group("boss_hazards")
	z_index=3
func _physics_process(dt: float) -> void:
	age+=dt
	if age>=warning and not fired:
		fired=true
		var p: CharacterBody2D=world.player
		var area := Rect2(position+Vector2(-radius,-72),Vector2(radius*2,76))
		var body := Rect2(p.position-Vector2(12,19),Vector2(24,38))
		if not p.burrowed and area.intersects(body): p.take_damage(damage)
	if age>warning+0.65: queue_free()
	queue_redraw()
func _draw() -> void:
	var tint := Color("ee8e6e") if not fired else Color("d6b286")
	if not fired:
		var t := clampf(age/warning,0,1)
		draw_rect(Rect2(-radius,-5,radius*2,7),Color(tint,0.15+t*0.35))
		draw_line(Vector2(-radius,-3),Vector2(radius,-3),tint,2)
		draw_line(Vector2(-radius,-3),Vector2(-radius,-12),tint,2)
		draw_line(Vector2(radius,-3),Vector2(radius,-12),tint,2)
		draw_arc(Vector2(0,-15),9,-PI/2,-PI/2+TAU*t,32,tint,2)
	else:
		var fade := 1-clampf((age-warning)/0.65,0,1)
		var spikes := 9 if wide else 5
		for i in spikes:
			var x := lerpf(-radius+6,radius-6,float(i)/maxi(1,spikes-1))
			var height := (52+18*sin(i*2.1))*minf(1,(age-warning)*16+0.25)
			draw_colored_polygon(PackedVector2Array([Vector2(x-9,0),Vector2(x-4,-height*0.6),Vector2(x+8,-height),Vector2(x+6,-height*0.3),Vector2(x+12,0)]),Color(Color("775a48"),fade))
			draw_line(Vector2(x+2,-height*0.2),Vector2(x+8,-height),Color(tint,fade),2)
