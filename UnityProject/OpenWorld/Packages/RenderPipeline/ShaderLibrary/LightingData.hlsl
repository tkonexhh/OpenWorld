#ifndef RENDERPIPELINE_LIGHTING_DATA_INCLUDED
#define RENDERPIPELINE_LIGHTING_DATA_INCLUDED

#include "Packages/RenderPipeline/ShaderLibrary/UnityInput.hlsl"

struct LightingData
{
    float3 positionWS;
    half3 normalWS;
    half3 viewDir;
};

LightingData InitLightingData(float3 positionWS, half3 normal)
{
    LightingData lightingData;
    lightingData.positionWS = positionWS;
    lightingData.normalWS = normalize(normal);
    lightingData.viewDir = normalize(GetCameraPositionWS() - positionWS);
    return lightingData;
}

#endif
