#ifndef RENDERPIPELINE_LIGHTING_INCLUDED
#define RENDERPIPELINE_LIGHTING_INCLUDED

#include "Packages/RenderPipeline/ShaderLibrary/Core.hlsl"
#include "Packages/RenderPipeline/ShaderLibrary/SurfaceData.hlsl"
#include "./LightingData.hlsl"
#include "Packages/RenderPipeline/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/RenderPipeline/ShaderLibrary/BRDF.hlsl"
#include "./GI.hlsl"
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
    BRDFData brdf = GetBRDF(surfaceData);
    GI gi = GetGI(lightingData, brdf);

    Light mainLight = GetMainLight(lightingData.positionWS, lightingData.normalWS);
    
    half3 mainLightResult = ShadeSingleLightPBR(surfaceData, lightingData, brdf, mainLight);
    half3 additionalResult = 0;
    half3 indirectResult = IndirectBRDF(surfaceData, lightingData, brdf, gi.diffuse, gi.specular);
    return mainLightResult + additionalResult + indirectResult;
}


#endif

