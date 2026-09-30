extends RefCounted
const NAMES := ["Warden","Strider","Hexbinder","Wildborn"]
const STYLES := [
	["Sword","Axe","Hammer","Spear"],
	["Bloodletter","Venom","Shadow","Flurry"],
	["Fire","Ice","Wind","Earth"],
	["Claws","Thorns","Roots","Feral"]
]
const COLORS := [Color("d8ad64"),Color("bc91e9"),Color("8dcdf0"),Color("9ac97c")]
const DESCRIPTIONS := [
	"Armored melee • four weapons • weapon-specific burrow finishers",
	"Fast dual blades • bleed, poison, ambush or flurry • rising ambush",
	"Gliding caster • four elements • elemental eruption",
	"Clawed forest guardian • thorns, roots and feral strikes • root ambush"
]
static func style_index(combat: Node) -> int:
	if "style" in combat: return combat.style
	if "element" in combat: return combat.element
	return combat.selected
static func style_name(class_id: int, combat: Node) -> String:
	return STYLES[class_id][style_index(combat)]
