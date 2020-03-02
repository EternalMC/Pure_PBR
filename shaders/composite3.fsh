#version 450 compatibility
#define composite3
#define fsh
#define ShaderStage 3
#include "/lib/Syntax.glsl"
#include "/lib/Settings.glsl"

/*
filtering pass - Reflections, CLOUDS
generation of bloom and aperature shape
*/

uniform sampler2D colortex0;

in vec2 texcoord;

layout (location = 0) out vec4 albedo;

#include "/lib/Debug.glsl"

void main() {
    albedo = texture(colortex0, texcoord);

    exit();
}
