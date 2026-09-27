shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }

uniform bool wear_robes = false;
uniform bool wear_gloves = false;
uniform bool wear_boots = false;
uniform vec2 head_at;
uniform vec2 hand_a;
uniform vec2 hand_b;
uniform float pixel_scale = 0.23;
uniform float feet_y = 425.0;

bool blue_fabric(vec4 c) {
	return c.a > 0.2 && c.b > c.r * 1.16 && c.b > c.g * 1.06;
}
bool leather(vec4 c) {
	return c.a > 0.2 && c.r > c.b * 1.22 && c.g > c.b * 1.03 && c.r > 0.055;
}
bool skin(vec4 c) {
	return c.a > 0.2 && c.r > c.b * 1.35 && c.r > c.g * 1.12 && c.r > 0.22;
}
void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec4 c = original;
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	float brightness = dot(c.rgb, vec3(0.3, 0.5, 0.2));
	vec3 navy = vec3(0.075, 0.115, 0.22);
	vec3 gold = vec3(0.88, 0.63, 0.24);
	vec2 step_uv = TEXTURE_PIXEL_SIZE * (0.65 / pixel_scale);
	if (wear_robes && blue_fabric(c)) {
		// Retain the painted folds and full-body silhouette. Gold follows actual
		// garment edges rather than an independently animated torso patch.
		bool edge = !blue_fabric(texture(TEXTURE, UV+vec2(step_uv.x,0.0))) || !blue_fabric(texture(TEXTURE, UV-vec2(step_uv.x,0.0))) || !blue_fabric(texture(TEXTURE, UV+vec2(0.0,step_uv.y))) || !blue_fabric(texture(TEXTURE, UV-vec2(0.0,step_uv.y)));
		c.rgb = navy * (0.6 + brightness * 3.0);
		if (edge) c.rgb = gold * (0.55 + brightness * 1.5);
	}
	float hand_distance = min(distance(pixel, hand_a), distance(pixel, hand_b)) * pixel_scale;
	float head_distance = length((pixel-head_at)*pixel_scale/vec2(7.0,9.5));
	if (wear_gloves && skin(original) && hand_distance < 9.0 && head_distance > 1.0) {
		// Repaint the existing fingers, preserving each casting gesture exactly.
		c.rgb = navy * (0.55 + brightness * 2.8);
		if (hand_distance > 5.5) c.rgb = gold * (0.6 + brightness);
	}
	if (wear_boots && (feet_y-pixel.y)*pixel_scale < 24.0 && leather(original)) {
		bool edge = !leather(texture(TEXTURE, UV+vec2(step_uv.x,0.0))) || !leather(texture(TEXTURE, UV-vec2(step_uv.x,0.0))) || !leather(texture(TEXTURE, UV-vec2(0.0,step_uv.y)));
		c.rgb = navy * (0.65 + brightness * 3.0);
		if (edge) c.rgb = gold * (0.65 + brightness * 1.4);
	}
	COLOR = c * vertex_tint;
}
