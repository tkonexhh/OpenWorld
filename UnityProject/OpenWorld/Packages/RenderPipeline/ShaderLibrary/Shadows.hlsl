#ifndef RENDERPIPELINE_SHADOWS_INCLUDED
#define RENDERPIPELINE_SHADOWS_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"

#define MAX_SHADOW_CASCADES 4

CBUFFER_START(MainLightShadows)
int _MainLightCascadeCount;
// Last cascade is initialized with a no-op matrix. It always transforms
// shadow coord to half3(0, 0, NEAR_PLANE). We use this trick to avoid
// branching since ComputeCascadeIndex can return cascade index = MAX_SHADOW_CASCADES
float4x4 _MainLightWorldToShadow[MAX_SHADOW_CASCADES + 1];
float4 _CascadeShadowSplitSpheres[MAX_SHADOW_CASCADES];
float4 _CascadeDatas[MAX_SHADOW_CASCADES];
half4 _MainLightShadowParams;   // (x: shadowStrength, y: >= 1.0 if soft shadows, 0.0 otherwise, z: main light fade scale, w: main light fade bias)
float4 _MainLightShadowmapSize;  // (xy: 1/width and 1/height, zw: width and height)
float4 _ShadowBias; // x: depth bias, y: normal bias
CBUFFER_END

//必须和ShadowSettings.FilterMode + 1 中对应起来
#define SOFT_SHADOW_OFF    half(0.0)
#define SOFT_SHADOW_PCF3X3 half(1.0)
#define SOFT_SHADOW_PCF5X5 half(2.0)
#define SOFT_SHADOW_PCF7X7 half(3.0)

#define SOFT_SHADOW_MODE _MainLightShadowParams.y

// ShadowParams
// x: ShadowStrength
// y: 1.0 if shadow is soft, 0.0 otherwise
// z: main light fade scale
// w: main light fade bias
half4 GetMainLightShadowParams()
{
    return _MainLightShadowParams;
}

half GetMainLightShadowFade(float3 positionWS)
{
    float3 camToPixel = positionWS - _WorldSpaceCameraPos;
    float distanceCamToPixel2 = dot(camToPixel, camToPixel);
    
    float fade = saturate(distanceCamToPixel2 * float(_MainLightShadowParams.z) + float(_MainLightShadowParams.w));
    return half(fade);
}

struct ShadowSamplingData
{
    int cascadeIndex;
    half strength;
};

ShadowSamplingData GetShadowSamplingData(float3 positionWS)
{
    ShadowSamplingData data;
    data.cascadeIndex = 0;
    data.strength = GetMainLightShadowFade(positionWS);

    int i;
    for (i = 0; i < _MainLightCascadeCount; i++)
    {
        float4 sphere = _CascadeShadowSplitSpheres[i];
        float3 fromCenter = positionWS - sphere.xyz;
        float distances2 = dot(fromCenter, fromCenter);

        if (distances2 <= sphere.w * sphere.w)
        {
            break;
        }
    }

    data.cascadeIndex = i;

    return data;
}


TEXTURE2D_SHADOW(_MainLightShadowmapTexture);SAMPLER_CMP(sampler_MainLightShadowmapTexture);
TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture);SAMPLER_CMP(sampler_AdditionalLightsShadowmapTexture);
TEXTURE2D(_ScreenSpaceShadowmapTexture);SAMPLER(sampler_ScreenSpaceShadowmapTexture);



//positionSTS : Shadow Texture Space
real SampleShadowmap(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float3 positionSTS)
{
    real attenuation = real(SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, positionSTS));
    return attenuation;
}

real SampleShadowmapFiltered(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float3 positionSTS)
{
    real attenuation = real(1.0);
    if (SOFT_SHADOW_MODE == SOFT_SHADOW_PCF3X3)
    {
        // 4-tap hardware comparison
        real4 attenuation4;
        attenuation4.x = real(SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, positionSTS + float3(-_MainLightShadowmapSize.xy * 0.5, 0)));
        attenuation4.y = real(SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, positionSTS + float3(_MainLightShadowmapSize.x * 0.5, -_MainLightShadowmapSize.y * 0.5, 0)));
        attenuation4.z = real(SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, positionSTS + float3(-_MainLightShadowmapSize.x * 0.5, _MainLightShadowmapSize.y * 0.5, 0)));
        attenuation4.w = real(SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, positionSTS + float3(_MainLightShadowmapSize.xy * 0.5, 0)));
        attenuation = dot(attenuation4, real(0.25));
    }
    else if (SOFT_SHADOW_MODE == SOFT_SHADOW_PCF5X5)
    {
        real fetchesWeights[9];
        real2 fetchesUV[9];
        SampleShadow_ComputeSamples_Tent_5x5(_MainLightShadowmapSize, positionSTS.xy, fetchesWeights, fetchesUV);

        attenuation = fetchesWeights[0] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[0].xy, positionSTS.z))
        + fetchesWeights[1] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[1].xy, positionSTS.z))
        + fetchesWeights[2] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[2].xy, positionSTS.z))
        + fetchesWeights[3] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[3].xy, positionSTS.z))
        + fetchesWeights[4] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[4].xy, positionSTS.z))
        + fetchesWeights[5] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[5].xy, positionSTS.z))
        + fetchesWeights[6] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[6].xy, positionSTS.z))
        + fetchesWeights[7] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[7].xy, positionSTS.z))
        + fetchesWeights[8] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[8].xy, positionSTS.z));
    }
    else if (SOFT_SHADOW_MODE == SOFT_SHADOW_PCF7X7)
    {
        real fetchesWeights[16];
        real2 fetchesUV[16];
        SampleShadow_ComputeSamples_Tent_7x7(_MainLightShadowmapSize, positionSTS.xy, fetchesWeights, fetchesUV);

        attenuation = fetchesWeights[0] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[0].xy, positionSTS.z))
        + fetchesWeights[1] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[1].xy, positionSTS.z))
        + fetchesWeights[2] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[2].xy, positionSTS.z))
        + fetchesWeights[3] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[3].xy, positionSTS.z))
        + fetchesWeights[4] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[4].xy, positionSTS.z))
        + fetchesWeights[5] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[5].xy, positionSTS.z))
        + fetchesWeights[6] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[6].xy, positionSTS.z))
        + fetchesWeights[7] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[7].xy, positionSTS.z))
        + fetchesWeights[8] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[8].xy, positionSTS.z))
        + fetchesWeights[9] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[9].xy, positionSTS.z))
        + fetchesWeights[10] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[10].xy, positionSTS.z))
        + fetchesWeights[11] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[11].xy, positionSTS.z))
        + fetchesWeights[12] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[12].xy, positionSTS.z))
        + fetchesWeights[13] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[13].xy, positionSTS.z))
        + fetchesWeights[14] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[14].xy, positionSTS.z))
        + fetchesWeights[15] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[15].xy, positionSTS.z));
    }
    return attenuation;
}

float3 TransformWorldToShadowCoord(int cascadeIndex, float3 positionWS, float3 normalWS)
{
    float3 normalBias = normalWS * _CascadeDatas[cascadeIndex].y * _ShadowBias.y;
    float4 shadowCoord = mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS + normalBias, 1.0));
    return shadowCoord.xyz;
}

half MainLightRealtimeShadow(float3 positionSTS, ShadowSamplingData shadowSamplingData)
{
    real attenuation;
    if (SOFT_SHADOW_MODE > SOFT_SHADOW_OFF)
    {
        attenuation = SampleShadowmapFiltered(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), positionSTS);
    }
    else
    {
        attenuation = SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), positionSTS);
    }

    // shadowSamplingData.strength = step(0.5, shadowSamplingData.strength);
    attenuation = lerp(attenuation, 1, shadowSamplingData.strength);
    half4 shadowParams = GetMainLightShadowParams();
    return lerp(1.0, attenuation, shadowParams.x) ;
}

float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
{
    float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
    float scale = invNdotL * _ShadowBias.y;

    // normal bias is negative since we want to apply an inset normal offset
    positionWS = lightDirection * _ShadowBias.xxx + positionWS;
    positionWS = normalWS * scale.xxx + positionWS;
    return positionWS;
}


#endif

