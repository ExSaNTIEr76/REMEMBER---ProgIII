shader_type canvas_item;
render_mode unshaded;

uniform float min_on_time = 0.4;
uniform float max_on_time = 0.6;
uniform float min_off_time = 0.1;
uniform float max_off_time = 0.1;

uniform float glow_intensity : hint_range(0.0, 2.0) = 1.3;

float rand(float x) {
	return fract(sin(x * 12.9898) * 43758.5453);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Tiempo global
	float t = TIME;

	// Bloque temporal (cambia cada ~1 segundo, pero irregular)
	float block = floor(t);

	// Duraciones pseudo-aleatorias
	float on_time  = mix(min_on_time,  max_on_time,  rand(block + 1.0));
	float off_time = mix(min_off_time, max_off_time, rand(block + 2.0));

	float cycle = on_time + off_time;
	float local_time = mod(t, cycle);

	// ¿Estamos encendidos?
	float visible = step(local_time, on_time);

	// Fade suave (entrada y salida)
	float fade = smoothstep(0.0, 0.15, local_time)
	           * smoothstep(on_time, on_time - 0.15, local_time);

	float intensity = visible * fade;

	// Color hacia blanco mágico
	vec3 final_rgb = mix(tex.rgb, vec3(1.0), intensity * glow_intensity);

	// Alpha real (desaparece de verdad)
	float final_alpha = tex.a * intensity;

	COLOR = vec4(final_rgb, final_alpha);
}
