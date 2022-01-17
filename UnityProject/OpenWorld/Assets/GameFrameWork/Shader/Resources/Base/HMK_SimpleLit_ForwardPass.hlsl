#pragma once

#include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    half3 normalOS: NORMAL;
    half4 tangentOS: TANGENT;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float3 positionWS: TEXCOORD3;
    float2 uv: TEXCOORD0;
    half3 normalWS: NORMAL;
    half4 tangentWS: TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
CBUFFER_START(UnityPerMaterial)
half4 _BaseColor;
half _Cutoff;
CBUFFER_END



half4 GetFinalBaseColor(Varyings input)
{
    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
}

HMKSurfaceData InitSurfaceData(Varyings input)
{
    float4 finalBaseColor = GetFinalBaseColor(input);
    half3 albedo = finalBaseColor.rgb;
    half alpha = finalBaseColor.a;
    return InitSurfaceData(albedo, alpha, 0, 0, 0);
}

HMKLightingData InitLightingData(Varyings input)
{
    //采样法线贴图
    half4 var_NormalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv);
    half3 bitangentWS = (cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w);
    half3 normalTS = UnpackNormal(var_NormalMap);
    half3x3 TBN = float3x3(input.tangentWS.xyz, bitangentWS, input.normalWS);
    float3 normalWS = TransformTangentToWorld(normalTS, TBN);

    return InitLightingData(input.positionWS, normalWS);
}

Varyings vert(Attributes input)
{
    Varyings output;
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.uv = input.uv;
    output.normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));
    output.tangentWS = input.tangentOS;
    return output;
}


float4 frag(Varyings input): SV_Target
{
    HMKSurfaceData surfaceData = InitSurfaceData(input);
    HMKLightingData lightingData = InitLightingData(input);
    
    #if defined(_ALPHATEST_ON)
        clip(surfaceData.alpha - _Cutoff);
    #endif

    half3 finalRGB = ShadeAllLightBlinnPhong(surfaceData, lightingData);
    return half4(finalRGB, surfaceData.alpha);
}