shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

/* Base colors */
uniform vec4 wood_color_light : source_color = vec4(0.63,0.35,0.14,1.0);
uniform vec4 wood_color_dark : source_color = vec4(0.32,0.16,0.07,1.0);

/* Grain control */
uniform float grain_scale = 14.0;
uniform float ring_scale = 4.0;

/* Surface properties */
uniform float roughness_min = 0.45;
uniform float roughness_max = 0.75;
uniform float bump_strength = 0.25;

/* Wear amount on edges */
uniform float wear_amount = 0.35;


/* Hash function */
/* Generates deterministic pseudo random numbers */
float hash(vec2 p){
    return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453);
}


/* Smooth value noise */
float noise(vec2 p){

    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0,0.0));
    float c = hash(i + vec2(0.0,1.0));
    float d = hash(i + vec2(1.0,1.0));

    vec2 u = f*f*(3.0-2.0*f);

    return mix(a,b,u.x) +
           (c-a)*u.y*(1.0-u.x) +
           (d-b)*u.x*u.y;
}


/* Fractal Brownian Motion */
/* Combines multiple noise layers for natural detail */
float fbm(vec2 p){

    float value = 0.0;
    float amplitude = 0.5;

    for(int i=0;i<5;i++){

        value += noise(p) * amplitude;

        p *= 2.0;
        amplitude *= 0.5;

    }

    return value;
}


/* Generates wood rings */
float wood_rings(vec2 uv){

    float n = fbm(uv * grain_scale);

    float rings = sin((uv.y + n*0.6) * grain_scale * ring_scale);

    return rings * 0.5 + 0.5;
}


/* Height function used for bump mapping */
float height_map(vec2 uv){

    float rings = wood_rings(uv);
    float fine = fbm(uv * 40.0);

    return rings * 0.8 + fine * 0.2;
}


void fragment(){

    vec2 uv = UV;

    /* Base wood pattern */
    float rings = wood_rings(uv);

    /* Color interpolation */
    vec3 wood_color = mix(
        wood_color_dark.rgb,
        wood_color_light.rgb,
        rings
    );

    /* Subtle color noise */
    float color_noise = fbm(uv * 10.0) * 0.1;

    wood_color += color_noise;

    /* Height-based bump mapping */
    float h = height_map(uv);

    float hx = height_map(uv + vec2(0.002,0.0));
    float hy = height_map(uv + vec2(0.0,0.002));

    vec3 normal = normalize(vec3(
        (h - hx) * bump_strength,
        (h - hy) * bump_strength,
        1.0
    ));

    NORMAL = normal;

    /* Edge wear approximation */
    float edge = pow(abs(dot(NORMAL, VIEW)),2.0);

    wood_color += edge * wear_amount * 0.15;

    /* Roughness variation */
    float roughness_noise = fbm(uv * 8.0);

    ROUGHNESS = mix(
        roughness_min,
        roughness_max,
        roughness_noise
    );

    ALBEDO = wood_color;
}