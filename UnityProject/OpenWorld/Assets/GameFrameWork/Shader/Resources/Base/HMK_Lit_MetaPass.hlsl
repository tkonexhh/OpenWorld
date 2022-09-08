#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"


struct Attributes
{
    float4 positionOS: POSITION;
    float3 normalOS: NORMAL;
    float2 uv0: TEXCOORD0;
    float2 uv1: TEXCOORD1;
    float2 uv2: TEXCOORD2;
    #ifdef _TANGENT_TO_WORLD
        float4 tangentOS: TANGENT;
    #endif
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
};

half Alpha(half albedoAlpha, half4 color, half cutoff)
{
    half alpha = color.a;

    #if defined(_ALPHATEST_ON)
        clip(alpha - cutoff);
    #endif

    return alpha;
}

inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    half4 albedoAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 MRAE = SAMPLE_TEXTURE2D(_PBRMap, sampler_PBRMap, uv);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    outSurfaceData.metallic = MRAE.r * _MetallicScale;
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
    outSurfaceData.smoothness = (1 - MRAE.g) * _RoughnessScale;
    outSurfaceData.occlusion = LerpWhiteTo(MRAE.b, _OcclusionScale) ;
    outSurfaceData.emission = MRAE.a * _EmissionScale * _EmissionColor;

    half4 var_NormalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
    half3 normalTS = UnpackNormalScale(var_NormalMap, _BumpScale);
    outSurfaceData.normalTS = UnpackNormalScale(var_NormalMap, _BumpScale);;
    outSurfaceData.clearCoatMask = 0.0h;
    outSurfaceData.clearCoatSmoothness = 0.0h;
}


Varyings UniversalVertexMeta(Attributes input)
{
    Varyings output;
    output.positionCS = MetaVertexPosition(input.positionOS, input.uv1, input.uv2, unity_LightmapST, unity_DynamicLightmapST);
    // output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.uv = TRANSFORM_TEX(input.uv0, _BaseMap);
    return output;
}

half4 UniversalFragmentMeta(Varyings input): SV_Target
{
    SurfaceData surfaceData;
    InitializeStandardLitSurfaceData(input.uv, surfaceData);

    BRDFData brdfData;
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

    MetaInput metaInput;
    metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
    metaInput.SpecularColor = surfaceData.specular;
    metaInput.Emission = surfaceData.emission ;
    // return half4(metaInput.SpecularColor, 1);
    return MetaFragment(metaInput);
}


Varyings VertexMeta(Attributes input)
{
    return UniversalVertexMeta(input);
}

half4 FragmentMeta(Varyings input): SV_Target
{
    return UniversalFragmentMeta(input);
}

