// Cairn — the global post pass: ONE shader, five effects, all uniforms so each
// area can tune its own look:
//   film grain (animated) · radial chromatic aberration · vignette ·
//   scanline flicker · colour grade (desaturate, shadows to blue-black,
//   highlights toward ivory).
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float grain : hint_range(0.0, 0.2) = 0.018;
uniform float aberration : hint_range(0.0, 0.02) = 0.004;
uniform float vignette_radius : hint_range(0.1, 1.5) = 0.75;
uniform float vignette_feather : hint_range(0.01, 1.0) = 0.3;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55;
uniform float scanline : hint_range(0.0, 0.2) = 0.03;
uniform float desaturate : hint_range(0.0, 1.0) = 0.12;
uniform vec3 shadow_tint = vec3(0.04, 0.05, 0.09);
uniform vec3 highlight_tint = vec3(1.04, 1.03, 0.98);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 fc = uv - vec2(0.5);
	// Chromatic aberration, growing toward the edges.
	vec2 off = fc * aberration * 2.0;
	vec3 col = vec3(
		texture(screen_tex, uv + off).r,
		texture(screen_tex, uv).g,
		texture(screen_tex, uv - off).b);
	// Colour grade: desaturate a touch, pull shadows blue-black, lift
	// highlights toward ivory.
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(luma), desaturate);
	col = mix(col + shadow_tint * (1.0 - luma) * 0.35, col * highlight_tint,
		smoothstep(0.25, 0.85, luma));
	// Scanline flicker — barely there.
	float line = sin(uv.y * 540.0 * 3.14159) * 0.5 + 0.5;
	col *= 1.0 - scanline * line * (0.85 + 0.15 * sin(TIME * 9.0));
	// Film grain, reseeded every frame.
	float n = hash(uv * vec2(960.0, 540.0) + vec2(TIME * 61.0, TIME * 83.0)) - 0.5;
	col += n * grain;
	// Vignette.
	float d = length(fc) / 0.7071;
	float vig = smoothstep(vignette_radius, vignette_radius + vignette_feather, d);
	col *= 1.0 - vig * vignette_strength;
	COLOR = vec4(col, 1.0);
}
