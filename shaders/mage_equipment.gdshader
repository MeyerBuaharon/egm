shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }

uniform vec3 fabric_tint = vec3(0.075, 0.115, 0.22);
uniform vec3 glove_tint = vec3(0.075, 0.115, 0.22);
uniform vec3 boot_tint = vec3(0.075, 0.115, 0.22);
uniform float hair_drop = 17.0;
uniform float hair_radius = 42.0;
uniform float hair_spread = 0.085;
uniform float hair_blue_ratio = 0.92;
uniform float exposed_skin_radius = 9.0;
uniform bool custom_appearance = false;
uniform vec4 hair_tint : source_color = vec4(1.0);
uniform vec4 skin_tint : source_color = vec4(1.0);
uniform vec2 raised_boot_at = vec2(-10000.0);
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
	vec3 navy = fabric_tint;
	vec3 gold = vec3(0.88, 0.63, 0.24);
	float head_distance = length((pixel-head_at)*pixel_scale/vec2(7.0,9.5));
	float hand_distance = min(distance(pixel, hand_a), distance(pixel, hand_b)) * pixel_scale;
	if (custom_appearance) {
		float spread = max(c.r,max(c.g,c.b))-min(c.r,min(c.g,c.b));
		bool hair_area = (pixel.y-head_at.y)*pixel_scale < hair_drop && distance(pixel,head_at)*pixel_scale < hair_radius;
		if (hair_area && spread<hair_spread && brightness>0.13 && c.b>c.r*hair_blue_ratio && !skin(original) && !blue_fabric(original)) {
			c.rgb = hair_tint.rgb*(0.4+brightness);
		} else if (skin(original) && (head_distance<1.8 || hand_distance<exposed_skin_radius)) {
			c.rgb *= skin_tint.rgb;
		}
	}
	vec2 step_uv = TEXTURE_PIXEL_SIZE * (0.65 / pixel_scale);
	if (wear_robes && blue_fabric(c)) {
		// Retain the painted folds and full-body silhouette. Gold follows actual
		// garment edges rather than an independently animated torso patch.
		bool edge = !blue_fabric(texture(TEXTURE, UV+vec2(step_uv.x,0.0))) || !blue_fabric(texture(TEXTURE, UV-vec2(step_uv.x,0.0))) || !blue_fabric(texture(TEXTURE, UV+vec2(0.0,step_uv.y))) || !blue_fabric(texture(TEXTURE, UV-vec2(0.0,step_uv.y)));
		c.rgb = navy * (0.6 + brightness * 3.0);
		if (edge) c.rgb = gold * (0.55 + brightness * 1.5);
	}
	if (wear_gloves && skin(original) && hand_distance < 9.0 && head_distance > 1.0) {
		// Repaint the existing fingers, preserving each casting gesture exactly.
		c.rgb = glove_tint * (0.55 + brightness * 2.8);
		if (hand_distance > 5.5) c.rgb = gold * (0.6 + brightness);
	}
	if (wear_boots && hand_distance>13.0 && head_distance>1.5 && ((feet_y-pixel.y)*pixel_scale < 24.0 || distance(pixel,raised_boot_at)*pixel_scale<13.0) && leather(original)) {
		bool edge = !leather(texture(TEXTURE, UV+vec2(step_uv.x,0.0))) || !leather(texture(TEXTURE, UV-vec2(step_uv.x,0.0))) || !leather(texture(TEXTURE, UV-vec2(0.0,step_uv.y)));
		c.rgb = boot_tint * (0.65 + brightness * 3.0);
		if (edge) c.rgb = gold * (0.65 + brightness * 1.4);
	}
	COLOR = c * vertex_tint;
}
