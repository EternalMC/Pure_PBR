#version 450 compatibility
#define composite4
#define fsh
#define ShaderStage 4
#include "/lib/Syntax.glsl"
#include "/lib/Settings.glsl"

/*
Whoop whoop, compile camera aperature iso and exposure.
https://placeholderart.wordpress.com/2014/11/21/implementing-a-physically-based-camera-manual-exposure/  hope the website doesnt get removed 
finalize image with dof
*/

uniform sampler2D colortex0;

in vec2 texcoord;

layout (location = 0) out vec4 albedo;

#include "/lib/Debug.glsl"

void main() {
    albedo = texture(colortex0, texcoord);

    exit();
}
