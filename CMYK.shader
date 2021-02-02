shader_type canvas_item;

uniform float grid_size  = 2.0;
uniform float blur_level = 0.0;
uniform float dot_size   = 1.0;

uniform bool blob_enabled = false;

uniform bool Cyan    = true;
uniform bool Magenta = true;
uniform bool Yellow  = true;
uniform bool Black   = true;

uniform float angle_cyan    = 15.0;
uniform float angle_magenta = 75.0;
uniform float angle_yellow  =  0.0;
uniform float angle_black   = 45.0;


mat2 rotate2d(float angle) {
	angle = radians(angle);
    return mat2(vec2(cos(angle),-sin(angle)),
                vec2(sin(angle), cos(angle)));
}

float get_color_by_index(int color_index, vec3 RGB) {
	switch (color_index) {
		case 0: return RGB.r;
		case 1: return RGB.g;
		case 2: return RGB.b;
		case 3: return max(RGB.r, max(RGB.g, RGB.b));
		default: return 0.0;
	}
}

float get_angle_by_index(int color_index) {
	switch (color_index) {
		case 0: return angle_cyan;
		case 1: return angle_magenta;
		case 2: return angle_yellow;
		case 3: return angle_black;
		default: return 0.0;
	}
}

vec2 point_to_screen_UV(vec2 point, vec2 current_position, vec2 screen_pixel_size, vec2 fragcoord) {
	vec2 offset_to_point = point - current_position;
	vec2 screen_point = vec2(fragcoord.x + offset_to_point.x, fragcoord.y - offset_to_point.y);

	return screen_point * screen_pixel_size;
}

vec2 get_rotated_grid_cell_center(vec2 position, float deg, vec2 texture_size) {
	vec2 rotated_position = ((position - (texture_size / 2.0)) * rotate2d(deg)) + (texture_size / 2.0);
	vec2 rotated_cell_center = floor(rotated_position / grid_size) * grid_size + vec2(grid_size / 2.0);
	vec2 cell_center = ((rotated_cell_center - (texture_size / 2.0)) * rotate2d(-deg)) + (texture_size / 2.0);

	return cell_center;
}

float get_color_strength(vec2 position, vec2 cell_center, int color_index, sampler2D screen_tex, vec2 screen_pixel_size, vec2 fragcoord) {
	float scaled_dot_size = dot_size * grid_size / 2.0;
	vec3 RGB = textureLod(screen_tex, point_to_screen_UV(cell_center, position, screen_pixel_size, fragcoord), blur_level).rgb;
	float dot_size_in_cell = (scaled_dot_size * (1.0 - get_color_by_index(color_index, RGB)));
	return pow(dot_size_in_cell, 2.0) / pow(distance(position, cell_center), 2.0);
}

float calculate_color(vec2 position, int color_index, sampler2D screen_tex, vec2 screen_pixel_size, vec2 fragcoord, vec2 tex_pixel_size) {
	vec2 cell_center = get_rotated_grid_cell_center(position, get_angle_by_index(color_index), 1.0/tex_pixel_size);
	float accumulator = get_color_strength(position, cell_center, color_index, screen_tex, screen_pixel_size, fragcoord);

	if (blob_enabled) {
		vec2 offset_position_x = vec2(grid_size, 0.0) * rotate2d(-get_angle_by_index(color_index));
		vec2 offset_position_y = vec2(0.0, grid_size) * rotate2d(-get_angle_by_index(color_index));

		accumulator += get_color_strength(position, (cell_center + offset_position_x), color_index, screen_tex, screen_pixel_size, fragcoord);
		accumulator += get_color_strength(position, (cell_center - offset_position_x), color_index, screen_tex, screen_pixel_size, fragcoord);
		accumulator += get_color_strength(position, (cell_center + offset_position_y), color_index, screen_tex, screen_pixel_size, fragcoord);
		accumulator += get_color_strength(position, (cell_center - offset_position_y), color_index, screen_tex, screen_pixel_size, fragcoord);
	}

	return accumulator;
}

void fragment() {
	vec2 position = UV / TEXTURE_PIXEL_SIZE;
	vec3 color = vec3(0.0);

	if (Cyan)    color.r  = smoothstep(0.95, 1.0, calculate_color(position, 0, SCREEN_TEXTURE, SCREEN_PIXEL_SIZE, FRAGCOORD.xy, TEXTURE_PIXEL_SIZE));
	if (Magenta) color.g  = smoothstep(0.95, 1.0, calculate_color(position, 1, SCREEN_TEXTURE, SCREEN_PIXEL_SIZE, FRAGCOORD.xy, TEXTURE_PIXEL_SIZE));
	if (Yellow)  color.b  = smoothstep(0.95, 1.0, calculate_color(position, 2, SCREEN_TEXTURE, SCREEN_PIXEL_SIZE, FRAGCOORD.xy, TEXTURE_PIXEL_SIZE));
	if (Black)   color   += smoothstep(0.95, 1.0, calculate_color(position, 3, SCREEN_TEXTURE, SCREEN_PIXEL_SIZE, FRAGCOORD.xy, TEXTURE_PIXEL_SIZE));

	// Convert to CMYK
	COLOR = vec4(1.0 - color, 1.0);
}
