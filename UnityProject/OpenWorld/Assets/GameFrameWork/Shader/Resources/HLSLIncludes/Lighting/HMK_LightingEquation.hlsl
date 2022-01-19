#pragma once

#include "./HMK_PBREquation.hlsl"
#include "./HMK_IrradianceVolume.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "./../Common/HMK_Shadow.hlsl"
#include "./../Common/HMK_Common.hlsl"


#define kDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)

struct HMKSurfaceData
{
    half3 albedo;//固有色
    half alpha;//透明度
    half metallic;//金属度
    half roughness;//粗糙度
    half occlusion;//遮蔽

};

struct HMKLightingData
{
    float3 normalWS;
    float3 positionWS;
    half3 viewDirWS;
    float4 shadowCoord;
    float2 lightmapUV;
    // half depth;

};



HMKSurfaceData InitSurfaceData(half3 albedo, half alpha, half metallic, half roughness, half occlusion)
{
    HMKSurfaceData surfaceData;
    surfaceData.albedo = albedo;
    surfaceData.alpha = alpha;
    surfaceData.metallic = saturate(metallic);
    surfaceData.roughness = saturate(roughness);
    surfaceData.occlusion = occlusion;
    return surfaceData;
}

HMKLightingData InitLightingData(half3 positionWS, half3 normalWS, float2 lightmapUV)
{
    HMKLightingData lightingData;
    lightingData.normalWS = normalize(normalWS);
    lightingData.viewDirWS = normalize(GetWorldSpaceViewDir(positionWS));
    lightingData.positionWS = positionWS;
    lightingData.shadowCoord = TransformWorldToShadowCoord(positionWS);
    lightingData.lightmapUV = lightmapUV;

    // lightingData.depth = positionCS.z;
    return lightingData;
}

HMKLightingData InitLightingData(half3 positionWS, half3 normalWS)
{
    return InitLightingData(positionWS, normalWS, 0);
}


///////////////////////////////////////////////////////////////////////////////
//                       GI                                                  //
///////////////////////////////////////////////////////////////////////////////

//相应GI xyz是颜色 a是环境光遮蔽
half4 ShadeIrradiance(float3 positionWS, float normalWS)
{
    #if defined(_GIMAP_ON)
        half4 irradiance = HMKSampleIrradiance(positionWS, normalWS);
        return irradiance;
    #else
        return half4(0, 0, 0, 1);
    #endif
}

half4 ShadeIrradiance(HMKLightingData lightingData)
{
    return ShadeIrradiance(lightingData.positionWS, lightingData.normalWS);
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

half3 ShadeGI(HMKLightingData lightingData)
{
    return ShadeGI(lightingData.normalWS);
}

half3 MixGIAndIrradiance(half3 gi, half3 irradiance, float occlusion)
{
    return irradiance + gi;
    return lerp(irradiance * 2, gi * 0.5, occlusion - 0.1);
}


///////////////////////////////////////////////////////////////////////////////
//                          Light Map                                        //
///////////////////////////////////////////////////////////////////////////////
//顶点声明
#define HMK_DECLARE_LIGHTMAP(lightmapName, index) float2 lightmapName: TEXCOORD##index
#define HMK_OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;


#define LIGHTMAP_HDR_MULTIPLIER  real(34.493242)
#define LIGHTMAP_HDR_EXPONENT   real(2.2)
#define LIGHTMAP_NAME unity_Lightmap
// #define LIGHTMAP_INDIRECTION_NAME unity_LightmapInd
#define LIGHTMAP_SAMPLER_NAME samplerunity_Lightmap


half3 HMKSampleSingleLightmap(float2 lightmapUV, float4 transform, real4 decodeInstructions)
{
    // transform is scale and bias
    lightmapUV = lightmapUV * transform.xy + transform.zw;
    real3 illuminance = real3(0.0, 0.0, 0.0);
    illuminance = SAMPLE_TEXTURE2D(LIGHTMAP_NAME, LIGHTMAP_SAMPLER_NAME, lightmapUV).rgb;
    return illuminance;
}

half3 HMKSampleLightmap(float2 lightmapUV, half3 normalWS)
{
    return SampleLightmap(lightmapUV, normalWS);
    half4 transformCoords = half4(1, 1, 0, 0);
    half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
    #if defined(LIGHTMAP_ON)
        return HMKSampleSingleLightmap(lightmapUV, transformCoords, decodeInstructions);
    #else
        return half3(0.0, 0.0, 0.0);
    #endif
    return half3(0.0, 0.0, 0.0);
}


half3 MixSHOrLightmap(HMKLightingData lightingData)
{
    #if defined(LIGHTMAP_ON)
        return HMKSampleLightmap(lightingData.lightmapUV, lightingData.normalWS);
    #else
        return ShadeGI(lightingData);
    #endif
}


///////////////////////////////////////////////////////////////////////////////
//                        GlobalIllumination                                 //
///////////////////////////////////////////////////////////////////////////////

//PBR中计算的公共变量
struct HMKPBRParam
{
    float NdotV;
    float kInDirectLight;//G项中的k值
    float F0;
    float roughness;
};


//根据粗糙度计算立方体贴图的Mip等级
//同PerceptualRoughnessToMipmapLevel
float CubeMapMip(float roughness)
{
    float mip_roughness = (roughness) * (1.7 - 0.7 * roughness);//Unity内部不是线性 调整下拟合曲线求近似
    half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;//把粗糙度remap到0-6 7个阶级 然后进行lod采样
    return mip;
}

half3 GlossyEnvironmentReflection(half roughness, half3 reflectVector, half occlusion)
{
    half mip = CubeMapMip(roughness);
    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);
    // half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
    #if defined(UNITY_USE_NATIVE_HDR)
        half3 irradiance = encodedIrradiance.rgb;
    #else
        half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
    #endif
    return irradiance * occlusion;
}

//间接光的菲涅尔系数
float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(float3(1, 1, 1) * (1 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

half3 ShadeGlobalIllumination(HMKSurfaceData surfaceData, HMKLightingData lightingData, HMKPBRParam PBRParam, half3 radiance)
{
    half roughness = PBRParam.roughness;
    //--------间接光照镜面反射---------
    half mip = CubeMapMip(roughness);                              //计算Mip等级，用于采样CubeMap
    float3 reflectVec = reflect(-lightingData.viewDirWS, lightingData.normalWS);
    half3 indirectSpecularResult = GlossyEnvironmentReflection(roughness, reflectVec, surfaceData.occlusion);

    half surfaceReduction = 1.0 / (roughness * roughness + 1.0);            //压暗非金属的反射
    float oneMinusReflectivity = kDielectricSpec.a - kDielectricSpec.a * surfaceData.metallic;
    half grazingTerm = saturate((1 - surfaceData.roughness) + (1 - oneMinusReflectivity));
    half t = pow(1 - PBRParam.NdotV, 5);
    float3 FresnelLerp = lerp(PBRParam.F0, grazingTerm, t);                   //控制反射的菲涅尔和金属色
    half3 iblSpecularResult = surfaceReduction * indirectSpecularResult * FresnelLerp ;
    // return iblSpecularResult;
    //--------间接光照漫反射-----------
    half4 irradiance = ShadeIrradiance(lightingData);
    float occlusion = min(surfaceData.occlusion, irradiance.a);
    occlusion = surfaceData.occlusion;

    //获取球谐光照
    half3 giResult = MixSHOrLightmap(lightingData);
    // return giResult;
    half3 irradianceResult = irradiance.rgb;
    // return irradianceResult * occlusion;
    float3 iblDiffuse = MixGIAndIrradiance(giResult, irradianceResult, occlusion);
    // return iblDiffuse;

    half3 Flast = fresnelSchlickRoughness(max(PBRParam.NdotV, 0.0), PBRParam.F0, roughness);
    float kdLast = (1 - Flast) * (1 - surfaceData.metallic);//压暗边缘，边缘处应当有更多的镜面反射
    half3 iblDiffuseResult = iblDiffuse * kdLast * surfaceData.albedo ;
    // return iblDiffuseResult;
    // return irradianceColor * occlusion * kdLast;
    half3 indirectResult = iblSpecularResult + iblDiffuseResult * occlusion ;
    indirectResult *= radiance;
    return indirectResult;
}

///////////////////////////////////////////////////////////////////////////////
//                        Shade Light                                        //
///////////////////////////////////////////////////////////////////////////////

half3 ShadeSingleLightPBR(HMKSurfaceData surfaceData, HMKLightingData lightingData, Light light, HMKPBRParam PBRParam, half3 radiance)
{
    float3 L = normalize(light.direction);
    float3 V = SafeNormalize(lightingData.viewDirWS);
    float3 H = SafeNormalize(V + L);
    // half NdotL = dot(lightingData.normalWS, light.direction) * 0.5 + 0.5;
    float ndotl = dot(lightingData.normalWS, light.direction);
    float NdotL = max(saturate(ndotl), 0.000001);
    float halfNdotL = ndotl * 0.5 + 0.5;
    
    float VdotH = max(saturate(dot(lightingData.viewDirWS, H)), 0.000001);
    float NdotH = max(saturate(dot(lightingData.normalWS, H)), 0.000001);
    
    float HdotL = max(saturate(dot(H, L)), 0.000001);
    float NdotV = PBRParam.NdotV;
    float roughness = PBRParam.roughness;
    float F0 = PBRParam.F0;
    
    //********直接光照*********
    //--------直接光照镜面反射---------
    float D = D_Function(roughness, NdotH);
    // return D;
    float F = F_Function(HdotL, PBRParam.F0);
    // return F;
    // return(NdotV * NdotL * 4);
    // return NdotV;
    float G = G_Function(NdotL, NdotV, roughness, PBRParam.kInDirectLight);
    // return G;
    float3 mainSpecularResult = (D * G * F) / (NdotV * NdotL * 4);
    // return mainSpecularResult;

    //--------直接光照漫反射-----------
    float3 kd = (1 - F) * (1 - surfaceData.metallic);
    half3 mainDiffColor = kd * surfaceData.albedo * halfNdotL;
    // return mainDiffColor;

    //--------直接光部分-------
    half3 lightResult = mainSpecularResult * light.shadowAttenuation + mainDiffColor ;
    lightResult *= light.color;

    // half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation ;
    // lightResult *= lightAttenuation;
    lightResult *= radiance;
    return lightResult;
}

half3 ShadeSingleLightPBR(HMKSurfaceData surfaceData, HMKLightingData lightingData, Light light, HMKPBRParam PBRParam)
{
    return ShadeSingleLightPBR(surfaceData, lightingData, light, PBRParam, 1);
}

half3 ShadeSingleLightPBR(HMKSurfaceData surfaceData, HMKLightingData lightingData, Light light, half3 radiance)
{
    float NdotV = max(saturate(dot(lightingData.normalWS, lightingData.viewDirWS)), 0.000001);
    float roughness = surfaceData.roughness * surfaceData.roughness;
    float3 F0 = lerp(kDielectricSpec.r, surfaceData.albedo, surfaceData.metallic);

    //准备公共变量
    HMKPBRParam PBRParam;
    PBRParam.NdotV = NdotV;
    PBRParam.kInDirectLight = pow(roughness + 1, 2) / 8;
    PBRParam.F0 = F0;
    PBRParam.roughness = roughness;
    return ShadeSingleLightPBR(surfaceData, lightingData, light, PBRParam, radiance) ;
}

///////////////////////////////////////////////////////////////////////////////
//                    Shade AdditionalLight                                  //
///////////////////////////////////////////////////////////////////////////////
half3 ShadeAdditionalLight(HMKSurfaceData surfaceData, HMKLightingData lightingData, HMKPBRParam PBRParam)
{
    half3 additionalLightSumResult = 0;
    int additionalLightsCount = GetAdditionalLightsCount();
    // half rate = 1.0 / additionalLightsCount;//亮度系数
    half rate = 1;
    for (int i = 0; i < additionalLightsCount; ++i)
    {
        Light light = GetAdditionalLight(i, lightingData.positionWS); // use original positionWS for lighting
        half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation ;
        additionalLightSumResult += ShadeSingleLightPBR(surfaceData, lightingData, light, PBRParam) * lightAttenuation * rate;
    }
    return additionalLightSumResult;
}



half3 CompositeAllLightResults(half3 indirectResult, half3 mainLightResult, half3 additionalLightSumResult, HMKSurfaceData surfaceData)
{
    half3 rawLightSum = max(indirectResult, mainLightResult + additionalLightSumResult);
    return rawLightSum;
}

//
half3 CalculateRadiance(Light mainLight, HMKLightingData lightingData)
{
    // half NdotL = max(saturate(dot(lightingData.normalWS, mainLight.direction)), 0.000001);
    float NdotL = dot(lightingData.normalWS, mainLight.direction) * 0.5 + 0.5;

    
    half lightAttenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation ;
    float halfLambertShadow = NdotL * lightAttenuation;
    // half ShadowThreshold = 0.5;
    // half ShadowSmooth = 0.25;
    // lightAttenuation = saturate(LinearStep(ShadowThreshold - ShadowSmooth, ShadowThreshold + ShadowSmooth, halfLambertShadow));
    lightAttenuation = halfLambertShadow;
    // half3 lerpShadowColor = lerp(_GlobalShadowColorNear, _GlobalShadowColorFar, saturate(lightingData.depth + _GlobalShadowLerp));
    
    half3 shadowColor = lerp(_GlobalShadowColor.rgb, 1, saturate(lightAttenuation));
    // shadowColor = lerp(shadowColor, lightAttenuation, _GlobalShadowColor.a);
    return shadowColor;
}

half3 ShadeAllLightPBR(HMKSurfaceData surfaceData, HMKLightingData lightingData)
{
    // return lightingData.depth + _GlobalShadowLerp;
    // return saturate(1 - pow(lightingData.depth, _GlobalShadowLerp));
    float roughness = surfaceData.roughness * surfaceData.roughness;
    // float squareRoughness = roughness * roughness;

    half4 shadowMask = half4(1, 1, 1, 1);
    Light mainLight = GetMainLight(lightingData.shadowCoord, lightingData.positionWS, shadowMask);
    float3 H = SafeNormalize(lightingData.viewDirWS + mainLight.direction);

    // float NdotL = dot(lightingData.normalWS, mainLight.direction) * 0.5 + 0.5;//max(saturate(dot(lightingData.normalWS, mainLight.direction)), 0.000001);
    float NdotV = max(saturate(dot(lightingData.normalWS, lightingData.viewDirWS)), 0.000001);
    // float VdotH = max(saturate(dot(lightingData.viewDirWS, H)), 0.000001);
    // float LdotH = max(saturate(dot(lightingData.viewDirWS, H)), 0.000001);
    // float NdotH = max(saturate(dot(lightingData.normalWS, H)), 0.000001);

    float3 F0 = lerp(kDielectricSpec.r, surfaceData.albedo, surfaceData.metallic);

    //准备公共变量
    HMKPBRParam PBRParam;
    PBRParam.NdotV = NdotV;
    PBRParam.kInDirectLight = pow(roughness + 1, 2) / 8;
    PBRParam.F0 = F0;
    PBRParam.roughness = roughness;

    half3 radiance = CalculateRadiance(mainLight, lightingData);
    // radiance = mainLight.shadowAttenuation;
    // return radiance;

    //********直接光照*********
    half3 mainLightResult = ShadeSingleLightPBR(surfaceData, lightingData, mainLight, PBRParam, radiance);
    // return mainLightResult;
    //********间接光照*********
    half3 indirectResult = ShadeGlobalIllumination(surfaceData, lightingData, PBRParam, radiance);
    // return indirectResult;
    //******额外光照*****
    half3 additionalLightSumResult = ShadeAdditionalLight(surfaceData, lightingData, PBRParam);


    half3 finalResult = mainLightResult + indirectResult + additionalLightSumResult;

    return finalResult;
}



///////////////////////////////////////////////////////////////////////////////
//                   Shade Light  BlinnPhong                                 //
///////////////////////////////////////////////////////////////////////////////
half3 ShadeSingleLightBlinnPhong(HMKSurfaceData surfaceData, HMKLightingData lightingData, Light light)
{
    //数据准备
    half3 N = lightingData.normalWS;
    half3 V = lightingData.viewDirWS;//间接光需要
    half3 L = light.direction;
    half3 H = SafeNormalize(V + L);

    half3 lightColor = saturate(light.color);//saturate防止过亮

    half3 attenuatedLightColor = lightColor * (light.distanceAttenuation * light.shadowAttenuation);

    //对每个数据做限制，防止除0
    half NdotL = max(saturate(dot(N, L)), 0.000001);
    // half NdotV = max(saturate(dot(N, V)), 0.000001);//间接光需要
    half NdotH = max(saturate(dot(N, H)), 0.000001);
    half LdotH = max(saturate(dot(L, H)), 0.000001);

    //漫反射
    half3 diffuse = NdotL * attenuatedLightColor * surfaceData.albedo;
    //高光反射

    return diffuse;
}


half3 ShadeAllLightBlinnPhong(HMKSurfaceData surfaceData, HMKLightingData lightingData)
{
    half3 bakedGI = ShadeGI(lightingData);
    bakedGI = 0;
    //间接光漫反射
    //间接光高光反射

    //主光源结果
    half4 shadowMask = half4(1, 1, 1, 1);
    Light mainLight = GetMainLight(lightingData.shadowCoord, lightingData.positionWS, shadowMask);
    half3 mainLightResult = ShadeSingleLightBlinnPhong(surfaceData, lightingData, mainLight);


    //次光源结果
    half3 additionalLightSumResult = 0;
    int additionalLightsCount = GetAdditionalLightsCount();
    half rate = 1.0 / additionalLightsCount;//亮度系数
    for (int i = 0; i < additionalLightsCount; ++i)
    {
        int perObjectLightIndex = GetPerObjectLightIndex(i);
        Light light = GetAdditionalLight(perObjectLightIndex, lightingData.positionWS, shadowMask); // use original positionWS for lighting
        additionalLightSumResult += ShadeSingleLightBlinnPhong(surfaceData, lightingData, light) * rate;
    }
    return mainLightResult + additionalLightSumResult + bakedGI;
}

