extends SceneTree
const Save = preload("res://scripts/forest_save.gd")
const PATH := "/tmp/egm-campaign-roundtrip.json"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var room: Node2D=load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	if "--write" in OS.get_cmdline_user_args():
		room.progress.embers=60
		room.progress.points=3
		room.progress.buy("fleet")
		room.progress.buy("deep")
		room.progress.claim("edge_cache")
		room.character_level=3
		room.experience=17
		room.load_map(1)
		room.select_class(3)
		room.player.character_name="Ash"
		room.player.equipment.pickup(3,5)
		var error := Save.write(Save.capture(room),PATH)
		print("PASS separate-process save" if error==OK else "FAIL save")
		quit(0 if error==OK else 1)
	else:
		var data := Save.load_data(PATH)
		var ok := Save.apply(room,data)
		ok=ok and room.map_index==1 and room.character_level==3 and room.experience==17 and room.progress.has("deep") and "edge_cache" in room.progress.collected and room.player.character_name=="Ash" and room.player.equipment.has_equipped(3,5)
		print("PASS cold restart restores map, class, name, XP, tree, loot and gems" if ok else "FAIL cold restart")
		for suffix in ["",".bak",".tmp"]:
			if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(PATH+suffix)
		quit(0 if ok else 1)
