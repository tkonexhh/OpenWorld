#ifndef RENDERPIPELINE_BRDF_INCLUDED
#define RENDERPIPELINE_BRDF_INCLUDED

// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/BSDF.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/RenderPipeline/ShaderLibrary/SurfaceData.hlsl"
#include "Packages/RenderPipeline/ShaderLibrary/PBREquation.hlsl"

#define MIN_REFLECTIVITY 0.04
#define kDielectricSpec half4(MIN_REFLECTIVITY, MIN_REFLECTIVITY, MIN_REFLECTIVITY, 1.0 - MIN_REFLECTIVITY) // standard dielectric reflectivity coef at incident angle (= 4%)


struct BRDFData
{
    half3 diffuse;
    half3 specular;
    half roughness;
    float fresnel;
};

half OneMinusReflectivityMetallic(half metallic)
{
    half oneMinusDielectricSpec = kDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

BRDFData GetBRDF(SurfaceData surface)
{
    half oneMinusReflectivity = OneMinusReflectivityMetallic(surface.metallic);//金属越强漫反射越弱
    half perceptualRoughness = RoughnessToPerceptualRoughness(surface.roughness);//粗糙度转化为感知粗糙度
    BRDFData brdf;
    brdf.diffuse = surface.albedo * oneMinusReflectivity;
    brdf.specular = lerp(kDielectricSpec.rgb, surface.albedo, surface.metallic);
    brdf.roughness = perceptualRoughness;
    brdf.fresnel = saturate(1 - surface.roughness + 1.0 - oneMinusReflectivity);
    return brdf;
}

half SpecularStrength(LightingData lightingData, BRDFData brdf, Light light)
{
    float3 H = SafeNormalize(light.direction + lightingData.viewDirection);
    float NdotH = saturate(dot(float3(lightingData.normalWS), H));
    float LdotH = saturate(dot(light.direction, H));

    float r2 = brdf.roughness * brdf.roughness;
    float d = NdotH * NdotH * (r2 - 1) + 1.00001f;
    half d2 = half(d * d);

    half LdotH2 = LdotH * LdotH;
    half normalization = brdf.roughness * 4.0 + 2.0;
    half specularTerm = r2 / (d2 * max(half(0.1), LdotH2) * normalization);

    return specularTerm;
}

half3 DirectBDRF(LightingData lightingData, BRDFData brdf, Light light)
{
    return SpecularStrength(lightingData, brdf, light) * brdf.specular + brdf.diffuse;
}

half3 IndirectBRDF(SurfaceData surfaceData, LightingData lightingData, BRDFData brdf, half3 diffuse, half3 specular)
{
    float fresnelStrength = Pow4(1.0 - saturate(dot(lightingData.normalWS, lightingData.viewDirection)));// * surface.fresnelStrength;
    float3 reflection = specular * lerp(brdf.specular, brdf.fresnel, fresnelStrength);
    //high roughness will halve the reflection while low roughness will not matter much
    reflection /= brdf.roughness * brdf.roughness + 1.0;
    return(reflection + diffuse * brdf.diffuse) * surfaceData.occlusion;
}



#endif

