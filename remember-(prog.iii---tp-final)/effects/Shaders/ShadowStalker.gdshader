shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 eye_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float eye_tolerance : hint_range(0.0, 1.0) = 0.2;
uniform float alpha_multiplier : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (tex.a < 0.1) {
        discard;
    }

    vec3 eye_base = vec3(0.3, 0.6, 1.0);
    float distance_to_eye = distance(tex.rgb, eye_base);

    vec4 final_color;

    if (distance_to_eye < eye_tolerance) {
        final_color = eye_color;
    } else {
        final_color = shadow_color;
    }

    final_color.a = tex.a * alpha_multiplier;

    COLOR = final_color;
}
