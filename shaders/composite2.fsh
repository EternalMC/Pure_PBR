#version 450 compatibility
#define composite2
#define fsh
#define ShaderStage 2
#include "/lib/Syntax.glsl"
#include "/lib/Settings.glsl"

//Adjustable variables. Tune these for performance
#define MAX_RAY_STEPS           30
#define RAY_STEP_LENGTH         0.1
#define RAY_DEPTH_BIAS          0.05
#define RAY_GROWTH              1.05
#define NUM_RAYS                1  // [1 2 4 8 16 32]
#define NUM_BOUNCES             2

/*
    sky - frostbite from spheremap
    clouds - frostbite
    raytracing - https://casual-effects.blogspot.com/2014/08/screen-space-ray-tracing.html
    brdf - gotanda F - frostbite correlated ggx smith V - ggx D
*/

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

uniform sampler2D gdepthtex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform float viewWidth;
uniform float viewHeight;

uniform float frameTime;
uniform float frameTimeCounter;

in vec2 texcoord;
in mat4 cur_pos_to_last_frame_pos;

layout (location = 0) out vec4 albedo;
layout (location = 2) out vec4 previousAlbedo;

#include "/lib/Debug.glsl"
#include "/lib/Utility.glsl"

#line 47

struct Fragment {
    vec3 position;
    vec3 color;
    vec3 normal;
    vec3 specular_color;
    bool skipLighting;
    bool is_sky;
    float metalness;
    float smoothness;
};

struct HitInfo {
    vec3 position;
    vec2 coord;
};

vec3 get_viewspace_position(in vec2 uv) {
    float depth = texture2D(gdepthtex, uv).x;
    vec4 position = gbufferProjectionInverse * vec4(uv.s * 2.0 - 1.0, uv.t * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    return position.xyz / position.w;
}

vec2 get_coord_from_viewspace(in vec4 position) {
    vec4 ndc_position = gbufferProjection * position;
    ndc_position /= ndc_position.w;
    return ndc_position.xy * 0.5 + 0.5;
}

Fragment fill_frag_struct(in vec2 coord) {
    vec4 color_tex_sample = texture2D(colortex0, coord);
    vec4 normal_tex_sample = texture2D(colortex1, coord);
    //vec4 gaux2_sample = texture2D(gaux2, coord);
    //vec4 gaux3_sample = texture2D(gaux3, coord);

    Fragment pixel;
    pixel.position          = get_viewspace_position(coord);
    pixel.normal            = normal_tex_sample.xyz;
    pixel.color             = color_tex_sample.rgb;
    //pixel.metalness         = gaux2_sample.b;
    //pixel.smoothness        = pow(gaux2_sample.a, 2.2);
    //pixel.skipLighting      = gaux2_sample.r > 0.5;
    //pixel.specular_color    = mix(vec3(0.14), color_tex_sample.rgb, vec3(pixel.metalness));
    //pixel.is_sky            = gaux3_sample.g > 0.5;

    return pixel;
}

float calculateDitherPattern() {
    const int[64] ditherPattern = int[64] ( 1, 49, 13, 61,  4, 52, 16, 64,
                                           33, 17, 45, 29, 36, 20, 48, 32,
                                            9, 57,  5, 53, 12, 60,  8, 56,
                                           41, 25, 37, 21, 44, 28, 40, 24,
                                            3, 51, 15, 63,  2, 50, 14, 62,
                                           35, 19, 47, 31, 34, 18, 46, 30,
                                           11, 59,  7, 55, 10, 58,  6, 54,
                                           43, 27, 39, 23, 42, 26, 38, 22);

    vec2 count = vec2(0.0f);
         count.x = floor(mod(texcoord.s * viewWidth, 8.0f));
         count.y = floor(mod(texcoord.t * viewHeight, 8.0f));

    int dither = ditherPattern[int(count.x) + int(count.y) * 8];

    return float(dither) / 64.0f;
}

//Determines the UV coordinate where the ray hits
//If the returned value is not in the range [0, 1] then nothing was hit.
//NOTHING!
//Note that origin and direction are assumed to be in screen-space coordinates, such that
//  -origin.st is the texture coordinate of the ray's origin
//  -direction.st is of such a length that it moves the equivalent of one texel
//  -both origin.z and direction.z correspond to values raw from the depth buffer
bool cast_screenspace_ray(in vec3 origin, in vec3 direction, inout HitInfo hit_info) {
    vec3 curPos = origin;
    vec2 curCoord = get_coord_from_viewspace(vec4(curPos, 1));
    direction = normalize(direction) * RAY_STEP_LENGTH;
    #ifdef DITHER_REFLECTION_RAYS
        direction *= mix(0.75, 1.0, calculateDitherPattern());
    #endif
    bool forward = true;
    bool can_collect = true;

    //The basic idea here is the the ray goes forward until it's behind something,
    //then slowly moves forward until it's in front of something.
    for(int i = 0; i < MAX_RAY_STEPS; i++) {
        curPos += direction;
        curCoord = get_coord_from_viewspace(vec4(curPos, 1));
        if(curCoord.x < 0 || curCoord.x > 1 || curCoord.y < 0 || curCoord.y > 1) {
            //If we're here, the ray has gone off-screen so we can't reflect anything
            return false;
        }

        vec3 worldDepth = get_viewspace_position(curCoord);
        float depthDiff = (worldDepth.z - curPos.z);
        float maxDepthDiff = sqrt(dot(direction, direction)) + RAY_DEPTH_BIAS;

        if(depthDiff > 0 && depthDiff < maxDepthDiff) {
            vec3 travelled = origin - curPos;
            hit_info.position = curPos;
            hit_info.coord = curCoord;

            // If we hit an emissive surface, we should stop tracing rays
            // No emission yet
            return true;//get_emission(curCoord) < 0.5;
        }
        direction *= RAY_GROWTH;
    }
    //If we're here, we couldn't find anything to reflect within the alloted number of steps
    return false;
}

float noise(in vec2 coord) {
    return fract(sin(dot(coord, vec2(12.8989, 78.233))) * 43758.5453);
}

vec3 doLightBounce(in Fragment pixel) {
    //Find where the ray hits
    //get the blur at that point
    //mix with the color
    vec3 retColor = vec3(0);
    vec3 hitColor = vec3(0);

    //trace the number of rays defined previously
    for(int i = 0; i < NUM_RAYS; i++) {
        vec3 ray_color = pixel.color;
        vec3 rayDir = normalize(pixel.position);
        HitInfo hit_info;
        hit_info.position = pixel.position;
        hit_info.coord = texcoord;

        Fragment origin_frag = fill_frag_struct(texcoord);

        for(int b = 0; b < NUM_BOUNCES; b++) {
            vec3 sample_normal = origin_frag.normal;

            vec2 noise_seed = texcoord * (i + 1) + (b + 1) * frameTimeCounter;
            vec3 noiseSample = vec3(noise(noise_seed * 4), noise(noise_seed * 3), noise(noise_seed * 23)) * 2.0 - 1.0;
            vec3 reflectDir = normalize(noiseSample + sample_normal);
            reflectDir *= sign(dot(sample_normal, reflectDir));

            if(origin_frag.metalness > 0.5) {
                rayDir = reflect(rayDir, reflectDir);
                ray_color *= origin_frag.specular_color;
            } else {
                rayDir = reflectDir;
            }

            if(dot(rayDir, sample_normal) < 0.1) {
                rayDir += sample_normal;
                rayDir = normalize(rayDir);
            }

            float ndotl = max(0, dot(rayDir, origin_frag.normal));
            ray_color *= ndotl;

            if(!cast_screenspace_ray(hit_info.position, rayDir, hit_info)) {
                //if(get_emission(hit_info.coord) > 0.5) {
                    //ray_color *= get_color(hit_info.coord) * 5000;
                //} else {
                   // ray_color *= luma(get_sky_color(rayDir)) * get_sky_brightness(hit_info.coord) * 1.5;
                //}
                break;
            }

            Fragment hit_frag = fill_frag_struct(hit_info.coord);
            ray_color *= hit_frag.color;

            origin_frag = hit_frag;
        }

        retColor += ray_color;
    }

    return retColor / NUM_RAYS;
}

vec3 intersect_with_sphere(vec3 center, float radius, vec3 original_color) {
    return vec3(0);
}

vec3 get_previous_color(vec2 coord) {
    float depth = texture2D(gdepthtex, coord).x;
    vec2 ndc_pos = coord * 2.0 - 1.0;
    vec4 frag_pos = gbufferProjectionInverse * vec4(ndc_pos, depth * 2.0 - 1.0, 1.0);
    frag_pos /= frag_pos.w;

    vec4 previous_frag_pos = cur_pos_to_last_frame_pos * frag_pos;
    previous_frag_pos /= previous_frag_pos.w;
    previous_frag_pos.st = previous_frag_pos.st * 0.5 + 0.5;

    vec3 previous_color = texture2D(colortex2, previous_frag_pos.st).rgb;

    return previous_color;
}

void main() {
    Fragment pixel = fill_frag_struct(texcoord);
    vec3 reflectedColor = pixel.color;

    if(!pixel.skipLighting) {
        reflectedColor = doLightBounce(pixel).rgb;

        //reflectedColor = intersect_with_sphere(vec3(6), 0.5f);

    } else if(pixel.is_sky) {
        //reflectedColor = get_sky_color(pixel.position) * 0.5;
    } else {
        reflectedColor *= 850; // For emissive blocks
    }

    vec3 previous_color = get_previous_color(texcoord);

    vec3 color = mix(reflectedColor, previous_color, 0.8);

    albedo = vec4(color, 1);
    previousAlbedo = vec4(color, 1);

    exit();
}
