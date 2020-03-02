/*
Get some hot motion blur along with some dank tonemapping
https://github.com/iryoku/smaa
*/

#version 450 compatibility
#define final
#define fsh
#define ShaderStage 7
#include "/lib/Syntax.glsl"
#include "/lib/Utility.glsl"

uniform sampler2D colortex0;

in vec2 texcoord;

out vec4 finalColor;

#include "/lib/Debug.glsl"

#include "/lib/final/tonemap.glsl"

void main() {
    finalColor = texture(colortex0, texcoord);
    finalColor = vec4(L2sRGB(finalColor.rgb), finalColor.a);

    exit();
}
