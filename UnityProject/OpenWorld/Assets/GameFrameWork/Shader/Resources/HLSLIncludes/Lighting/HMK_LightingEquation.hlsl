#pragma once

#include "./HMK_PBREquation.hlsl"
#include "./HMK_IrradianceVolume.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "./../Common/HMK_Shadow.hlsl"
#include "./../Common/HMK_Common.hlsl"
#include "./../Common/Fog.hlsl"
#include "./../Common/Global.hlsl"


#define kDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)


struct HMKSurfaceData
{
    half3 albedo;//固有色
    half alpha;//透明度
    half metallic;//金属度
    half roughness;//粗糙度
    half occlusion;//遮蔽
    half3 emission;//自发光

};

struct HMKLightingData
{
    float3 normalWS;
    float3 positionWS;
    float3 viewDirWS;
    float4 shadowCoord;
    float2 lightmapUV;
};

void ApplyWetness(inout half3 albedo, inout half roughness, inout half metallic)
{
    //潮湿压暗非金属物体  FarCry6方法
    albedo *= lerp(1.0f, 0.25f, _Wetness * (1.0 - metallic));

    //顽皮狗方法
    // half3 albedoSqr = albedo * albedo;
    // albedo = lerp(albedo, albedoSqr, ClampRange(_Wetness, 0.2, 0.55));

    // half roughnessAdjustment = lerp(0.4f, -0.6f, sqrt(roughness));
    // half finalRoughness = saturate(0.6f + roughnessAdjustment);
    // finalRoughness = clamp(finalRoughness, roughness, 0.9f);
    // roughness = lerp(finalRoughness, roughness, _Wetness);

    roughness = lerp(roughness, 0.2, ClampRange(_Wetness, 0.2, 1.0));

    // occlusion = lerp(occlusion, 1.0, ClampRange(_Wetness, 0.45, 0.95));

}


void ApplyWetnessCharacter(inout half3 albedo, inout half roughness, inout half metallic)
{
    //潮湿压暗非金属物体  FarCry6方法
    albedo *= lerp(1.0f, 0.8f, _Wetness * (1.0 - metallic));

    roughness = lerp(roughness, 0.2, ClampRange(_Wetness, 0.2, 1.0));
}


HMKSurfaceData InitSurfaceData(half3 albedo, half alpha, half metallic, half roughness, half occlusion, half3 emission)
{


    #ifdef CHARACTER //如果是角色的话 单独处理潮湿度
        ApplyWetnessCharacter(albedo, roughness, metallic);
    #elif defined NOT_SCENE//为了解决UI Avater 受潮湿度影响
        ApplyWetness(albedo, roughness, metallic);
    #endif



    HMKSurfaceData surfaceData;
    surfaceData.albedo = albedo;
    surfaceData.alpha = saturate(alpha);
    surfaceData.metallic = saturate(metallic);
    surfaceData.roughness = saturate(roughness);
    surfaceData.occlusion = saturate(occlusion);
    surfaceData.emission = emission;
    return surfaceData;
}

HMKSurfaceData InitSurfaceData(half3 albedo, half alpha, half metallic, half roughness, half occlusion)
{
    return InitSurfaceData(albedo, alpha, metallic, roughness, occlusion, 0);
}

HMKLightingData InitLightingData(float3 positionWS, float3 normalWS, float2 lightmapUV)
{
    HMKLightingData lightingData;
    lightingData.normalWS = normalize(normalWS);
    lightingData.viewDirWS = normalize(GetWorldSpaceViewDir(positionWS));
    lightingData.positionWS = positionWS;
    lightingData.shadowCoord = TransformWorldToShadowCoord(positionWS);
    lightingData.lightmapUV = lightmapUV;
    return lightingData;
}

HMKLightingData InitLightingData(float3 positionWS, float3 normalWS)
{
    return InitLightingData(positionWS, normalWS, 0);
}




///////////////////////////////////////////////////////////////////////////////
//                       GI                                                  //
///////////////////////////////////////////////////////////////////////////////

half3 ShadeGI(HMKLightingData lightingData)
{
    return ShadeGI(lightingData.normalWS);
}

half3 ShadeCustomGI(HMKLightingData lightingData)
{
    return ShadeCustomGI(lightingData.normalWS);
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
    half4 transformCoords = half4(1, 1, 0, 0);
    half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
    #if defined(LIGHTMAP_ON)
        return HMKSampleSingleLightmap(lightmapUV, transformCoords, decodeInstructions) * _BakedIndirectStrength + ShadeCustomGI(normalWS) ;
    #else
        return half3(0.0, 0.0, 0.0);
    #endif
}

//只有角色才受光线探针影响
half3 MixSHOrLightmap(HMKLightingData lightingData)
{
    #if defined(LIGHTMAP_ON)
        return HMKSampleLightmap(lightingData.lightmapUV, lightingData.normalWS);
    #else
        return ShadeCustomGI(lightingData);
        // return half3(0.0, 0.0, 0.0);
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
    half3 F0;
    half roughness;
};


//根据粗糙度计算立方体贴图的Mip等级
//同PerceptualRoughnessToMipmapLevel
half CubeMapMip(half roughness)
{
    half mip_roughness = (roughness) * (1.7 - 0.7 * roughness);//Unity内部不是线性 调整下拟合曲线求近似
    half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;//把粗糙度remap到0-6 7个阶级 然后进行lod采样
    return mip;
}

half3 GlossyEnvironmentReflection(half roughness, half3 reflectVector, half occlusion)
{
    //计算Mip等级，用于采样CubeMap
    half mip = CubeMapMip(roughness);
    //采样
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
half3 fresnelSchlickRoughness(half cosTheta, half3 F0, half roughness)
{
    return F0 + (max(half3(1, 1, 1) * (1 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

half3 ShadeGlobalIllumination(HMKSurfaceData surfaceData, HMKLightingData lightingData, HMKPBRParam PBRParam, half3 radiance, half3 giResult)
{
    half roughness = PBRParam.roughness;
    //--------间接光照镜面反射---------
    float3 reflectVec = reflect(-lightingData.viewDirWS, lightingData.normalWS);
    half3 indirectSpecularResult = GlossyEnvironmentReflection(roughness, reflectVec, surfaceData.occlusion);

    half surfaceReduction = 1.0 / (roughness * roughness + 1.0);            //压暗非金属的反射
    // surfaceReduction = lerp(surfaceReduction, 0.8, _Wetness);
    surfaceReduction = lerp(surfaceReduction, 0.2, ClampRange(_Wetness, 0.2, 0.7));
    half oneMinusReflectivity = kDielectricSpec.a - kDielectricSpec.a * surfaceData.metallic;
    half grazingTerm = saturate((1 - PBRParam.roughness) + (1 - oneMinusReflectivity));
    half t = pow(1 - PBRParam.NdotV, 5);
    half3 FresnelLerp = lerp(PBRParam.F0, grazingTerm, t);                   //控制反射的菲涅尔和金属色
    half3 iblSpecularResult = surfaceReduction * indirectSpecularResult * FresnelLerp ;
    // return iblSpecularResult;
    //--------间接光照漫反射-----------
    half occlusion = surfaceData.occlusion;

    half3 iblDiffuse = giResult;
    // return iblDiffuse;

    half3 Flast = fresnelSchlickRoughness(max(PBRParam.NdotV, 0.0), PBRParam.F0, roughness);
    Flast = saturate(Flast);

    half3 kdLast = (1 - Flast) * (1 - surfaceData.metallic);//压暗边缘，边缘处应当有更多的镜面反射
    // return kdLast;
    half3 iblDiffuseResult = iblDiffuse * kdLast * surfaceData.albedo ;
    // return iblDiffuseResult;

    half3 indirectResult = iblSpecularResult + iblDiffuseResult * occlusion ;
    indirectResult *= radiance;
    return indirectResult;
}

half3 ShadeGlobalIllumination(HMKSurfaceData surfaceData, HMKLightingData lightingData, HMKPBRParam PBRParam, half3 radiance)
{
    return ShadeGlobalIllumination(surfaceData, lightingData, PBRParam, radiance, MixSHOrLightmap(lightingData));
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
    // float ndotl = dot(lightingData.normalWS, light.direction);
    float NdotL = max(saturate(dot(lightingData.normalWS, light.direction)), 0.000001);
    // float halfNdotL = ndotl * 0.5 + 0.5;

    float VdotH = max(saturate(dot(lightingData.viewDirWS, H)), 0.000001);
    float NdotH = max(saturate(dot(lightingData.normalWS, H)), 0.000001);

    float HdotL = max(saturate(dot(H, L)), 0.000001);
    float NdotV = PBRParam.NdotV;
    half roughness = PBRParam.roughness;
    half3 F0 = PBRParam.F0;

    //********直接光照*********
    //--------直接光照镜面反射---------
    //原始公式
    // float D = D_Function(roughness, NdotH);
    // return D;
    // float3 F = F_Function(HdotL, F0);
    // return F;
    // float G = G_Function(NdotL, NdotV, roughness, PBRParam.kInDirectLight);
    // return G;
    // float visibility = Visibility(NdotL, NdotV, roughness);

    // half3 mainSpecular = (D * G * F) / (NdotV * NdotL * 4);
    // half3 mainSpecular = (D * F * visibility);


    //以下为Lighting.hlsl 优化方法
    half roughness2 = roughness * roughness;
    half d = NdotH * NdotH * (roughness2 - 1) + 1.00001f;
    half normalizationTerm = roughness * 4 + 2;
    half LoH2 = HdotL * HdotL;
    half specularTerm = (roughness2) / ((d * d) * max(0.1h, LoH2) * normalizationTerm);

    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles

    half3 mainSpecular = specularTerm * F0;
    half3 mainSpecularResult = mainSpecular;

    //--------直接光照漫反射-----------
    // half3 kd = (1 - F) * (1 - surfaceData.metallic);
    // 移动端优化 F 直接近似为0.04
    half3 kd = (1 - 0.04) * (1 - surfaceData.metallic);
    kd = saturate(kd);
    half3 mainDiffColor = kd * surfaceData.albedo  ;
    // mainDiffColor /= PI;
    // return mainDiffColor;

    //--------直接光部分-------
    half3 lightResult = (mainSpecularResult * light.shadowAttenuation + mainDiffColor) * NdotL ;
    lightResult *= light.color;

    // half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation ;
    // lightResult *= lightAttenuation;
    lightResult *= radiance;
    return lightResult;
}

//用于额外灯光
half3 ShadeSingleLightPBR(HMKSurfaceData surfaceData, HMKLightingData lightingData, Light light, HMKPBRParam PBRParam)
{
    return ShadeSingleLightPBR(surfaceData, lightingData, light, PBRParam, 1);
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


    float lightAttenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation ;
    float halfLambertShadow = NdotL * lightAttenuation;

    lightAttenuation = halfLambertShadow;
    // half3 lerpShadowColor = lerp(_GlobalShadowColorNear, _GlobalShadowColorFar, saturate(lightingData.depth + _GlobalShadowLerp));

    half3 shadowColor = lerp(_GlobalShadowColor.rgb, 1, saturate(lightAttenuation));
    // shadowColor = lerp(shadowColor, lightAttenuation, _GlobalShadowColor.a);
    return shadowColor;
}

half3 ShadeAllLightPBR(HMKSurfaceData surfaceData, HMKLightingData lightingData)
{
    // return surfaceData.metallic;
    // return saturate(1 - pow(lightingData.depth, _GlobalShadowLerp));
    half roughness = surfaceData.roughness * surfaceData.roughness;
    // float squareRoughness = roughness * roughness;

    // half4 shadowMask = half4(1, 1, 1, 1);
    // Light mainLight = GetMainLight(lightingData.shadowCoord, lightingData.positionWS, shadowMask);
    Light mainLight = GetMainLight(lightingData.shadowCoord);
    float3 H = SafeNormalize(lightingData.viewDirWS + mainLight.direction);

    float NdotL = max(saturate(dot(lightingData.normalWS, mainLight.direction)), 0.000001);
    // return NdotL;
    float NdotV = max(saturate(dot(lightingData.normalWS, lightingData.viewDirWS)), 0.000001);
    // return NdotV;
    // float VdotH = max(saturate(dot(lightingData.viewDirWS, H)), 0.000001);
    // float LdotH = max(saturate(dot(lightingData.viewDirWS, H)), 0.000001);
    // float NdotH = max(saturate(dot(lightingData.normalWS, H)), 0.000001);

    half3 F0 = lerp(kDielectricSpec.rgb, surfaceData.albedo, surfaceData.metallic);

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
    finalResult = saturate(finalResult);
    finalResult += surfaceData.emission;//再加上自发光

    // #if _FOG_ON
    //     finalResult = ApplyFog(finalResult, lightingData.positionWS);
    // #endif
    return finalResult;
}



#include "./HMK_LightingEquation_Character.hlsl"