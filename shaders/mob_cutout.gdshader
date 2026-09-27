shader_type canvas_item;
render_mode unshaded;
uniform float clip_y = 10000.0;
varying float local_y;
varying vec4 vertex_tint;
void vertex() { local_y = VERTEX.y; vertex_tint = COLOR; }
void fragment() {
    vec4 texel = texture(TEXTURE, UV);
    if (texel.a < 0.5 || local_y > clip_y) { discard; }
    COLOR = vec4(texel.rgb, 1.0) * vertex_tint;
}
