#ifndef RENDERPIPELINE_LIGHTING_INCLUDED
#define RENDERPIPELINE_LIGHTING_INCLUDED

#include "Packages/RenderPipeline/ShaderLibrary/Core.hlsl"
#include "Packages/RenderPipeline/ShaderLibrary/SurfaceData.hlsl"
#include "Packages/RenderPipeline/ShaderLibrary/LightingData.hlsl"
#include "Packages/RenderPipeline/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/RenderPipeline/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"


half3 ShadeSingleLightPBR(SurfaceData surfaceData, LightingData lightingData, BRDFData brdf, Light light)
{
    float NdotL = saturate(dot(lightingData.normalWS, light.direction));
    return NdotL * light.color * surfaceData.albedo * DirectBDRF(lightingData, brdf, light) * light.shadowAttenuation;
}


half3 ShadeAllLightPBR(SurfaceData surfaceData, LightingData lightingData)
{
    // ShadowSamplingData shadowSamplingData = GetShadowSamplingData(lightingData.positionWS);
    // return shadowSamplingData.strength;

    Light mainLight = GetMainLight(lightingData.positionWS, lightingData.normalWS);
    BRDFData brdf = GetBRDF(surfaceData);
    return ShadeSingleLightPBR(surfaceData, lightingData, brdf, mainLight);
}


#endif

