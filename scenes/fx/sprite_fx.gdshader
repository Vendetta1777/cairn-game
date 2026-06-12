// Cairn — sprite FX shader (player + enemies):
//   flash    — replaces every visible pixel with flash_color (true white hit
//              flash; modulate alone can only darken)
//   dissolve — noise-driven dissolve, eaten upward as `dissolve` rises 0 -> 1
//              (the death sequence; enemy dissipations)
shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Dissolve: pixels vanish bottom-up with a noisy edge; the edge glows.
	if (dissolve > 0.001) {
		float n = hash(floor(UV * 64.0));
		float cut = (1.0 - UV.y) * 0.7 + n * 0.5;
		if (cut < dissolve) {
			tex.a = 0.0;
		} else if (cut < dissolve + 0.08) {
			tex.rgb = vec3(0.7, 0.85, 1.0);
		}
	}
	tex.rgb = mix(tex.rgb, flash_color.rgb, flash * flash_color.a);
	COLOR = tex * COLOR;
}
