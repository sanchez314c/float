//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Ethereal vignette — video dissolves from center outward with rounded fade

vec4 hook() {
    vec2 uv = HOOKED_pos;
    vec2 size = vec2(HOOKED_size);
    vec2 pixel = uv * size;
    vec2 center = size * 0.5;

    // Normalize pixel position to -1..1 range from center
    vec2 npos = (pixel - center) / center;

    // Rounded rectangle SDF — gives smooth distance to a rounded rect boundary
    vec2 box_size = vec2(0.65, 0.65);
    float corner_radius = 0.35;

    vec2 d = abs(npos) - box_size + corner_radius;
    float sdf = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - corner_radius;

    float fade_width = 0.35;
    float alpha = 1.0 - smoothstep(0.0, fade_width, sdf);
    alpha = alpha * alpha;

    float noise = fract(sin(dot(pixel, vec2(12.9898, 78.233))) * 43758.5453);
    float dither = (noise - 0.5) * 0.02 * (1.0 - alpha);
    alpha = clamp(alpha + dither, 0.0, 1.0);

    vec4 color = HOOKED_tex(uv);
    return vec4(color.rgb * alpha, alpha);
}
