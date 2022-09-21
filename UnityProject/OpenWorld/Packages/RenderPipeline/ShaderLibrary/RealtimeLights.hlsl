#ifndef RENDERPIPELINE_REALTIME_LIGHTS_INCLUDED
#define RENDERPIPELINE_REALTIME_LIGHTS_INCLUDED

#include "Packages/RenderPipeline/ShaderLibrary/Input.hlsl"
#include "Packages/RenderPipeline/ShaderLibrary/Shadows.hlsl"

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


#endif

