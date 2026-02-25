shader_type canvas_item;
render_mode unshaded;

uniform float pulse_speed : hint_range(0.1, 5.0) = 1.2;
uniform float apparition_speed : hint_range(0.1, 4.0) = 0.8;
uniform float trail_strength : hint_range(0.0, 2.0) = 1.4;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.4;

uniform vec4 spirit_color : source_color = vec4(0.8, 1.0, 1.2, 1.0);

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV;
    vec4 base = texture(TEXTURE, uv);

    if (base.a < 0.01) {
        discard;
    }

    float t = TIME;

    // Fade in / out espiritual (aparición)
    float apparition = sin(t * apparition_speed) * 0.5 + 0.5;
    apparition = smoothstep(0.15, 0.85, apparition);

    // Pulso interno
    float pulse = sin(t * pulse_speed + uv.y * 6.0) * 0.5 + 0.5;

    // Distorsión etérea
    float n = noise(uv * 5.0 + vec2(0.0, t));
    vec2 distorted_uv = uv;
    distorted_uv.y -= n * 0.04 * distortion_strength;
    distorted_uv.x += sin(t + uv.y * 5.0) * 0.02 * distortion_strength;

    vec4 flame = texture(TEXTURE, distorted_uv);

    // Estela espiritual (afterimage falso)
    float trail = 0.0;
    for (int i = 1; i <= 4; i++) {
        float offset = float(i) * 0.02;
        trail += texture(TEXTURE, distorted_uv + vec2(0.0, offset)).a / float(i);
    }

    // Color aditivo espiritual
    vec3 color = flame.rgb * spirit_color.rgb;
    color += trail * spirit_color.rgb * 0.8;

    float alpha = flame.a;
    alpha *= apparition;
    alpha *= (0.4 + pulse * 0.6);

    COLOR = vec4(color * alpha, alpha);
}