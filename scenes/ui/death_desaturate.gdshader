// Cairn — death desaturation. Pulls the whole screen toward cold grey as the
// player dies; amount is animated 0 -> 1 by DeathScreen.gd.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(screen_tex, SCREEN_UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	// Not pure grey: a faint cold cast so it still feels like Cairn.
	vec3 grey = vec3(g) * vec3(0.92, 0.96, 1.05);
	COLOR = vec4(mix(c.rgb, grey, amount), 1.0);
}
