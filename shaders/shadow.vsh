#version 450 compatibility
#define gbuffers_shadow
#define vsh
#define ShaderStage -1
#include "/lib/Syntax.glsl"
#include "/lib/Settings.glsl"

uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float far;
uniform float sunAngle;
uniform float frameTimeCounter;

out vec3 vertNormal;


#include "/lib/Utility.glsl"
#include "/lib/Shadows/ShadowBiasFunctions.glsl"

vec3 GetWorldSpacePositionShadow() {
	return transMAD(shadowModelViewInverse, transMAD(gl_ModelViewMatrix, gl_Vertex.xyz));
}

vec4 ProjectShadowMap(vec4 position) {
	position = vec4(projMAD(shadowProjection, transMAD(shadowModelView, position.xyz)), position.z * shadowProjection[2].w + shadowProjection[3].w);
	
	float biasCoeff = GetShadowBias(position.xy);
	
	position.xy /= biasCoeff;
	
	position.z += 0.001 * sin(max0(vertNormal.z));
	position.z += 0.000005 / (abs(position.x) + 1.0);
	position.z += 0.006 * pow2(biasCoeff) * 2048.0 / shadowMapResolution;
	
	position.z /= 4.0; // Shrink the domain of the z-buffer. This counteracts the noticable issue where far terrain would not have shadows cast, especially when the sun was near the horizon
	
	return position;
}

void main() {
	vertNormal     = normalize(mat3(shadowModelView) * gl_Normal);
	vec3 position  = GetWorldSpacePositionShadow();

	gl_Position    = ProjectShadowMap(position.xyzz);
}
