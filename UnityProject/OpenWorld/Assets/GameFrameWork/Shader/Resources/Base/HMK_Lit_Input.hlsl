#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)
half4 _BaseColor;
half _BumpScale;
half _MetallicScale, _RoughnessScale, _OcclusionScale;
half _Cutoff;
CBUFFER_END