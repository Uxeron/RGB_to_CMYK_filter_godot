shader_type canvas_item;

uniform float grid_size = 2.0;
uniform float blur_level = 0.0;
uniform float dot_size = 1.0;

const vec3 Cyan = vec3(0.0, 1.0, 1.0);
const vec3 Magenta = vec3(1.0, 0.0, 1.0);
const vec3 Yellow = vec3(1.0, 1.0, 0.0);
const vec3 Black = vec3(0.0, 0.0, 0.0);
const vec3 None = vec3(1.0);

mat2 rotate2d(float _angle){
    return mat2(vec2(cos(_angle),-sin(_angle)),
                vec2(sin(_angle),cos(_angle)));
}

vec2 point_to_screen_UV(vec2 point, vec2 current_position, vec2 scr_pixel_size, vec2 fragcoord) {
	vec2 offset_to_point = point - current_position;
	vec2 screen_point = vec2(fragcoord.x + offset_to_point.x, fragcoord.y - offset_to_point.y);
	
	return screen_point * scr_pixel_size;
}

vec2 get_rotated_grid_cell_center(vec2 position, float deg, vec2 texture_size) {
	vec2 rotated_position = ((position - (texture_size / 2.0)) * rotate2d(radians(deg))) + (texture_size / 2.0);
	vec2 rotated_cell_center = floor(rotated_position / grid_size) * grid_size + vec2(grid_size / 2.0);
	vec2 cell_center = ((rotated_cell_center - (texture_size / 2.0)) * rotate2d(radians(-deg))) + (texture_size / 2.0);
	
	return cell_center;
}

vec3 CMYK(vec2 position, vec2 texture_size, vec2 screen_pixel_size, sampler2D screen_texture, vec2 fragcoord) {
	vec3 color = None;
	float scaled_dot_size = dot_size * grid_size / 2.0;
	
	vec2 cell_center = get_rotated_grid_cell_center(position, 15.0, texture_size);
	vec3 RGB = textureLod(screen_texture, point_to_screen_UV(cell_center, position, screen_pixel_size, fragcoord), blur_level).rgb;
	float C = 1.0 - RGB.r;
	
	if (distance(position, cell_center) < (scaled_dot_size * C)) {
		color = mix(Cyan, color, 0.2);
	}
	
	cell_center = get_rotated_grid_cell_center(position, 75.0, texture_size);
	RGB = textureLod(screen_texture, point_to_screen_UV(cell_center, position, screen_pixel_size, fragcoord), blur_level).rgb;
	float M = 1.0 - RGB.g;

	if (distance(position, cell_center) < (scaled_dot_size * M)) {
		color = mix(Magenta, color, 0.1);
	}
	
	cell_center = get_rotated_grid_cell_center(position, 0.0, texture_size);
	RGB = textureLod(screen_texture, point_to_screen_UV(cell_center, position, screen_pixel_size, fragcoord), blur_level).rgb;
	float Y = 1.0 - RGB.b;
	
	if (distance(position, cell_center) < (scaled_dot_size * Y)) {
		color = mix(Yellow, color, 0.4);
	}
	
	cell_center = get_rotated_grid_cell_center(position, 45.0, texture_size);
	RGB = textureLod(screen_texture, point_to_screen_UV(cell_center, position, screen_pixel_size, fragcoord), blur_level).rgb;
	float K = 1.0 - max(RGB.r, max(RGB.g, RGB.b));
	
	if (distance(position, cell_center) < (scaled_dot_size * K)) {
		color = mix(Black, color, 0.02);
	}
	
	return color;
}

void fragment() {
	vec2 position = UV / TEXTURE_PIXEL_SIZE;

	COLOR = vec4(CMYK(position, 1.0/TEXTURE_PIXEL_SIZE, SCREEN_PIXEL_SIZE, SCREEN_TEXTURE, FRAGCOORD.xy), 1.0);
}