extends RefCounted

signal changed
const SLOTS := ["Helmet", "Robes", "Gloves", "Boots"]
const ITEM_NAMES := {
	0: ["Warden helm", "Warden war robes", "Warden gauntlets", "Warden boots"],
	2: ["Arcanist hood", "Arcanist robes", "Arcanist gloves", "Arcanist boots"]
}
# Separate class loadouts survive map changes and the gameplay reset.
var owned := {0: [false,false,false,false], 2: [false,false,false,false]}
var worn := {0: [false,false,false,false], 2: [false,false,false,false]}

func pickup(class_id: int, slot: int) -> bool:
	if not owned.has(class_id) or slot<0 or slot>=4 or owned[class_id][slot]:
		return false
	owned[class_id][slot] = true
	worn[class_id][slot] = true
	changed.emit()
	return true

func set_worn(class_id: int, slot: int, equipped: bool) -> bool:
	if not owned.has(class_id) or slot<0 or slot>=4 or not owned[class_id][slot]:
		return false
	worn[class_id][slot] = equipped
	changed.emit()
	return true

func has_equipped(class_id: int, slot: int) -> bool:
	return worn.has(class_id) and slot>=0 and slot<4 and worn[class_id][slot]
