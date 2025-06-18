shader_type canvas_item;

uniform sampler2D light_texture;
uniform vec2 light_texture_size = vec2(1.0, 1.0);
uniform float max_alpha = 1.0;

void fragment() {
	vec2 tex_coords = floor(UV * light_texture_size) / light_texture_size;
	float darkness = texture(light_texture, tex_coords).a;

	darkness = clamp(darkness, 0.0, 1.0);
	COLOR = vec4(0.0, 0.0, 0.0, darkness * max_alpha);
}
