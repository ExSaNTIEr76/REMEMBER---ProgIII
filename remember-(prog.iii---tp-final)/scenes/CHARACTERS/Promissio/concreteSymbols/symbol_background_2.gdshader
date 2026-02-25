shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(0.4, 0.8, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 5.0) = 2.0;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.5;
uniform float distortion_strength : hint_range(0.0, 0.05) = 0.015;
uniform float distortion_speed : hint_range(0.0, 10.0) = 3.0;

void fragment() {
    float time = TIME;

    // Coordenadas UV con distorsión mágica
    vec2 uv = UV;
    uv.x += sin(uv.y * 20.0 + time * distortion_speed) * distortion_strength;
    uv.y += cos(uv.x * 20.0 + time * distortion_speed) * distortion_strength;

    vec4 base_tex = texture(TEXTURE, uv);

    // Pulso luminoso
    float pulse = 0.5 + 0.5 * sin(time * pulse_speed);

    // Intensidad basada en alpha del sprite
    float intensity = base_tex.a * pulse * glow_strength;

    vec3 final_color = base_tex.rgb + glow_color.rgb * intensity;

    COLOR = vec4(final_color, base_tex.a);
}
