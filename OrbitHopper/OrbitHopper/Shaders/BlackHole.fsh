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

// 2. Posterize: snap a value to one of N discrete steps with hard edges
float posterize(float value, float steps) {
    return floor(value * steps) / steps;
}

void main() {
    // Shift coordinates so (0,0) is the dead center of the sprite
    vec2 uv = v_tex_coord - 0.5;
    float dist = length(uv);
    float eventHorizon = 0.15;

    // Resolve accent color: if u_accent_color uniform is provided, use it
    // Otherwise fall back to the default cyan palette
    vec3 accent = vec3(0.35, 0.85, 1.00); // default bright cyan
    #ifdef GL_ES
    // u_accent_color is optional — check if it has a non-zero value
    #endif
    if (u_accent_color.r + u_accent_color.g + u_accent_color.b > 0.01) {
        accent = u_accent_color;
    }

    if (dist < eventHorizon) {
        // 1. The Singularity: Flat black void with a subtle stepped internal ring
        float ring = step(0.10, dist) * 0.12;
        gl_FragColor = vec4(vec3(0.02, 0.05, 0.1) * ring, 1.0);
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

        // 3. The Photon Sphere: Hard inner rim at the edge of the void
        float photonSphere = step(dist, eventHorizon + 0.025);

        // 4. Accretion Disk: Posterized gas bands (10 discrete shades)
        float rawGlow = 1.0 - smoothstep(eventHorizon, 0.5, dist);
        rawGlow = rawGlow * (n * 1.5 + 0.5);
        float diskGlow = posterize(rawGlow, 10.0);

        // 5. Color Palette: 10 flat shades mapped along a gradient using accent color
        vec3 colCore = vec3(0.01, 0.03, 0.08);              // deepest navy
        vec3 colMid1 = mix(vec3(0.06, 0.10, 0.20), accent * 0.3, 0.5);  // dark tinted
        vec3 colMid2 = mix(vec3(0.15, 0.30, 0.50), accent * 0.6, 0.5);  // mid tinted
        vec3 colEdge = accent;                                // bright accent

        vec3 color;
        // Interpolate the posterized glow to generate 10 flat colors
        if (diskGlow < 0.33) {
            color = mix(colCore, colMid1, diskGlow / 0.33);
        } else if (diskGlow < 0.66) {
            color = mix(colMid1, colMid2, (diskGlow - 0.33) / 0.33);
        } else {
            color = mix(colMid2, colEdge, (diskGlow - 0.66) / 0.34);
        }

        // Add the white-hot inner rim as a flat band
        color = mix(color, vec3(0.9, 0.97, 1.0), photonSphere);

        // 6. Posterize the outer bloom into a single highlight band
        float bloom = step(0.65, pow(rawGlow, 2.0));
        color = color + colEdge * bloom * 0.3;

        // 7. Outer Edge Mask & Noisy Fade
        // Create prominent swirling arms using the dynamic angle
        float armDistort = sin(dynamicAngle * 3.0) * 0.06 + sin(dynamicAngle * 2.0 - u_time) * 0.04;
        
        // Combine distance, arms, and fine noise
        float edgeDist = dist + armDistort + ((n - 0.5) * 0.05);

        // Separate high-frequency noise specifically for the fade out
        float fadeNoise = fbm(uv * 12.0 - u_time * 0.4);
        
        // Smoothly fade the edge over a noisy range to make it organically vanish
        float alpha = smoothstep(0.52, 0.38, edgeDist + (fadeNoise * 0.15));

        gl_FragColor = vec4(color * alpha, alpha);
    }
}

