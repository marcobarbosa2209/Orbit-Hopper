// Nebula.fsh

// 1. Random and Noise functions
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    vec2 shift = vec2(100.0);
    for (int i = 0; i < 6; i++) {
        value += amplitude * noise(st);
        st = st * 2.0 + shift;
        amplitude *= 0.5;
    }
    return value;
}

void main() {
    vec2 uv = v_tex_coord;
    
    // 1. Base Drift: Constant slow movement
    vec2 pos = uv * 4.0 + vec2(u_time * 0.015, u_time * 0.025);
    
    // 2. Camera Parallax: React to ship movement
    pos += u_camera_offset * 0.8;

    // 3. Dynamic Morphing: Layered noise for gas movement
    vec2 dynamicWarp = vec2(
        fbm(pos + vec2(0.0, u_time * 0.05)),
        fbm(pos + vec2(5.2, 1.3) - vec2(u_time * 0.04, 0.0))
    );
    
    float n = fbm(pos + dynamicWarp * 2.0);

    // 4. Space Density: Control cloud vs void ratio
    float dust = pow(n, 6.0);

    // 5. Dynamic Colors: Subtle shifting gas hues
    vec3 dustColorDark = vec3(0.06, 0.09, 0.14);
    vec3 dustColorLight = vec3(
        0.12 + sin(u_time * 0.5) * 0.02,
        0.18 + cos(u_time * 0.3) * 0.02,
        0.25 + sin(u_time * 0.7) * 0.03
    );

    // Mix gas colors based on density
    vec3 gasColor = mix(dustColorDark, dustColorLight, dust * 2.0);

    // 6. Transparency: Faint gas clouds
    float alpha = smoothstep(0.2, 0.7, n) * 0.6;

    // Output with premultiplied alpha
    gl_FragColor = vec4(gasColor * alpha, alpha);
}
