extends RefCounted
const NAMES := ["Silver", "Chestnut", "Auburn", "Onyx"]
const HAIR := [Color.WHITE,Color("513221"),Color("a54325"),Color("292631")]
const SKIN := [Color.WHITE,Color(0.9,0.8,0.72),Color(1,0.94,0.89),Color(0.57,0.43,0.34)]
static func apply_to(material: ShaderMaterial, index: int) -> void:
	index = clampi(index,0,3)
	material.set_shader_parameter("custom_appearance",index!=0)
	material.set_shader_parameter("hair_tint",HAIR[index])
	material.set_shader_parameter("skin_tint",SKIN[index])
