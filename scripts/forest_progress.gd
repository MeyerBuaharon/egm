extends RefCounted
signal changed
const NODES := [
	{"id":"edge","name":"Keen edge","branch":"Might","parent":"","cost":1,"embers":8,"detail":"Deal 20% more damage."},
	{"id":"siphon","name":"Blood sap","branch":"Might","parent":"edge","cost":1,"embers":12,"detail":"Recover 8 HP after defeating a foe."},
	{"id":"execution","name":"Heartbreaker","branch":"Might","parent":"siphon","cost":2,"embers":20,"detail":"Deal 30% more damage to foes below 35% HP."},
	{"id":"bark","name":"Iron bark","branch":"Resolve","parent":"","cost":1,"embers":8,"detail":"Reduce incoming damage by 2."},
	{"id":"breath","name":"Second wind","branch":"Resolve","parent":"bark","cost":1,"embers":12,"detail":"Recover 4 extra stamina per second."},
	{"id":"stand","name":"Last stand","branch":"Resolve","parent":"breath","cost":2,"embers":20,"detail":"Take 35% less damage while below 35 HP."},
	{"id":"fleet","name":"Wind step","branch":"Wayfarer","parent":"","cost":1,"embers":8,"detail":"Move 10% faster."},
	{"id":"deep","name":"Deep roots","branch":"Wayfarer","parent":"fleet","cost":1,"embers":12,"detail":"Burrowing drains 25% less stamina."},
	{"id":"echo","name":"Afterimage","branch":"Wayfarer","parent":"deep","cost":2,"embers":20,"detail":"Dash recharges 25% faster."}
]
var points := 1
var embers := 0
var learned: Array[String] = []
var collected: Array[String] = []
var boss_defeated := false
func node(id: String) -> Dictionary:
	for entry in NODES:
		if entry.id==id: return entry
	return {}
func has(id: String) -> bool: return id in learned
func reason(id: String) -> String:
	var entry := node(id)
	if entry.is_empty(): return "Unknown passive"
	if has(id): return "Learned"
	if entry.parent!="" and not has(entry.parent): return "Requires "+node(entry.parent).name
	if points<int(entry.cost): return "Earn more points by leveling or finding memories"
	if embers<int(entry.embers): return "Find more embers in enemies and caches"
	return ""
func buy(id: String) -> bool:
	if reason(id)!="": return false
	var entry := node(id)
	points-=entry.cost
	embers-=entry.embers
	learned.append(id)
	changed.emit()
	return true
func claim(id: String) -> bool:
	if id in collected: return false
	collected.append(id)
	return true
func damage(amount: int, target_health: int, target_max: int) -> int:
	var multiplier := 1.0+(0.2 if has("edge") else 0.0)+(0.1 if "mansion_seal" in collected else 0.0)
	if has("execution") and target_health<float(target_max)*0.35: multiplier+=0.3
	return maxi(1,roundi(amount*multiplier))
