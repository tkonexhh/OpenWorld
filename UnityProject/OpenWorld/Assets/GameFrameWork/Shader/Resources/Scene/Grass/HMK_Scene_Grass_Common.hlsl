#pragma once

#include "./../../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
#include "./../Hidden/Wind.hlsl"
#include "./../Hidden/Bending.hlsl"
#include "./../../HLSLIncludes/Common/Global.hlsl"

///////////////////////////////////////////////////////////////////////////////
//                      Fade Distance                                        //
///////////////////////////////////////////////////////////////////////////////

float3 DeriveNormal(float3 positionWS)
{
    float3 dpx = ddx(positionWS);
    float3 dpy = ddy(positionWS) * _ProjectionParams.x;
    return normalize(cross(dpx, dpy));
}

float InterleavedNoise(float2 coords, float t)
{
    return t * (InterleavedGradientNoise(coords, 0) + t);
}


float DistanceFadeFactor(float3 positionWS, float4 params)
{
    if (params.z == 0) return 1;

    float pixelDist = length(_WorldSpaceCameraPos - positionWS.xyz);

    //Distance based scalar
    float f = saturate((pixelDist - params.x) / params.y);

    //Invert
    if (params.w <= 0) f = 1 - f;

    return f;
}

void ApplyDistanceFade(half cutoff, float3 positionCS, float3 positionWS, float4 params)
{
    float f = 1 - DistanceFadeFactor(positionWS, params) ;

    float NdotV = saturate(dot(DeriveNormal(positionWS), SafeNormalize(_WorldSpaceCameraPos - positionWS)));
    float dither = InterleavedNoise(positionCS.xy, NdotV);
    float alpha = lerp(dither, f, NdotV);
    // clip(NdotV - cutoff);
    clip(alpha - cutoff);
    clip(cutoff - alpha * f);
}


///////////////////////////////////////////////////////////////////////////////
//                   Shade Light                                             //
///////////////////////////////////////////////////////////////////////////////

half3 ApplyHueColor(half3 baseColor, half4 hueVariation)
{
    float hueVariationAmount = frac(UNITY_MATRIX_M[0].w + UNITY_MATRIX_M[1].w + UNITY_MATRIX_M[2].w);
    float viewPos = saturate(hueVariationAmount * hueVariation.a);

    half3 shiftedColor = lerp(baseColor, hueVariation.rgb, viewPos);
    return shiftedColor;
}

half3 ApplySingleDirectLight(Light light, HMKLightingData lightingData, half3 albedo, half positionOSY, half3 radiance, half specularStrength)
{
    half3 H = normalize(light.direction + lightingData.viewDirWS);
    float NdotH = max(0, dot(lightingData.normalWS, H));
    float NdotV = max(dot(lightingData.normalWS, lightingData.viewDirWS), 0);
    half directDiffuse = dot(lightingData.normalWS, light.direction) * 0.5 + 0.5;//Half Lambert

    float specularPow = NdotH;
    specularPow *= specularPow;
    specularPow *= specularPow;
    specularPow *= specularPow;
    specularPow *= specularPow;
    

    half3 directSpecular = specularPow * _SpecularColor * specularStrength;//高光部分
    half3 edgeSpecular = specularPow * _SpecularColor * smoothstep(0.6, 0.9, 0.5);
    
    half3 specular = (directSpecular + edgeSpecular) * positionOSY * positionOSY * light.shadowAttenuation;
    specular = lerp(specular, 0, ClampRange(_Wetness, 0.2, 0.55));

    // return directSpecular;
    half3 lighting = light.color * light.distanceAttenuation;
    // half3 lighting = light.color * light.shadowAttenuation * light.distanceAttenuation;
    half3 result = (albedo * directDiffuse + specular) * lighting * radiance;
    return result;
}

half3 CompositeAllLightResults(half3 indirectResult, half3 mainLightResult, half3 additionalLightSumResult)
{
    half3 finalResult = indirectResult + mainLightResult + additionalLightSumResult;
    return finalResult;
}

half3 GrassShadeAllLight(HMKSurfaceData surfaceData, HMKLightingData lightingData, half positionOSY, half specularStrength)
{
    // ApplyWetness(surfaceData.albedo, surfaceData.roughness, 0);
    half3 albedoSqr = surfaceData.albedo * surfaceData.albedo;
    surfaceData.albedo = lerp(surfaceData.albedo, albedoSqr, ClampRange(_Wetness, 0.2, 0.55));

    //间接光结果
    half3 indirectResult = SampleSH(0) * surfaceData.albedo * 0.5;
    // return indirectResult;
    //主光源结果
    Light mainLight;
    #if _MAIN_LIGHT_SHADOWS
        mainLight = GetMainLight(lightingData.shadowCoord);
    #else
        mainLight = GetMainLight();
    #endif

    half3 radiance = CalculateRadiance(mainLight, lightingData);
    // return radiance;

    half3 mainLightResult = ApplySingleDirectLight(mainLight, lightingData, surfaceData.albedo, positionOSY, radiance, specularStrength);
    // return mainLightResult;

    half4 shadowMask = half4(1, 1, 1, 1);
    //次光源结果
    half3 additionalLightSumResult = 0;
    int additionalLightsCount = GetAdditionalLightsCount();
    half rate = 1.0 / additionalLightsCount;//亮度系数
    for (int i = 0; i < additionalLightsCount; ++i)
    {
        int perObjectLightIndex = GetPerObjectLightIndex(i);
        Light light = GetAdditionalLight(perObjectLightIndex, lightingData.positionWS, shadowMask); // use original positionWS for lighting
        additionalLightSumResult += ApplySingleDirectLight(light, lightingData, surfaceData.albedo, positionOSY, radiance, specularStrength) * rate;
    }
    // return additionalLightSumResult;
    
    return CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult);
}