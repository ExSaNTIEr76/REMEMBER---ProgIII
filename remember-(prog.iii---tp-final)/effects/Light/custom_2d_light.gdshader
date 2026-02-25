shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

render_mode blend_add, unshaded;

uniform sampler2D light_texture;
uniform vec4 light_color : source_color;
uniform float brightness : hint_range(0.0, 1.0) = 0.5;
uniform float attenuation_strength : hint_range(0.0, 1.0) = 0.5;
uniform float intensity : hint_range(0.0, 10.0) = 1.0;
uniform float max_brightness : hint_range(0.0, 0.3) = 0.1;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float energy : hint_range(0.0, 10.0) = 1.0;
uniform float contrast : hint_range(0.0, 3.0) = 1.0;
uniform float warm_tint : hint_range(0.0, 1.0) = 0.0;
uniform float edge_smoothness : hint_range(0.0, 1.0) = 0.0; // 🌟 NUEVO

vec3 adjust_saturation(vec3 color, float sat) {
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), color, sat);
}

vec3 adjust_contrast(vec3 color, float contrast_factor) {
    return mix(vec3(0.5), color, contrast_factor);
}


float smooth_mask(vec2 uv, float smoothness) {
    vec2 center = vec2(0.5);
    float dist = distance(uv, center);
    float radius = 0.5;
    float softness = mix(0.001, 0.5, smoothness);
    return smoothstep(radius, radius - softness, dist);
}

void fragment() {
    vec4 light_tex_color = texture(light_texture, UV);
    vec4 under_color = texture(SCREEN_TEXTURE, SCREEN_UV);

    // ✅ Calcular y aplicar suavizado
    float edge_mask = smooth_mask(UV, edge_smoothness);
    light_tex_color.rgb *= edge_mask;
    light_tex_color.a *= edge_mask;

    vec3 saturated_light_color = adjust_saturation(light_color.rgb, saturation);

    float under_brightness = dot(under_color.rgb, vec3(0.299, 0.587, 0.114));
    float attenuation = mix(1.0, under_brightness, attenuation_strength);

    vec3 lit_color = light_tex_color.rgb * attenuation * saturated_light_color * brightness * intensity;
    lit_color *= energy;

    vec3 warm_filter = vec3(1.0, 0.6, 0.4);
    lit_color = mix(lit_color, lit_color * warm_filter, warm_tint);

    lit_color = adjust_contrast(lit_color, contrast);
    lit_color = min(lit_color, vec3(max_brightness));

    COLOR = vec4(lit_color, light_tex_color.a);
}
