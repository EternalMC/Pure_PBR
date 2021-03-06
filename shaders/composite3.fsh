#version 450 compatibility
#define composite3
#define fsh
#define ShaderStage 3
#include "/lib/Syntax.glsl"
#include "/lib/Settings.glsl"

/*
filtering pass - Reflections, CLOUDS
generation of bloom and aperature shape
https://learnopengl.com/Advanced-Lighting/Bloom
http://ivizlab.sfu.ca/papers/cgf2012.pdf
https://github.com/orthecreedence/ghostie/blob/master/opengl/glsl/dof.bokeh.2.4.frag
*/

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

in vec2 texcoord;

layout (location = 0) out vec4 albedo;

#include "/lib/Debug.glsl"

//Code

void main() {
    albedo = texture(colortex0, texcoord);

    exit();
}
