#version 450 compatibility
#define composite1
#define fsh
#define ShaderStage 1
#include "/lib/Syntax.glsl"

/* TODO, shading, 
         diffuse(burley fitted - http://www.frostbite.com/wp-content/uploads/2014/11/course_notes_moving_frostbite_to_pbr.pdf - page 11
                 gotanda - http://research.tri-ace.com/Data/DesignReflectanceModel_notes.pdf, 
                 oren nayar - http://blog.selfshadow.com/publications/s2012-shading-course/gotanda/s2012_pbs_beyond_blinn_notes_v3.pdf
                 Sub Surface - http://www.iryoku.com/separable-sss/downloads/Separable-Subsurface-Scattering.pdf

         sky - frostbite
         envMap - cloud approx, sky, rendered ground, if inside turn 0.5
         filtering - AO(GTAO), GI(BILAT)
         color rendered to correct values of radiance
https://github.com/wdas/brdf

*/

/* DRAWBUFFERS:0 */

uniform sampler2D colortex0;

in vec2 texcoord;

layout (location = 0) out vec3 albedo;

void main() {
    albedo = texture(colortex0, texcoord).rgb;
}