#ifndef RENDERPIPELINE_LIT_INPUT_INCLUDED
#define RENDERPIPELINE_LIT_INPUT_INCLUDED

#include "Packages/RenderPipeline/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


CBUFFER_START(UnityPerMaterial)
half4 _BaseColor;
half _MetallicScale;
half _RoughnessScale;
half _OcclusionScale;

half3 _EmissionColor;
half _EmissionScale;

real _Cutoff;

float4 _MainTex_ST;
CBUFFER_END


// UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
// UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
// UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

#endif