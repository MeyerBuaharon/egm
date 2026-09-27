shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// The painted hood has a dark interior. Make its face opening transparent
	// so the unchanged full-body face remains visible beneath it.
	vec2 p = UV * vec2(1254.0);
	if (p.x > 488.0 && p.y > 694.0 && max(c.r,max(c.g,c.b)) < 0.105) c.a = 0.0;
	COLOR = c * vertex_tint;
}
