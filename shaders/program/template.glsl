
#version 450 compatibility
#define program name ie composite
#define fsh / vsh
#define ShaderStage ie -1 0 1 2 
#include "/lib/Settings.glsl"
#include "/lib/Syntax.glsl"
#include "/lib/Settings.glsl"

// TODOs go here and notes

/* DRAWBUFFERS:0 */ // drawbuffers

// uniforms
uniform sampler2D colortex0;
uniform sampler2D colortex1;

// in out
in vec2 texcoord;

// fragdata layout (  layout (location = (0/1/2)) out vec4 (name of fragdata);  )
layout (location = 0) out vec4 albedo;

// Debug
#include "/lib/Debug.glsl"

void main() {
    albedo = texture(colortex0, texcoord);
    
    exit();
}
