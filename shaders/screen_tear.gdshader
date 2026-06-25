shader_type canvas_item;

// Grabs the game screen behind the ColorRect
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// Global intensity multiplier
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.5;

// Simple generator to create pseudo-random noise
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// 1D noise for temporal randomness
float noise(float x) {
    return fract(sin(x * 12345.67) * 45678.91);
}

void fragment() {
    vec2 uv = SCREEN_UV;

    // 1. Create a chaotic time variable that stutters
    float time_step = floor(TIME * 15.0); // Adjust '15.0' to change how rapidly the glitch updates

    // 2. Determine if a glitch should happen at all at this moment
    // This creates "bursts" of tearing instead of a constant effect
    float glitch_threshold = step(0.6, rand(vec2(time_step, 123.4)));

    if (glitch_threshold > 0.0) {
        // 3. Generate randomized horizontal bands
        // This splits the screen into random shifting bars vertically
        float block_noise = rand(vec2(time_step, floor(uv.y * 10.0 * rand(vec2(time_step, 4.5)))));

        // 4. Determine line-level tearing intensity
        // This creates highly localized, unpredictable microscopic tears
        float line_noise = rand(vec2(time_step, uv.y));

        // 5. Combine them for the final offset calculation
        // We only tear if the random noise crosses a certain threshold per line
        float tear_mask = step(0.85 - (glitch_intensity * 0.2), line_noise);

        // Randomize the direction and strength of the tear (left or right)
        float tear_direction = (rand(vec2(time_step, uv.y * 2.0)) - 0.5) * 2.0;

        // Apply the chaotic displacement to the X coordinate
        // Mixes big block shifts with sharp line tears
        float displacement = (block_noise * 0.015 + tear_direction * 0.03) * glitch_intensity * tear_mask;
        uv.x += displacement;
    }

    // 6. Sample the screen texture with the distorted UVs
    COLOR = texture(screen_texture, uv);
}