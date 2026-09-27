extends Node2D

var world: Node2D
var class_id := 0
var slot := 0
var clock := 0.0
var nearby := false
var icon: Texture2D

func _process(dt: float) -> void:
	clock += dt
	var p: CharacterBody2D = world.player
	visible = world.map_index==0 and p.appearance.class_index==class_id and not p.equipment.owned[class_id][slot]
	nearby = can_collect()
	queue_redraw()

func can_collect() -> bool:
	var p: CharacterBody2D = world.player
	return world.map_index==0 and p.appearance.class_index==class_id and not p.equipment.owned[class_id][slot] and not world.transitioning and not p.burrowed and not p.combat.active and p.position.distance_to(position+Vector2(0,-19))<48

func collect() -> bool:
	if not can_collect():
		return false
	return world.player.equipment.pickup(class_id,slot)

func _draw() -> void:
	if not visible: return
	var tint := Color("e2c27c")
	draw_line(Vector2(-10,-1),Vector2(10,-1),Color(tint,0.65),2,true)
	draw_circle(Vector2(0,-18),18,Color(tint,0.08))
	if icon:
		draw_texture_rect(icon,Rect2(-15,-36+sin(clock*2.3)*2,30,30),false)
	if nearby and world.nearest_pickup()==self:
		var caption: String = "F • Wear " + preload("res://scripts/character_equipment.gd").ITEM_NAMES[class_id][slot]
		draw_string(ThemeDB.fallback_font,Vector2(-70,-48),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ffebba"))
