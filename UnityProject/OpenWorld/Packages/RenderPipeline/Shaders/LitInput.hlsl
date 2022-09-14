#ifndef RENDERPIPELINE_LIT_INPUT_INCLUDED
#define RENDERPIPELINE_LIT_INPUT_INCLUDED


CBUFFER_START(UnityPerMaterial)
half4 _BaseColor;
half _MetallicScale;
half _RoughnessScale;
half _OcclusionScale;

half3 _EmissionColor;
half _EmissionScale;

real _Cutoff;
CBUFFER_END


// UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
// UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
// UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

#endif