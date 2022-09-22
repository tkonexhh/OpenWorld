#ifndef RENDERPIPELINE_REALTIME_LIGHTS_INCLUDED
#define RENDERPIPELINE_REALTIME_LIGHTS_INCLUDED

#include "./Common.hlsl"
#include "./Input.hlsl"
#include "./Shadows.hlsl"

// Abstraction over Light shading data.
struct Light
{
    half3 direction;
    half3 color;
    float distanceAttenuation; // full-float precision required on some platforms
    half shadowAttenuation;
    uint layerMask;
};


///////////////////////////////////////////////////////////////////////////////
//                        Attenuation Functions                               /
///////////////////////////////////////////////////////////////////////////////

// Matches Unity Vanilla HINT_NICE_QUALITY attenuation
// Attenuation smoothly decreases to light range.
float DistanceAttenuation(float distanceSqr, half2 distanceAttenuation)
{
    float lightAtten = rcp(distanceSqr);//1 / distanceSqr rcp快速求倒数
    float2 distanceAttenuationFloat = float2(distanceAttenuation);

    // Use the smoothing factor also used in the Unity lightmapper.
    half factor = half(distanceSqr * distanceAttenuationFloat.x);
    half smoothFactor = saturate(half(1.0) - factor * factor);
    smoothFactor = smoothFactor * smoothFactor;

    return lightAtten * smoothFactor;
}

half AngleAttenuation(half3 spotDirection, half3 lightDirection, half2 spotAttenuation)
{
    // Spot Attenuation with a linear falloff can be defined as
    // (SdotL - cosOuterAngle) / (cosInnerAngle - cosOuterAngle)
    // This can be rewritten as
    // invAngleRange = 1.0 / (cosInnerAngle - cosOuterAngle)
    // SdotL * invAngleRange + (-cosOuterAngle * invAngleRange)
    // SdotL * spotAttenuation.x + spotAttenuation.y

    // If we precompute the terms in a MAD instruction
    half SdotL = dot(spotDirection, lightDirection);
    half atten = saturate(SdotL * spotAttenuation.x + spotAttenuation.y);
    return atten * atten;
}

///////////////////////////////////////////////////////////////////////////////
//                      Light Abstraction                                    //
///////////////////////////////////////////////////////////////////////////////

Light GetMainLight()
{
    Light light;
    light.direction = half3(_MainLightPosition.xyz);
    light.distanceAttenuation = unity_LightData.z; // unity_LightData.z is 1 when not culled by the culling mask, otherwise 0.
    light.shadowAttenuation = 1.0;
    light.color = _MainLightColor.rgb;
    light.layerMask = _MainLightLayerMask;
    return light;
}

//带阴影的Light
Light GetMainLight(float3 positionWS, float3 normalWS)
{
    Light light = GetMainLight();
    ShadowSamplingData shadowSamplingData = GetShadowSamplingData(positionWS);
    float3 positionSTS = TransformWorldToShadowCoord(shadowSamplingData.cascadeIndex, positionWS, normalWS);
    light.shadowAttenuation = MainLightRealtimeShadow(positionSTS, shadowSamplingData);
    return light;
}

///////////////////////////////////////////////////////////////////////////////
//            Additional    Light Abstraction                                //
///////////////////////////////////////////////////////////////////////////////
int GetAdditionalLightsCount()
{
    // TODO: we need to expose in SRP api an ability for the pipeline cap the amount of lights
    // in the culling. This way we could do the loop branch with an uniform
    // This would be helpful to support baking exceeding lights in SH as well
    return int(min(_AdditionalLightsCount.x, unity_LightData.y));
}


Light GetAdditionalLight(uint i, float3 positionWS)
{
    float4 lightPositionWS = _AdditionalLightsPosition[i];
    half3 color = _AdditionalLightsColor[i].rgb;
    half4 distanceAndSpotAttenuation = _AdditionalLightsAttenuation[i];
    half4 spotDirection = _AdditionalLightsSpotDir[i];

    // Directional lights store direction in lightPosition.xyz and have .w set to 0.0.
    // This way the following code will work for both directional and punctual lights.
    float3 lightVector = lightPositionWS.xyz - positionWS * lightPositionWS.w;
    float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);

    half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));
    // full-float precision required on some platforms
    float attenuation = DistanceAttenuation(distanceSqr, distanceAndSpotAttenuation.xy) * AngleAttenuation(spotDirection.xyz, lightDirection, distanceAndSpotAttenuation.zw);

    Light light;
    light.direction = lightDirection;
    light.distanceAttenuation = attenuation;
    light.shadowAttenuation = 1.0; // This value can later be overridden in GetAdditionalLight(uint i, float3 positionWS, half4 shadowMask)
    light.color = color;
    light.layerMask = _MainLightLayerMask;
    return light;
}

#endif

