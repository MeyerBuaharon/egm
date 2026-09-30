extends RefCounted
signal changed
const SLOTS := ["Ring 1", "Ring 2", "Amulet", "Heart socket", "Lung socket", "Hand socket", "Core socket"]
const NAMES := ["Iron signet", "Sapphire ring", "Vitality amulet", "Aegis gem", "Gale gem", "Nova gem", "Renewal gem"]
const DETAILS := ["Passive: reduce incoming damage by 2.", "Passive: +3 mana regeneration per second.", "Passive: +4 stamina regeneration per second.", "Heart gem: reduce incoming damage by 3.", "Lung gem: +15% movement speed.", "1: Nova — 20 damage around you. 15 MP, 8 second cooldown.", "2: Renewal — restore 25 HP. 20 MP, 12 second cooldown."]
const ITEM_NAMES := {0:NAMES,1:NAMES,2:NAMES,3:NAMES}
static var icon_cache: Dictionary={}
# Independent class loadouts; jewelry and body sockets never alter character art.
var owned := {0:[false,false,false,false,false,false,false],1:[false,false,false,false,false,false,false],2:[false,false,false,false,false,false,false],3:[false,false,false,false,false,false,false]}
var worn := {0:[false,false,false,false,false,false,false],1:[false,false,false,false,false,false,false],2:[false,false,false,false,false,false,false],3:[false,false,false,false,false,false,false]}
func pickup(class_id: int, slot: int) -> bool:
	if not owned.has(class_id) or slot<0 or slot>=SLOTS.size() or owned[class_id][slot]: return false
	owned[class_id][slot]=true
	worn[class_id][slot]=true
	changed.emit()
	return true
func set_worn(class_id: int, slot: int, equipped: bool) -> bool:
	if not owned.has(class_id) or slot<0 or slot>=SLOTS.size() or not owned[class_id][slot]: return false
	worn[class_id][slot]=equipped
	changed.emit()
	return true
func has_equipped(class_id: int, slot: int) -> bool:
	return worn.has(class_id) and slot>=0 and slot<SLOTS.size() and worn[class_id][slot]
func bag_slots(class_id: int) -> Array[int]:
	var result: Array[int]=[]
	if not owned.has(class_id): return result
	for slot in SLOTS.size():
		if owned[class_id][slot] and not worn[class_id][slot]: result.append(slot)
	return result
func defense(class_id: int) -> int:
	return (2 if has_equipped(class_id,0) else 0)+(3 if has_equipped(class_id,3) else 0)
func speed_multiplier(class_id: int) -> float:
	return 1.15 if has_equipped(class_id,4) else 1.0
func mana_regen(class_id: int) -> float:
	return 3.0 if has_equipped(class_id,1) else 0.0
func stamina_regen(class_id: int) -> float:
	return 4.0 if has_equipped(class_id,2) else 0.0
static func item_icon(slot: int) -> Texture2D:
	if slot<0 or slot>=SLOTS.size(): return null
	if icon_cache.has(slot): return icon_cache[slot]
	if slot<3:
		icon_cache[slot]=preload("res://scripts/jewelry_icon.gd").make_icon(slot+4)
		return icon_cache[slot]
	var colors := ["#9aaedc","#9ee7aa","#c8a3f2","#74dbc8"]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48"><path d="M24 3 L41 17 L34 38 L24 45 L14 38 L7 17Z" fill="%s" stroke="#eadac0" stroke-width="2"/><path d="M24 3 L18 20 L24 45 L30 20Z" fill="#ffffff" opacity=".3"/></svg>' % colors[slot-3]
	var img := Image.new()
	img.load_svg_from_string(svg)
	icon_cache[slot]=ImageTexture.create_from_image(img)
	return icon_cache[slot]
