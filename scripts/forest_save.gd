extends RefCounted
const SAVE_PATH := "user://forest-progress-v1.json"
const Progress = preload("res://scripts/forest_progress.gd")
static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version")!=1: return false
	for key in ["level","xp","map","class","points","embers"]:
		var value: Variant=data.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>1000000: return false
	if data.level<1 or data.map>2 or data.class>3: return false
	if not data.get("boss_defeated") is bool: return false
	for key in ["learned","collected","names","owned","worn"]:
		if not data.get(key) is Array: return false
	if data.names.size()!=4 or data.owned.size()!=4 or data.worn.size()!=4: return false
	for class_id in 4:
		if not data.names[class_id] is String or data.names[class_id].length()>24: return false
		for key in ["owned","worn"]:
			if not data[key][class_id] is Array or data[key][class_id].size()!=7: return false
			for value in data[key][class_id]:
				if not value is bool: return false
	for id in data.collected:
		if not id is String or id.length()>80: return false
	var seen: Array[String]=[]
	var model := Progress.new()
	for id in data.learned:
		if not id is String or id in seen: return false
		var entry := model.node(id)
		if entry.is_empty() or (entry.parent!="" and not entry.parent in seen): return false
		seen.append(id)
	return true
static func capture(world: Node2D) -> Dictionary:
	var p: RefCounted=world.progress
	var data := {"version":1,"level":world.character_level,"xp":world.experience,"map":world.map_index,"class":world.player.appearance.class_index,"points":p.points,"embers":p.embers,"learned":p.learned.duplicate(),"collected":p.collected.duplicate(),"boss_defeated":p.boss_defeated,"names":[],"owned":[],"worn":[]}
	for class_id in 4:
		data.names.append(world.player.character_profiles[class_id].name)
		data.owned.append(world.player.equipment.owned[class_id].duplicate())
		data.worn.append(world.player.equipment.worn[class_id].duplicate())
	return data
static func read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return {}
	return parser.data if valid(parser.data) else {}
static func load_data(path: String = SAVE_PATH) -> Dictionary:
	var data := read_file(path)
	return read_file(path+".bak") if data.is_empty() else data
static func write(data: Dictionary, path: String = SAVE_PATH) -> Error:
	if not valid(data): return ERR_INVALID_DATA
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error!=OK: return error
	if not read_file(path).is_empty():
		error=DirAccess.copy_absolute(path,path+".bak")
		if error!=OK: return error
	return DirAccess.rename_absolute(path+".tmp",path)
static func apply(world: Node2D, data: Dictionary) -> bool:
	if not valid(data): return false
	world.progress.points=int(data.points)
	world.progress.embers=int(data.embers)
	world.progress.learned.assign(data.learned)
	world.progress.collected.assign(data.collected)
	world.progress.boss_defeated=data.boss_defeated
	world.character_level=int(data.level)
	world.experience=int(data.xp)
	world.experience_needed=100+(world.character_level-1)*50
	for class_id in 4:
		world.player.character_profiles[class_id].name=data.names[class_id]
		world.player.equipment.owned[class_id]=data.owned[class_id].duplicate()
		world.player.equipment.worn[class_id]=data.worn[class_id].duplicate()
		for slot in 7:
			if not world.player.equipment.owned[class_id][slot]: world.player.equipment.worn[class_id][slot]=false
	world.select_class(int(data.class))
	world.load_map(int(data.map))
	return true
