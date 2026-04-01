shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

/* Base colors */
uniform vec4 cardboard_light : source_color = vec4(0.80,0.66,0.40,1.0);
uniform vec4 cardboard_dark  : source_color = vec4(0.55,0.42,0.24,1.0);


/* Dirt */
uniform float dirt_strength = 0.2;

/* Surface */
uniform float roughness_min = 0.7;
uniform float roughness_max = 0.95;

/* Edge darkening */
uniform float edge_strength = 0.8;
uniform float edge_power = 3.0;

/* Pass world position to fragment */
varying vec3 world_pos;


/* Vertex shader */
void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
}


/* Hash */
float hash(vec3 p){
    return fract(sin(dot(p ,vec3(127.1,311.7,191.999))) * 43758.5453);
}


/* Noise */
float noise(vec3 p){

    vec3 i = floor(p);
    vec3 f = fract(p);

    float n000 = hash(i);
    float n100 = hash(i + vec3(1,0,0));
    float n010 = hash(i + vec3(0,1,0));
    float n110 = hash(i + vec3(1,1,0));

    float n001 = hash(i + vec3(0,0,1));
    float n101 = hash(i + vec3(1,0,1));
    float n011 = hash(i + vec3(0,1,1));
    float n111 = hash(i + vec3(1,1,1));

    vec3 u = f*f*(3.0-2.0*f);

    float nxy0 = mix(
        mix(n000,n100,u.x),
        mix(n010,n110,u.x),
        u.y
    );

    float nxy1 = mix(
        mix(n001,n101,u.x),
        mix(n011,n111,u.x),
        u.y
    );

    return mix(nxy0,nxy1,u.z);
}


/* Fractal noise */
float fbm(vec3 p){

    float v = 0.0;
    float a = 0.5;

    for(int i=0;i<5;i++){
        v += noise(p) * a;
        p *= 2.0;
        a *= 0.5;
    }

    return v;
}


void fragment(){

    vec3 world = world_pos;

    /* Fiber pattern */
    float fibers = fbm(world * 3.0);

    vec3 base_color = mix(
        cardboard_dark.rgb,
        cardboard_light.rgb,
        fibers
    );

    /* Dirt */
    float dirt = fbm(world * 2.0 + 5.0);
    base_color -= dirt * dirt_strength;

    /* Edge darkening based on normal curvature (not camera) */
    // Calculate simple edge factor using normal differences (approx)
    float edge = 1.0 - pow(abs(NORMAL.x) * abs(NORMAL.y) * abs(NORMAL.z) * 8.0, edge_power);
    edge = clamp(edge, 0.0, 1.0);

    // Darken edges
    base_color = mix(base_color, vec3(0.02,0.02,0.02), edge * edge_strength);

    /* Roughness */
    float r = fbm(world * 4.0);
    ROUGHNESS = mix(
        roughness_min,
        roughness_max,
        r
    );

    ALBEDO = base_color;
}