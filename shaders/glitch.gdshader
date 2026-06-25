shader_type canvas_item;

uniform float scan_line_jitter : hint_range(0.0, 0.075) = 0.015;
uniform float horizontal_shake : hint_range(0.0, 0.25) = 0.01;
uniform float color_drift : hint_range(0.0, 0.1) = 0.03;

// 1. Added a tint uniform. Defaults to a bright neon/cyberpunk red.
uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
// Controls how strong the red tint is (0.0 = original glitch colors, 1.0 = fully red)
uniform float tint_factor : hint_range(0.0, 1.0) = 0.7;

float nrand(float x, float y) {
    return fract(sin(dot(vec2(x, y), vec2(12.9898, 78.233))) * 43758.5433);
}

void fragment() {
    // Operating directly on the tile's UV space
    float u = UV.x;
    float v = UV.y;

    // Calculate noise based on the global TIME variable
    float jitter = nrand(v, TIME) * 2.0 - 1.0;
    jitter *= step(0.0, abs(jitter)) * scan_line_jitter;
    
    float shake = (nrand(TIME, 2.0) - 0.5) * horizontal_shake;
    float drift = sin(v) * color_drift;

    // We scale the offset down dynamically near the boundaries 
    // to prevent the text from clipping/wrapping inside its tile box
    float edge_damp = smoothstep(0.0, 0.1, u) * smoothstep(1.0, 0.9, u);
    float total_offset = (jitter + shake) * edge_damp;

    // Sample the tile's own texture directly
    vec4 src1 = texture(TEXTURE, vec2(u + total_offset, v));
    vec4 src2 = texture(TEXTURE, vec2(u + total_offset + (drift * edge_damp), v));
    
    // 2. Reconstruct the glitched color base
    vec3 glitch_base = vec3(src1.r, src2.g, src1.b);
    
    // 3. Blend the glitched base with your red tint color based on the tint factor
    vec3 final_color = mix(glitch_base, glitch_base * tint_color.rgb, tint_factor);
    
    // Output the glitched, tinted result
    COLOR = vec4(final_color, src1.a);
}