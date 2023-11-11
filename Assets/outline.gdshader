shader_type canvas_item;

uniform bool is_active = false;
uniform vec4 outline_color: source_color = vec4(1.0);

// for each pixel
void fragment() {
	// get current pixel color
	vec4 pixel_color = texture(TEXTURE, UV);
	if (is_active) {
		if (pixel_color.a == 0.0) {
			// look up neighbors for any color pixel / alpha value
			vec2 size = TEXTURE_PIXEL_SIZE * 1.0;
			vec4 neighbor = texture(TEXTURE, UV + vec2(size.x, 0)) +
							texture(TEXTURE, UV + vec2(-size.x, 0)) +
							texture(TEXTURE, UV + vec2(0, size.y)) +
							texture(TEXTURE, UV + vec2(0, -size.y));
			if (neighbor.a > 0.0) {
				pixel_color = outline_color;
			}
		}
	}
	COLOR = pixel_color;
}
