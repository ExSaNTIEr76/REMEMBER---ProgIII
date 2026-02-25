shader_type canvas_item;
render_mode unshaded;

vec4 texturePointSmooth(sampler2D smp, vec2 uv, vec2 pixel_size) {
	vec2 ddx = dFdx(uv);
	vec2 ddy = dFdy(uv);
	vec2 lxy = sqrt(ddx * ddx + ddy * ddy);

	vec2 uv_pixels = uv / pixel_size;
	vec2 uv_pixels_floor = round(uv_pixels) - vec2(0.5);
	vec2 uv_dxy_pixels = uv_pixels - uv_pixels_floor;

	uv_dxy_pixels = clamp(
		(uv_dxy_pixels - vec2(0.5)) * pixel_size / lxy + vec2(0.5),
		0.0,
		1.0
	);

	uv = uv_pixels_floor * pixel_size;
	return textureGrad(smp, uv + uv_dxy_pixels * pixel_size, ddx, ddy);
}

uniform float flash_opacity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 tex = texturePointSmooth(TEXTURE, UV, TEXTURE_PIXEL_SIZE);

	// Intensidad total del flash
	float flash_strength = flash_opacity * flash_color.a;

	// Color con flash
	vec3 final_rgb = mix(tex.rgb, flash_color.rgb, flash_strength);

	// Alpha afectada por el flash (fade real)
	float final_alpha = tex.a * flash_strength;

	COLOR = vec4(final_rgb, final_alpha);
}
