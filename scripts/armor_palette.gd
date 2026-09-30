extends RefCounted
const NAMES := ["Steel","Ember","Frost","Verdant"]
const METAL := [Color("778eaa"),Color("a64f33"),Color("8bd0da"),Color("69986c")]
const CLOTH := [Color("304f85"),Color("842f36"),Color("477d9a"),Color("376543")]
static func apply_to(mat: ShaderMaterial, class_id: int, _gear: RefCounted, _preset: int) -> void:
	mat.set_shader_parameter("class_id",class_id)
	mat.set_shader_parameter("appearance",0)
	for slot in 4:
		mat.set_shader_parameter("wear_%d" % slot,false)
