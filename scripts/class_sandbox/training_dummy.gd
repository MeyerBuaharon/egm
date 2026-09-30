extends "res://scripts/forest_mob.gd"
var total_damage := 0
var last_damage := 0
func reset() -> void:
	super.reset()
	max_health=1000000000
	health=max_health
	speed=0
	patrol=Vector2(25,1255)
	total_damage=0
	last_damage=0
func regular_hit(amount: int=10) -> void:
	health=max_health
	super.regular_hit(amount)
	last_damage=max_health-health
	total_damage+=last_damage
	health=max_health
func tick_attack(_dt: float) -> void: attack_time=-1
func tick_death(_dt: float) -> void:
	health=max_health
	death_time=-1
func _physics_process(dt: float) -> void:
	health=max_health
	super._physics_process(dt)
	var dot := max_health-health
	if dot>0:
		last_damage=dot
		total_damage+=dot
	health=max_health
func _draw() -> void:
	super._draw()
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(-67,-78),"IMMORTAL DUMMY",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e9d398"))
	draw_string(font,Vector2(-84,-59),"Hits %d  Last %d  Total %d" % [hit_count,last_damage,total_damage],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
