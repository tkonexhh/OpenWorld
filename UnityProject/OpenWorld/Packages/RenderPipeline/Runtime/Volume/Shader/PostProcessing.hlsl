#pragma once

#include "Packages/RenderPipeline/ShaderLibrary/Core.hlsl"

//Always present in every shader
TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);float4 _MainTex_TexelSize;
sampler sampler_LinearClamp;
float4x4 _FrustumCornersRay;//用于重建世界坐标


half4 GetScreenColor(float2 uv)
{
    return SAMPLE_TEXTURE2D(_MainTex, sampler_LinearClamp, uv);
}

///普通后处理
struct AttributesDefault
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
};


struct VaryingsDefault
{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
};
VaryingsDefault VertDefault1(uint vertexID: SV_VERTEXID)
{
    VaryingsDefault output;
    //make the [-1, 1] NDC, visible UV coordinates cover the 0-1 range
    output.positionCS = float4(
        vertexID <= 1 ? - 1.0: 3.0,
        vertexID == 1 ? 3.0: - 1.0,
        0.0, 1.0);
    output.uv = float2(
        vertexID <= 1 ? 0.0: 2.0,
        vertexID == 1 ? 2.0: 0.0);
    //some graphics APIs have the texture V coordinate start at the top while others have it start at the bottom
    if (_ProjectionParams.x < 0.0)
    {
        output.uv.y = 1.0 - output.uv.y;
        return output;
    }
}

VaryingsDefault VertDefault(AttributesDefault input)
{
    VaryingsDefault output;
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.uv = input.uv;

    return output;
}

//需要到世界坐标的
struct VaryingsWorld
{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
    float4 interpolatedRay: TEXCOORD2;
};

VaryingsWorld VertWorld(AttributesDefault input)
{
    VaryingsWorld output;
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.uv = input.uv;


    int index = 0;
    if (input.uv.x < 0.5 && input.uv.y < 0.5)
    {
        index = 0;
    }
    else if (input.uv.x > 0.5 && input.uv.y < 0.5)
    {
        index = 1;
    }
    else if (input.uv.x > 0.5 && input.uv.y > 0.5)
    {
        index = 2;
    }
    else
    {
        index = 3;
    }

    #if UNITY_UV_STARTS_AT_TOP
        if (_MainTex_TexelSize.y < 0)
            index = 3 - index;
    #endif

    output.interpolatedRay = _FrustumCornersRay[index];

    return output;
}


//------------------------------------------------------------------------------------------------------
// Generic functions
//------------------------------------------------------------------------------------------------------

float rand(float n)
{
    return frac(sin(n) * 13758.5453123 * 0.01);
}

float rand(float2 n)
{
    return frac(sin(dot(n, float2(12.9898, 78.233))) * 43758.5453);
}


