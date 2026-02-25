shader_type canvas_item;

uniform float time : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 offset = vec2(sin(UV.y * 20.0 + TIME * 10.0) * 0.005, 0.0);
	COLOR = texture(TEXTURE, UV + offset) * COLOR;
}