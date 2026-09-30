extends SceneTree
const Save = preload("res://scripts/forest_save.gd")
const PATH := "/tmp/egm-campaign-test.json"
var failures := 0
func check(ok: bool,label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL",label])
	if not ok: failures+=1
func _initialize() -> void: call_deferred("run")
func freeze_room(room: Node2D) -> void:
	room.player.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
func find_item(room: Node2D,id: String) -> Node2D:
	for item in room.pickups:
		if "item_id" in item and item.item_id==id: return item
	return null
func run() -> void:
	var room: Node2D=load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for i in 10: await physics_frame
	freeze_room(room)
	var p: CharacterBody2D=room.player
	check(not room.saving_enabled,"tests cannot overwrite player autosave")
	check(room.MAPS.size()==3 and room.portals.size()==1,"forest route starts with one forward portal")
	check(not room.progress.buy("execution"),"keystone requires its branch")
	check(not room.progress.buy("edge"),"passive purchase requires embers")
	var cache := find_item(room,"edge_cache")
	p.position=Vector2(280,681)
	check(cache.collect() and room.progress.embers==18,"first map cache grants embers")
	check(not cache.collect(),"cache cannot reward twice")
	check(room.progress.buy("edge") and room.progress.points==0 and room.progress.embers==10,"buy root consumes exact points and currency")
	check(not room.progress.buy("edge"),"learned passive cannot be purchased twice")
	var enemy: Node2D=room.combat_targets[0]
	enemy.regular_hit(10)
	check(enemy.health==28,"Might increases actual enemy damage")
	var memory := find_item(room,"edge_memory")
	check(not memory.collect(),"memory cannot be collected remotely")
	p.position=memory.position+Vector2(0,-19)
	check(memory.collect() and room.progress.points==1,"platform memory grants passive point")
	room.award_experience(100)
	check(room.character_level==2 and room.progress.points==2,"level awards passive point")
	room.progress.embers=200
	room.progress.points=20
	for id in ["siphon","execution","bark","breath","stand","fleet","deep","echo"]:
		check(room.progress.buy(id),"learn "+id)
	check(room.modify_damage(10,10,40)==15,"execution damage checks target max health")
	p.health=100
	p.hurt_time=0
	p.take_damage(10)
	check(p.health==92,"Iron bark reduces incoming hits")
	p.health=30
	p.hurt_time=0
	p.take_damage(10)
	check(p.health==25,"Last stand reduces low-health damage")
	var speed: float=p.base_run_speed()
	check(is_equal_approx(p.current_run_speed(),speed*1.1),"Wayfarer affects movement speed")
	p.stamina=100
	p.burrowed=true
	p.tick_resources(1)
	check(is_equal_approx(p.stamina,89.5),"Deep roots reduces burrow drain")
	p.burrowed=false
	p.dash_cooldown=0
	p.start_dash()
	check(is_equal_approx(p.dash_cooldown,p.dash_recharge*0.75),"Afterimage shortens dash recharge")
	p.dash_time=0
	room.passive_tree.open()
	check(room.passive_tree.buttons[8].text.begins_with("Afterimage"),"all tree nodes refresh without script errors")
	check(paused and room.passive_tree.visible,"tree pauses play while allocating")
	room.passive_tree.close_tree()
	check(not paused,"tree closes without leaving play paused")
	room.load_map(1)
	freeze_room(room)
	check(room.portals.size()==2 and room.portals[0].destination==0 and room.portals[1].destination==2,"grove connects back and onward")
	check(room.progress.has("edge") and find_item(room,"grove_cache")!=null,"passives persist and new map loot appears")
	room.load_map(0)
	freeze_room(room)
	check(find_item(room,"edge_cache").is_claimed(),"opened cache persists across maps")
	room.load_map(2)
	freeze_room(room)
	var boss: Node2D=room.boss
	check(is_instance_valid(boss) and boss.health==480,"mansion spawns distinct guardian")
	p.position=Vector2(700,681)
	boss.choose_attack()
	var hazards := get_nodes_in_group("boss_hazards")
	check(hazards.size()==3,"boss starts with three readable eruption warnings")
	var hazard: Node2D=hazards[0]
	p.position=hazard.position+Vector2(0,-19)
	p.health=100
	p.hurt_time=0
	hazard._physics_process(hazard.warning-0.01)
	check(p.health==100,"telegraph deals no early damage")
	hazard._physics_process(0.02)
	check(p.health<100,"eruption damages player inside marked area")
	var avoided: Node2D=hazards[1]
	p.position=avoided.position+Vector2(0,-150)
	p.health=100
	p.hurt_time=0
	avoided._physics_process(avoided.warning+0.01)
	check(p.health==100,"jump above eruption avoids hit")
	boss.health=240
	boss._physics_process(0.01)
	check(boss.enraged,"boss escalates at half health")
	boss.summon()
	check(room.combat_targets.size()==3,"boss calls two reinforcements")
	for mob in room.combat_targets: mob.set_physics_process(false)
	boss.summon()
	check(room.combat_targets.size()==3,"reinforcement cap prevents runaway spawning")
	room.on_player_defeated()
	check(boss.health==480 and not boss.enraged,"death resets encounter without losing build")
	boss.regular_hit(10000)
	check(room.progress.boss_defeated,"boss death records victory")
	var seal := find_item(room,"mansion_seal")
	p.position=seal.position+Vector2(0,-19)
	var points_before: int=room.progress.points
	check(seal.collect() and room.progress.points==points_before+3,"boss seal grants build reward")
	check(not seal.collect(),"boss reward cannot duplicate")
	check(room.modify_damage(10,40,40)==13,"claimed seal grants permanent damage bonus")
	p.equipment.pickup(1,5)
	p.character_profiles[1].name="Test runner"
	var data := Save.capture(room)
	check(Save.write(data,PATH)==OK,"atomic campaign save")
	check(Save.write(data,PATH)==OK,"save retains previous good backup")
	var broken := FileAccess.open(PATH,FileAccess.WRITE)
	broken.store_string("{truncated")
	broken.close()
	var restored := Save.load_data(PATH)
	check(Save.valid(restored) and restored.boss_defeated,"corrupt primary falls back to backup")
	room.progress.learned.clear()
	room.progress.boss_defeated=false
	check(Save.apply(room,restored),"saved progression can reconstruct world")
	freeze_room(room)
	check(room.progress.has("echo") and room.progress.boss_defeated and room.player.equipment.owned[1][5],"tree, boss and inventory survive restore")
	check(room.player.character_profiles[1].name=="Test runner" and room.boss==null,"names restored and defeated boss stays defeated")
	data.version=999
	check(not Save.valid(data),"unknown save version rejected")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(PATH+suffix)
	print("Forest campaign: %d failures" % failures)
	quit(failures)
