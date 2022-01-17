#pragma once

float3 _LightDirection;

half4 _GlobalShadowColor;
half4 _GlobalShadowColorNear;
half4 _GlobalShadowColorFar;
half _GlobalShadowLerp;



float4 GetShadowPositionHClip(float3 positionOS, float3 normalOS)
{
    float3 positionWS = TransformObjectToWorld(positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(normalOS);

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif

    return positionCS;
}