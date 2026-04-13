//!HOOK OUTPUT
//!BIND HOOKED
//!DESC Soft rounded corners — video edges fade with smooth rounded termination

vec4 hook() {
    vec2 uv = HOOKED_pos;
    vec2 size = vec2(HOOKED_size);
    vec2 pixel = uv * size;

    // Corner radius and edge feather
    float radius = 60.0;    // how round the corners are (pixels)
    float feather = 40.0;   // how soft the edge fade is (pixels)

    // === ROUNDED RECTANGLE SDF ===
    // Distance from pixel to the nearest point on a rounded rectangle
    vec2 half_size = size * 0.5;
    vec2 center = half_size;
    vec2 d = abs(pixel - center) - half_size + radius;
    float sdf = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;

    // sdf < 0 = inside, sdf > 0 = outside
    // Smooth fade across the feather zone
    float alpha = 1.0 - smoothstep(-feather, 0.0, sdf);

    // === DITHER ===
    float noise = fract(sin(dot(pixel, vec2(12.9898, 78.233))) * 43758.5453);
    float dither = (noise - 0.5) / 255.0;

    vec4 color = HOOKED_tex(uv);
    vec3 dithered = color.rgb + vec3(dither);
    return vec4(dithered * alpha, alpha);
}
