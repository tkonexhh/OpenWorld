#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

// CBUFFER_START(UnityPerMaterial)
float4 _BaseColor;
float _BlendAlpha;
float _OutLineSpec;
// CBUFFER_END

TEXTURE2D(_FreezeTex);SAMPLER(sampler_FreezeTex);


struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    half3 normalOS: NORMAL;
    //half4 tangentOS: TANGENT;
    //UNITY_VERTEX_INPUT_INSTANCE_ID

};


struct Varyings
{
    float4 positionCS: SV_POSITION;
    float3 positionWS: TEXCOORD2;
    float2 uv: TEXCOORD0;
    
    half3 normalWS: NORMAL;
};


Varyings FreezeVert(Attributes input)
{
    Varyings output;
    //UNITY_SETUP_INSTANCE_ID(input);
    
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.uv = input.uv;
    float3 normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));
    
    output.normalWS = normalWS;
    
    return output;
}


float4 FreezeFrag(Varyings input): SV_Target
{
    float2 uv = input.uv;
    half4 var_BaseMap = SAMPLE_TEXTURE2D(_FreezeTex, sampler_FreezeTex, uv);
    half3 finalRGB = var_BaseMap.rgb * _BaseColor;

    float3 camPos = _WorldSpaceCameraPos.xyz;
    float3 view = normalize(camPos - input.positionWS);
    float light = (1 - abs(dot(view, input.normalWS))) * (1 - _OutLineSpec) + _OutLineSpec;

    return half4(finalRGB, _BlendAlpha * light);
}
