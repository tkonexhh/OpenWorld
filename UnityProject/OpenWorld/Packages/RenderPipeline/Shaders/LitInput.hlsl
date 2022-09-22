#ifndef RENDERPIPELINE_LIT_INPUT_INCLUDED
#define RENDERPIPELINE_LIT_INPUT_INCLUDED

#include "Packages/RenderPipeline/ShaderLibrary/Common.hlsl"
#include "Packages/RenderPipeline/ShaderLibrary/Core.hlsl"


CBUFFER_START(UnityPerMaterial)
half4 _BaseColor;
half _MetallicScale;
half _RoughnessScale;
half _OcclusionScale;

half3 _EmissionColor;
half _EmissionScale;

real _Cutoff;

float4 _BaseMap_ST;
CBUFFER_END


TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

#endif