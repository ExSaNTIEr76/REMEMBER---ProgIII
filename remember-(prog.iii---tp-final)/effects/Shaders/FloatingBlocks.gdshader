shader_type canvas_item;
render_mode unshaded;

vec4 texturePointSmooth(sampler2D smp, vec2 uv, vec2 pixel_size) {
	vec2 ddx = dFdx(uv);
	vec2 ddy = dFdy(uv);
	vec2 lxy = sqrt(ddx * ddx + ddy * ddy);

	vec2 uv_pixels = uv / pixel_size;
	vec2 uv_pixels_floor = round(uv_pixels) - vec2(0.5);
	vec2 uv_dxy_pixels = uv_pixels - uv_pixels_floor;

	uv_dxy_pixels = clamp((uv_dxy_pixels - vec2(0.5)) * pixel_size / lxy + vec2(0.5), 0.0, 1.0);
	uv = uv_pixels_floor * pixel_size;

	return textureGrad(smp, uv + uv_dxy_pixels * pixel_size, ddx, ddy);
}

uniform float flash_opacity = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0, 0.0, 0.0);

void fragment() {
	vec4 smooth_tex = texturePointSmooth(TEXTURE, UV, TEXTURE_PIXEL_SIZE);
	vec3 mixed_color = mix(smooth_tex.rgb, flash_color, flash_opacity);
	COLOR = vec4(mixed_color, smooth_tex.a);
}