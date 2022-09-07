#pragma once

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct LowPolySurfaceData
{
    half3 albedo;//固有色
    half alpha;//透明度
    // half metallic;//金属度
    // half roughness;//粗糙度
    // half occlusion;//遮蔽

};

struct LowPolyLightingData
{
    float3 normalWS;
    float3 positionWS;
    half3 viewDirWS;
    float4 shadowCoord;
};

LowPolySurfaceData InitSurfaceDaata(half3 albedo, half alpha)
{
    LowPolySurfaceData data;
    data.albedo = albedo;
    data.alpha = alpha;
    return data;
}


LowPolyLightingData InitLightingData(half3 positionWS)
{
    LowPolyLightingData lightingData;

    float3 worldDx = ddx(positionWS);
    float3 worldDy = ddy(positionWS);
    float3 worldNormal = normalize(cross(worldDy, worldDx));
    float3 normalWS = worldNormal * 0.5 + 0.5;

    lightingData.normalWS = normalize(normalWS);
    lightingData.viewDirWS = normalize(GetWorldSpaceViewDir(positionWS));
    lightingData.positionWS = positionWS;
    lightingData.shadowCoord = TransformWorldToShadowCoord(positionWS);
    // lightingData.lightmapUV = lightmapUV;

    // lightingData.depth = positionCS.z;
    return lightingData;
}

half3 ShadeGI(float3 normalWS)
{
    half4 x;
    half4 normal = half4(normalWS, 1.0);
    x.r = dot(unity_SHAr, normal);
    x.g = dot(unity_SHAg, normal);
    x.b = dot(unity_SHAb, normal);
    half3 gi = max(half3(0, 0, 0), x);
    return gi;
}

half3 ShadeGlobalIllumination(LowPolySurfaceData surfaceData, LowPolyLightingData lightingData)
{
    return ShadeGI(lightingData.normalWS);
    return half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
}

///////////////////////////////////////////////////////////////////////////////
//                        Shade Light                                        //
///////////////////////////////////////////////////////////////////////////////

half3 ShadeSingleLight(LowPolySurfaceData surfaceData, LowPolyLightingData lightingData, Light light)
{
    

    float NdotL = saturate(dot(light.direction, lightingData.normalWS)) ;

    //主光源漫反射
    half3 diffuse = surfaceData.albedo * NdotL * light.color;
    half3 specular = light.color * pow(max(0.0, dot(reflect(-light.direction, lightingData.normalWS), lightingData.viewDirWS)), 4);
    half3 finalResult = diffuse * light.shadowAttenuation + specular;
    return finalResult;
}


half3 ShadeAllLight(LowPolySurfaceData surfaceData, LowPolyLightingData lightingData)
{
    //Mainlight
    half4 shadowMask = half4(1, 1, 1, 1);
    Light mainLight = GetMainLight(lightingData.shadowCoord, lightingData.positionWS, shadowMask);
    half3 mainLightResult = ShadeSingleLight(surfaceData, lightingData, mainLight);
    half3 indirectResult = ShadeGlobalIllumination(surfaceData, lightingData);
    // return indirectResult;
    // return mainLightResult;
    return mainLightResult + indirectResult;
}