#ifndef RENDERPIPELINE_LIGHTING_DATA_INCLUDED
#define RENDERPIPELINE_LIGHTING_DATA_INCLUDED

#include "Packages/RenderPipeline/ShaderLibrary/UnityInput.hlsl"

struct LightingData
{
    float3 positionWS;
    half3 normalWS;
    half3 viewDirection;
    float2 lightMapUV;
};

LightingData InitLightingData(float3 positionWS, half3 normal, float2 lightmapUV)
{
    LightingData lightingData;
    lightingData.positionWS = positionWS;
    lightingData.normalWS = normalize(normal);
    lightingData.viewDirection = normalize(GetCameraPositionWS() - positionWS);
    lightingData.lightMapUV = lightmapUV;
    return lightingData;
}


#endif
