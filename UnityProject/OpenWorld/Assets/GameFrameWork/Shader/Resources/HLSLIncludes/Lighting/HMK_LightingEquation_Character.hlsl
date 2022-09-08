#pragma once

#include "./HMK_LightingEquation.hlsl"

struct HMKSurfaceDataNPR
{
    half3 albedo;//固有色
    half alpha;//透明度
    half3 emission;//自发光

};
struct HMKLightDataNPR
{
    half3 ShadowMultColor;//基础阴影颜色
    half3 DarkShadowMultColor;//次级阴影颜色
    half SkinMask;
    half ShadowSwitch;
    float3 normalWS;
};


HMKLightDataNPR InitLightDataNPR(half3 ShadowMultColor, half3 DarkShadowMultColor, float3 normalWS, half SkinMask, half ShadowSwitch)
{

    HMKLightDataNPR lightingDataNpr;

    lightingDataNpr.DarkShadowMultColor = DarkShadowMultColor;

    lightingDataNpr.ShadowMultColor = ShadowMultColor;
    lightingDataNpr.SkinMask = SkinMask;
    lightingDataNpr.normalWS = normalWS;
    lightingDataNpr.ShadowSwitch = ShadowSwitch;
    return lightingDataNpr;
}



half3 Saturation_float(float3 In, float Saturation)
{
    float luma = dot(In, float3(0.2126729, 0.7151522, 0.0721750));
    return luma.xxx + Saturation.xxx * (In - luma.xxx);
}



///////////////////////////////////////////////////////////////////////////////
//                     Shade Light character                                 //
///////////////////////////////////////////////////////////////////////////////

half3 ShadeGlobalIlluminationCharacter(HMKSurfaceData surfaceData, HMKLightingData lightingData, HMKPBRParam PBRParam, half3 radiance)
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
    // half4 irradiance = ShadeIrradiance(lightingData);
    // half occlusion = min(surfaceData.occlusion, irradiance.a);
    half occlusion = surfaceData.occlusion;
    // return lightingData.normalWS;
    //获取球谐光照
    half3 iblDiffuse = ShadeGI(lightingData) * _BakedIndirectStrength + ShadeCustomGI(lightingData.normalWS);
    // return iblDiffuse;

    half3 Flast = fresnelSchlickRoughness(max(PBRParam.NdotV, 0.0), PBRParam.F0, roughness);
    Flast = saturate(Flast);

    half3 kdLast = max((1 - Flast) * (1 - surfaceData.metallic), 0.3);//压暗边缘，边缘处应当有更多的镜面反射

    // return kdLast;
    half3 iblDiffuseResult = iblDiffuse * kdLast * surfaceData.albedo ;
    // return iblDiffuseResult;



    half3 indirectResult = (iblSpecularResult + iblDiffuseResult * occlusion);
    indirectResult *= radiance;
    return indirectResult;
}

half3 ShadeSingleLightPBRCharacter(HMKSurfaceData surfaceData, HMKLightingData lightingData, Light light, HMKPBRParam PBRParam, half3 radiance)
{
    float3 L = normalize(light.direction);
    float3 V = SafeNormalize(lightingData.viewDirWS);
    float3 H = SafeNormalize(V + L);
    // half NdotL = dot(lightingData.normalWS, light.direction) * 0.5 + 0.5;
    float ndotl = dot(lightingData.normalWS, light.direction);
    // float NdotL = max(saturate(dot(lightingData.normalWS, light.direction)), 0.000001);
    float halfNdotL = ndotl * 0.5 + 0.5 ;

    float VdotH = max(saturate(dot(lightingData.viewDirWS, H)), 0.000001);
    float NdotH = max(saturate(dot(lightingData.normalWS, H)), 0.000001);

    float HdotL = max(saturate(dot(H, L)), 0.000001);
    float NdotV = PBRParam.NdotV;
    half roughness = PBRParam.roughness;
    half3 F0 = PBRParam.F0;

    //********直接光照*********
    //--------直接光照镜面反射---------


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
    half3 lightResult = (mainSpecularResult * light.shadowAttenuation + mainDiffColor) * halfNdotL;


    // float luma = dot(light.color, float3(0.2126729, 0.7151522, 0.0721750));
    // half lightColorInt = luma.x;

    //  light.color = Saturation_float(light.color, 1);
    // light.color = luma.xxx + clamp(saturate(1 - lightColorInt), 0, 0.5) * (light.color - luma.xxx) ;

    // light.color *= clamp(saturate(1 - lightColorInt), 0.2, 1);
    // light.color = clamp(light.color, 0.8, 1.2);
    lightResult *= light.color ;

    // half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation ;
    // lightResult *= lightAttenuation;
    lightResult *= radiance;
    return lightResult;
}

//用于额外灯光
half3 ShadeSingleLightPBRCharacter(HMKSurfaceData surfaceData, HMKLightingData lightingData, Light light, HMKPBRParam PBRParam)
{
    return ShadeSingleLightPBRCharacter(surfaceData, lightingData, light, PBRParam, 1);
}


half3 ShadeAllLightPBRCharacter(HMKSurfaceData surfaceData, HMKLightingData lightingData)
{
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

    half3 F0 = lerp(kDielectricSpec.rgb, surfaceData.albedo, surfaceData.metallic);

    //准备公共变量
    HMKPBRParam PBRParam;
    PBRParam.NdotV = NdotV;
    PBRParam.kInDirectLight = pow(roughness + 1, 2) / 8;
    PBRParam.F0 = F0;
    PBRParam.roughness = roughness;
    mainLight.color = clamp(mainLight.color, 0.5, 1);
    half3 radiance = CalculateRadiance(mainLight, lightingData);
    // radiance = mainLight.shadowAttenuation;
    // return radiance;
    //********直接光照*********
    half3 mainLightResult = ShadeSingleLightPBRCharacter(surfaceData, lightingData, mainLight, PBRParam, radiance);
    // return mainLightResult;
    //********间接光照*********
    half3 indirectResult = ShadeGlobalIlluminationCharacter(surfaceData, lightingData, PBRParam, radiance);
    // return indirectResult;
    // return ShadeGI(lightingData);
    //******额外光照*****
    half3 additionalLightSumResult = ShadeAdditionalLight(surfaceData, lightingData, PBRParam);


    half3 finalResult = saturate(mainLightResult + indirectResult + additionalLightSumResult);

    finalResult += surfaceData.emission;//再加上自发光

    // #if _FOG_ON
    //     finalResult = ApplyFog(finalResult, lightingData.positionWS);
    // #endif
    return finalResult;
}

half3 ShaderNRP(half3 color, HMKLightDataNPR lightingData, Light light)
{
    // return ShadeGI(lightingData);
    // color += ShadeGI(normalWS) * 1.5f;

    half3 lightColor = light.color;
    half3 lightInt = Saturation_float(lightColor, 0);
    lightInt = clamp(lightInt, 0.65, 0.8);
    // return float4(lightInt, 1);
    //暗部处理
    half3 ShadowColor = color * lightingData.ShadowMultColor;
    half3 DarkShadowColor = color * lightingData.DarkShadowMultColor.rgb;
    half3 worldLight = normalize(float3(light.direction.x, 0, light.direction.z));
    half halfLambert = dot(lightingData.normalWS, worldLight) * 0.5 + 0.5;
    half3 ShallowShadowColor = float3(1, 0, 0);
    half rampS = smoothstep(0, 0.3, halfLambert - 0.5);
    half DarkShadowArea = 0.4;
    half var_DarkShadowArea = lightingData.ShadowSwitch?1: DarkShadowArea;

    half DarkShadowSmooth = 0.3;

    half rampDS = smoothstep(0, DarkShadowSmooth, halfLambert - DarkShadowArea) ;
    half FixDarkShadow = 1;
    DarkShadowColor = rampDS * (FixDarkShadow * ShadowColor + (1 - FixDarkShadow) * ShallowShadowColor) + (1 - rampDS) * DarkShadowColor;
    DarkShadowColor.rgb = lerp(DarkShadowColor.rgb, ShadowColor, rampDS);
    ShallowShadowColor = lerp(ShadowColor, color, rampS);


    //NPR颜色处理
    half4 NPRFinalColor;
    NPRFinalColor.rgb = rampDS * ShallowShadowColor + (1 - rampDS) * DarkShadowColor ;


    half SkinMask = lightingData.SkinMask;
    NPRFinalColor.rgb = lightInt * (1 - SkinMask) * NPRFinalColor.rgb ;//* _ColorTint.rgb ;// + Emission * _EmissiveColorTint.rgb;
    float3 NPRcolor = (1 - SkinMask) * color ;//* _ColorTint.rgb ;

    float3 InShadowColor = (NPRcolor * lightingData.DarkShadowMultColor) * lightInt ;



    NPRFinalColor.rgb = (lightingData.ShadowSwitch)?(InShadowColor): (NPRFinalColor.rgb);
    // half3 iblDiffuse = ShadeGI(lightingData.normalWS) * _BakedIndirectStrength;
    // return half4(iblDiffuse, 1);
    // NPRFinalColor.rgb += iblDiffuse;

    return saturate(NPRFinalColor);
}


half3 ShaderNRP(half3 color, HMKLightDataNPR lightingData)
{
    return ShaderNRP(color, lightingData, GetMainLight());
}
