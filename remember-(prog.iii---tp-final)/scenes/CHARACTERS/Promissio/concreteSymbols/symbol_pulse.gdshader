shader_type canvas_item;
render_mode unshaded;

uniform float pulse_speed : hint_range(0.1, 4.0) = 0.9;
uniform float wave_speed : hint_range(0.1, 4.0) = 1.2;
uniform float wave_strength : hint_range(0.0, 1.0) = 0.35;
uniform float trail_strength : hint_range(0.0, 2.0) = 1.3;
uniform float apparition_speed : hint_range(0.1, 2.0) = 0.6;

uniform vec4 spirit_color : source_color = vec4(0.4, 0.7, 1.3, 1.0);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5);

    vec4 base = texture(TEXTURE, uv);
    if (base.a < 0.01) discard;

    float t = TIME;

    // Vector radial desde el centro
    vec2 dir = uv - center;
    float dist = length(dir);

    // Pulso espiritual (fade in / out)
    float apparition = sin(t * apparition_speed) * 0.5 + 0.5;
    apparition = smoothstep(0.2, 0.85, apparition);

    // Ondas de energía hacia afuera
    float wave =
        sin(dist * 20.0 - t * wave_speed) * 0.5 + 0.5;

    // Vibración irregular
    float jitter = hash(uv * 20.0 + t) * 0.02;

    // Distorsión UV hacia afuera
    vec2 distorted_uv = uv + normalize(dir) * wave * wave_strength * 0.03;
    distorted_uv += normalize(dir) * jitter;

    vec4 flame = texture(TEXTURE, distorted_uv);

    // Estelas espirituales (afterimage fake)
    float trail = 0.0;
    for (int i = 1; i <= 4; i++) {
        float offset = float(i) * 0.025;
        vec2 trail_uv = distorted_uv + normalize(dir) * offset;
        trail += texture(TEXTURE, trail_uv).a / float(i);
    }

    vec3 color = spirit_color.rgb;
    color *= flame.a + trail * trail_strength;

    float alpha = flame.a;
    alpha *= apparition;
    alpha *= (0.6 + wave * 0.6);

    // Color aditivo puro
    COLOR = vec4(color * alpha, alpha);
}
