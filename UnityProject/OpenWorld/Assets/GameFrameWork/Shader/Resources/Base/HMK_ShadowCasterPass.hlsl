#pragma once

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "./../HLSLIncludes/Common/HMK_Shadow.hlsl"


// TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

struct Attributes
{
    float4 positionOS: POSITION;
    float3 normalOS: NORMAL;
    float2 texcoord: TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv: TEXCOORD0;
    float4 positionCS: SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


Varyings ShadowPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.uv = input.texcoord;//TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.positionCS = GetShadowPositionHClip(input.positionOS, input.normalOS);
    return output;
}

half4 ShadowPassFragment(Varyings input): SV_TARGET
{
    #if defined(_ALPHATEST_ON)
        half4 var_Base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
        half alpha = var_Base.a;
        clip(alpha - _Cutoff);
    #endif
    
    return 0;
}

