#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)
half4 _BaseColor;
half _BumpScale;
half _RoughnessScale, _OcclusionScale;
half _Cutoff;

float4 _BaseMap_ST;
CBUFFER_END

TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
