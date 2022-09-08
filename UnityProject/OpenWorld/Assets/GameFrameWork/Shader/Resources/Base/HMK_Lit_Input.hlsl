#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)
half4 _BaseColor;
float4 _BaseMap_ST;
half _BumpScale;
half _MetallicScale, _RoughnessScale, _OcclusionScale, _EmissionScale;
half _Cutoff;

half3 _EmissionColor;
half _BreathSpeed;

CBUFFER_END

TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
TEXTURE2D(_PBRMap);SAMPLER(sampler_PBRMap);
TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);