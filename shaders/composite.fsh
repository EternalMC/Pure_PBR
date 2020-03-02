#version 450 compatibility
#define composite0
#define fsh
#define ShaderStage 0
#include "/lib/Syntax.glsl"
#include "/lib/Utility.glsl"

/*
// TODO: GI(RSM-flux) https://pdfs.semanticscholar.org/1b29/71e7024a3e1c4108718e59b5ba4327c44b93.pdf, 
         AO(GTAO) http://iryoku.com/downloads/Practical-Realtime-Strategies-for-Accurate-Indirect-Occlusion.pdf
*/

/* DRAWBUFFERS:0 */

uniform sampler2D colortex0;

in vec2 texcoord;

layout (location = 0) out vec4 albedo;

#include "/lib/Debug.glsl"

vec3 ProjectEquirectangularImage(vec2 coord) {
	cvec2 coordToLongLat = vec2(2.0 * PI, PI);
	      coord.y -= 0.5;
	vec2 longLat = coord * coordToLongLat;
	float longitude = longLat.x;
	float latitude = longLat.y - (2.0 * PI);

	float cos_lat = cos(latitude);
	float cos_long = cos(longitude);
	float sin_lat = sin(latitude);
	float sin_long = sin(longitude);

	return normalize(vec3(cos_lat * sin_long, sin_lat, cos_lat * cos_long));
}

#include "/program/composite.glsl"

void main() {
    albedo = texture(colortex0, texcoord);

    exit();
}
