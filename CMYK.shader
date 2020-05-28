shader_type canvas_item;

uniform float grid_size = 2.0;
uniform float blur_level = 0.0;
uniform float dot_size = 1.0;

uniform bool Cyan = true;
uniform bool Magenta = true;
uniform bool Yellow = true;
uniform bool Black = true;

uniform float angle_cyan    = 15.0;
uniform float angle_magenta = 75.0;
uniform float angle_yellow  =  0.0;
uniform float angle_black   = 45.0;


mat2 rotate2d(float angle){
    return mat2(vec2(cos(angle),-sin(angle)),
                vec2(sin(angle), cos(angle)));
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

void fragment() {
	vec2 position = UV / TEXTURE_PIXEL_SIZE;
	
	COLOR = vec4(0.0);
	float scaled_dot_size = dot_size * grid_size / 2.0;
	
	vec2 cell_center;
	vec3 RGB;
	
	if (Cyan) {
		cell_center = get_rotated_grid_cell_center(position, angle_cyan, 1.0/TEXTURE_PIXEL_SIZE);
		RGB = textureLod(SCREEN_TEXTURE, point_to_screen_UV(cell_center, position, SCREEN_PIXEL_SIZE, FRAGCOORD.xy), blur_level).rgb;
		if (distance(position, cell_center) < (scaled_dot_size * (1.0 - RGB.r))) {
			COLOR.r = 1.0;
		}
	}
	
	if (Magenta) {
		cell_center = get_rotated_grid_cell_center(position, angle_magenta, 1.0/TEXTURE_PIXEL_SIZE);
		RGB = textureLod(SCREEN_TEXTURE, point_to_screen_UV(cell_center, position, SCREEN_PIXEL_SIZE, FRAGCOORD.xy), blur_level).rgb;
		if (distance(position, cell_center) < (scaled_dot_size * (1.0 - RGB.g))) {
			COLOR.g = 1.0;
		}
	}
	
	if (Yellow) {
		cell_center = get_rotated_grid_cell_center(position, angle_yellow, 1.0/TEXTURE_PIXEL_SIZE);
		RGB = textureLod(SCREEN_TEXTURE, point_to_screen_UV(cell_center, position, SCREEN_PIXEL_SIZE, FRAGCOORD.xy), blur_level).rgb;
		if (distance(position, cell_center) < (scaled_dot_size * (1.0 - RGB.b))) {
			COLOR.b = 1.0;
		}
	}
	
	if (Black) {
		cell_center = get_rotated_grid_cell_center(position, angle_black, 1.0/TEXTURE_PIXEL_SIZE);
		RGB = textureLod(SCREEN_TEXTURE, point_to_screen_UV(cell_center, position, SCREEN_PIXEL_SIZE, FRAGCOORD.xy), blur_level).rgb;
		if (distance(position, cell_center) < (scaled_dot_size * (1.0 - max(RGB.r, max(RGB.g, RGB.b))))) {
			COLOR.rgb = vec3(1.0);
		}
	}
	
	// Convert to CMYK
	COLOR = vec4(1.0 - COLOR.rgb, 1.0);
}