shader_type canvas_item;
render_mode unshaded;

uniform float sway_strength : hint_range(0.0, 0.02) = 0.006;
uniform float sway_speed = 6.0;

uniform float pulse_speed = 2.0;
uniform float pulse_intensity : hint_range(0.0, 2.0) = 1.2;

uniform float pedestal_alpha : hint_range(0.0, 1.0) = 0.8;
uniform vec3 energy_color : source_color = vec3(0.3, 0.7, 1.0);

void fragment() {
	// Pulso energético
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);

	// Ladeo / vibración lateral (ghost-like)
	float sway = sin(UV.y * 20.0 + TIME * sway_speed) * sway_strength * pulse;

	vec2 offset = vec2(sway, 0.0);

	// Textura base desplazada
	vec4 tex = texture(TEXTURE, UV + offset);

	// Energía superpuesta (tipo Screen suave)
	vec3 energy = energy_color * pulse * pulse_intensity;
	vec3 final_rgb = 1.0 - (1.0 - tex.rgb) * (1.0 - energy);

	// Alpha etérea
	float final_alpha = tex.a * pedestal_alpha;

	COLOR = vec4(final_rgb, final_alpha);
}
