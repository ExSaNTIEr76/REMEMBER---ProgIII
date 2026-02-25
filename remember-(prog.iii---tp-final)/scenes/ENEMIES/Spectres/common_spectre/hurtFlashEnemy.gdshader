shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float flash_opacity = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // 🔴 incluye alpha

// 🔲 Parámetros del reborde
uniform bool enable_outline = false;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Amarillo
uniform float outline_thickness = 1.0;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	vec4 final_color = base_color;

	// 🟥 Flash blending solo si el pixel no es transparente
	if (base_color.a > 0.01) {
		final_color.rgb = mix(base_color.rgb, flash_color.rgb, flash_opacity);
		final_color.a   = mix(base_color.a,   flash_color.a,   flash_opacity);
	}

	// 🟡 Reborde si está activado y el pixel actual es transparente
	if (enable_outline && base_color.a < 0.01) {
		bool has_neighbor = false;

		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				vec2 offset = vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE * outline_thickness;
				if (texture(TEXTURE, UV + offset).a > 0.01) {
					has_neighbor = true;
				}
			}
		}

		if (has_neighbor) {
			final_color = outline_color;
		}
	}

	COLOR = final_color;
}
