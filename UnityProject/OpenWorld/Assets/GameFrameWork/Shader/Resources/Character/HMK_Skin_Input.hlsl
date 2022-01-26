﻿#ifndef INPUT_LUXLWRP_BASE_INCLUDED
#define INPUT_LUXLWRP_BASE_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//  defines a bunch of helper functions (like lerpwhiteto)
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
//  defines SurfaceData, textures and the functions Alpha, SampleAlbedoAlpha, SampleNormal, SampleEmission
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
//  defines e.g. "DECLARE_LIGHTMAP_OR_SH"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "HMK_Skin_Lighting.hlsl"

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

//  Material Inputs
CBUFFER_START(UnityPerMaterial)

half4 _BaseColor;
half4 _SpecularColor;

float4 _BaseMap_ST;
half _Smoothness;

half _BumpScale;
half _Bias;

half _SkinShadowBias;
half _SkinShadowSamplingBias;

half _OcclusionStrength;

half4 _SubsurfaceColor;
half _SampleCurvature;
half _Curvature;
float2 _DistanceFade;

half _TranslucencyPower;
half _TranslucencyStrength;
half _ShadowStrength;
half _MaskByShadowStrength;
half _Distortion;
half _AmbientReflectionStrength;

//#if defined(_RIMLIGHTING)
half4 _RimColor;
half _RimPower;
half _RimMinPower;
half _RimFrequency;
half _RimPerPositionFrequency;
//#endif

//  Needed by URP 10.1. and depthnormal
half _Cutoff;
half _Surface;

half _Backscatter;
half _VertexNormal;

CBUFFER_END

//  Additional textures
TEXTURE2D(_SSSAOMap); SAMPLER(sampler_SSSAOMap);

//  Global Inputs

//  Structs
struct VertexInput
{
    float3 positionOS: POSITION;
    float3 normalOS: NORMAL;
    float4 tangentOS: TANGENT;
    float2 texcoord: TEXCOORD0;
    float2 lightmapUV: TEXCOORD1;
    half4 color: COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput
{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
    half fade: TEXCOORD9;
    #if !defined(UNITY_PASS_SHADOWCASTER) && !defined(DEPTHONLYPASS)
        DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);
        #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
            float3 positionWS: TEXCOORD2;
        #endif
        float3 normalWS: TEXCOORD3;
        float3 viewDirWS: TEXCOORD4;

        half4 fogFactorAndVertexLight: TEXCOORD6;

        float4 shadowCoord: TEXCOORD7;

    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct SurfaceDescription
{
    half3 albedo;
    half alpha;
    half3 normalTS;
    half3 diffuseNormalTS;
    half3 emission;
    half metallic;
    half3 specular;
    half smoothness;
    half occlusion;
    half translucency;
    half skinMask;
    half curvature;
};

#endif