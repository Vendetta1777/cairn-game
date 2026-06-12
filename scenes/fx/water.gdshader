// Cairn — living water: refracts whatever is behind it with slow rolling
// waves, adds a cold tint, depth-darkening and a moving specular shimmer.
// Used by every WaterZone body (Nave basins, the Library's flooded index).
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec4 tint : source_color = vec4(0.05, 0.14, 0.16, 0.55);
uniform float distort : hint_range(0.0, 0.02) = 0.006;
uniform float shimmer : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 wob = vec2(
		sin(UV.y * 22.0 + TIME * 1.7) + sin(UV.y * 9.0 - TIME * 1.1),
		sin(UV.x * 18.0 + TIME * 1.3)) * distort;
	vec3 behind = texture(screen_tex, SCREEN_UV + wob).rgb;
	// Cold depth tint, heavier toward the bottom.
	vec3 col = mix(behind, tint.rgb, tint.a * (0.6 + UV.y * 0.4));
	// A drifting band of specular shimmer near the surface.
	float band = smoothstep(0.0, 0.16, UV.y) * (1.0 - smoothstep(0.16, 0.5, UV.y));
	float spec = pow(0.5 + 0.5 * sin(UV.x * 60.0 + TIME * 2.4 + sin(UV.x * 13.0)), 6.0);
	col += vec3(0.5, 0.8, 0.8) * spec * band * shimmer;
	COLOR = vec4(col, 1.0);
}
