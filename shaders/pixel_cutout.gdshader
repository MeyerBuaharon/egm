shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
    vec4 sample_color = texture(TEXTURE, UV);
    // Suppress faint atlas matte pixels without moving or modifying source artwork.
    if (sample_color.a < 0.5) { discard; }
    COLOR = vec4(sample_color.rgb, 1.0) * vertex_tint;
}
