// BlackHole.fsh

// 1. Random and Noise functions
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
        value = value + amplitude * noise(st);
        st = st * 2.0;
        amplitude = amplitude * 0.5;
    }
    return value;
}

void main() {
    // Shift coordinates so (0,0) is the dead center of the sprite
    vec2 uv = v_tex_coord - 0.5;
    float dist = length(uv);
    float eventHorizon = 0.15;

    if (dist < eventHorizon) {
        // 1. The Singularity: Subtle internal gradient for depth
        float internalGlow = smoothstep(eventHorizon, 0.0, dist) * 0.15;
        gl_FragColor = vec4(vec3(0.02, 0.05, 0.1) * internalGlow, 1.0);
    } else {
        // 2. Seamless Coordinates: Map angle to noise space for smooth wrapping
        float angle = atan(uv.y, uv.x);
        
        // Swirl intensity increases near the center
        float swirl = 2.0 / (dist + 0.05);
        float dynamicAngle = angle + swirl + u_time * 0.8;
        
        // Use Trig for 100% seamless wrap
        vec2 noiseUV = vec2(cos(dynamicAngle), sin(dynamicAngle)) * 1.5;
        
        // Mix with radial distance for movement
        noiseUV = noiseUV + vec2(dist * 4.0 - u_time * 0.3);
        
        float n = fbm(noiseUV);

        // 3. The Photon Sphere: Bright inner rim at the edge of the void
        float photonSphere = smoothstep(eventHorizon + 0.03, eventHorizon, dist);
        
        // 4. Accretion Disk Glow: Flickering gas clouds
        float diskGlow = 1.0 - smoothstep(eventHorizon, 0.5, dist);
        diskGlow = diskGlow * (n * 1.5 + 0.5);

        // 5. Colors & Composition: Electric Blue to Deep Navy
        vec3 coreColor = vec3(0.3, 0.8, 1.0);
        vec3 midColor = vec3(0.1, 0.4, 0.8);
        vec3 edgeColor = vec3(0.02, 0.05, 0.15);
        
        vec3 color = mix(edgeColor, midColor, diskGlow);
        color = mix(color, coreColor, diskGlow * diskGlow);
        
        // Add the white-hot inner rim
        color = mix(color, vec3(1.0, 1.0, 1.0), photonSphere * 0.9);
        
        // Add extra brightness (bloom) near the horizon
        float bloom = pow(diskGlow, 3.0) * 1.2;
        color = color + coreColor * bloom;

        // 6. Circular Mask
        float alpha = 1.0 - smoothstep(0.46, 0.5, dist);
        
        gl_FragColor = vec4(color * alpha, alpha);
    }
}
