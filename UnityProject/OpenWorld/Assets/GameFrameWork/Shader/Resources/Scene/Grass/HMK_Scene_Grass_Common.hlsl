#pragma once
#include "./../../Environment/Wind/HMK_Wind_Input.hlsl"
#include "./../../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"

///////////////////////////////////////////////////////////////////////////////
//                         Wind&Interactive                                  //
///////////////////////////////////////////////////////////////////////////////

//响应风力 自身强度 遮罩 世界坐标
void GrassApplyWind(half windStrength, half height, half mask, inout float3 positionWS)
{
    half2 uv = positionWS.xz;
    half var_Wind = SAMPLE_TEXTURE2D_LOD(_WindMap, sampler_WindMap, uv, 0);
    var_Wind -= 0.5;
    half3 windDir = _WindDir * var_Wind;

    half2 xzOffset = clamp(windDir.xz * windStrength * 0.1, -height, height) * mask;
    positionWS.xz += xzOffset;

    half2 gravityDistRate = 0;
    gravityDistRate += xzOffset;
    float gravityForce = length(gravityDistRate) / 3 ;
    //整体重力影响
    positionWS.y -= gravityForce * mask;
}

//响应动态交互
void ApplyInteractive(int _InteractivesCount, half3 _Interactives[100], half _InteractRange, half _InteractForce, half _InteractTopOffset, half _InteractBottomOffset, half mask, inout float3 positionWS)
{
    for (int n = 0; n < _InteractivesCount; n++)
    {
        half3 interPos = _Interactives[n];
        half topY = interPos.y + _InteractTopOffset;
        half bottomY = interPos.y + _InteractBottomOffset;
        half interY = clamp(positionWS.y, bottomY, topY);

        half3 dist = distance(half3(interPos.x, interY, interPos.z), positionWS);

        //倒的方向
        half blendRate = clamp(_InteractRange - dist, 0, _InteractRange);
        // output.color += -blendRate;
        half3 blendDir = normalize(positionWS - interPos);
        half3 blendForce = blendRate * blendDir * _InteractForce;//倒的力度0.2 估计值
        positionWS.y -= blendRate * 0.4;
        positionWS.xz += blendForce.xz * mask;
    }
}

///////////////////////////////////////////////////////////////////////////////
//                   Shade Light                                             //
///////////////////////////////////////////////////////////////////////////////
half3 ApplySingleDirectLight(Light light, HMKLightingData lightingData, half3 albedo, half positionOSY, half3 radiance)
{
    half3 H = normalize(light.direction + lightingData.viewDirWS);
    half directDiffuse = dot(lightingData.normalWS, light.direction) * 0.5 + 0.5;//Half Lambert

    float directSpecular = saturate(dot(lightingData.normalWS, H));//高光部分
    //pow(directSpecular,8)
    directSpecular *= directSpecular;
    directSpecular *= directSpecular;
    directSpecular *= directSpecular;
    //directSpecular *= directSpecular; //enable this line = change to pow(directSpecular,16)
    //add direct directSpecular to result
    directSpecular *= 0.3 * positionOSY * light.shadowAttenuation;
    // return directSpecular;
    half3 lighting = light.color * light.distanceAttenuation;
    // half3 lighting = light.color * light.shadowAttenuation * light.distanceAttenuation;
    half3 result = (albedo * directDiffuse + directSpecular) * lighting * radiance;
    return result;
}

half3 CompositeAllLightResults(half3 indirectResult, half3 mainLightResult, half3 additionalLightSumResult, half4 hueVariation)
{
    half3 finalResult = indirectResult + mainLightResult + additionalLightSumResult;

    #ifdef EFFECT_HUE_VARIATION
        float hueVariationAmount = frac(UNITY_MATRIX_M[0].w + UNITY_MATRIX_M[1].w + UNITY_MATRIX_M[2].w);
        float viewPos = saturate(hueVariationAmount * hueVariation.a);

        half3 shiftedColor = lerp(finalResult, hueVariation.rgb, viewPos);
        half maxBase = max(finalResult.r, max(finalResult.g, finalResult.b));
        half newMaxBase = max(shiftedColor.r, max(shiftedColor.g, shiftedColor.b));
        maxBase /= newMaxBase;
        maxBase = maxBase * 0.5f + 0.5f;
        shiftedColor.rgb *= maxBase;
        finalResult = (shiftedColor);
    #endif

    return finalResult;
}

half3 GrassShadeAllLight(HMKSurfaceData surfaceData, HMKLightingData lightingData, half positionOSY, half4 hueVariation)
{
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

    half3 mainLightResult = ApplySingleDirectLight(mainLight, lightingData, surfaceData.albedo, positionOSY, radiance);
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
        additionalLightSumResult += ApplySingleDirectLight(light, lightingData, surfaceData.albedo, positionOSY, radiance) * rate;
    }
    // return additionalLightSumResult;
    
    return CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, hueVariation);//
    // return indirectResult + mainLightResult + additionalLightSumResult;

}

half3 GrassShadeAllLight(HMKSurfaceData surfaceData, HMKLightingData lightingData, half positionOSY)
{
    return GrassShadeAllLight(surfaceData, lightingData, positionOSY, 0);
}