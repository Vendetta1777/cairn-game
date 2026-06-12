// Cairn — global post-process: subtle radial chromatic aberration + animated
// film grain. One full-screen pass, applied identically to every scene so all
// the mixed art reads as one filmed image. Tuned faint on purpose.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float aberration : hint_range(0.0, 0.02) = 0.003;
uniform float grain : hint_range(0.0, 0.2) = 0.02;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 from_center = uv - vec2(0.5);
	// Aberration grows toward the screen edges, zero at center.
	vec2 off = from_center * aberration * 2.0;
	float r = texture(screen_tex, uv + off).r;
	float g = texture(screen_tex, uv).g;
	float b = texture(screen_tex, uv - off).b;
	vec3 col = vec3(r, g, b);
	// Animated film grain.
	float n = hash(uv * vec2(960.0, 540.0) + vec2(TIME * 61.0, TIME * 83.0)) - 0.5;
	col += n * grain;
	COLOR = vec4(col, 1.0);
}
