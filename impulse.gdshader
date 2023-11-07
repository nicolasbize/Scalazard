shader_type canvas_item;

void fragment() {
	vec2 uv = vec2(UV.x - sin(TIME * 40.0) * 0.1, UV.y + 0.1 + sin(TIME * 10.0) * 0.08);
	COLOR = texture(TEXTURE, uv);
}
