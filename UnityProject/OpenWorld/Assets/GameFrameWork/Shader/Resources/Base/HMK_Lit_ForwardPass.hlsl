#pragma once

#include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    #if defined(LIGHTMAP_ON)
        float2 lightmapUV: TEXCOORD1;
    #endif
    half3 normalOS: NORMAL;
    half4 tangentOS: TANGENT;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float3 positionWS: TEXCOORD2;
    float2 uv: TEXCOORD0;
    #if defined(LIGHTMAP_ON)
        HMK_DECLARE_LIGHTMAP(lightmapUV, 1);
    #endif
    half3 normalWS: NORMAL;
    half3 tangentWS: TEXCOORD3;
    half3 bitangentWS: TEXCOORD4;
    half fogFactor: TEXCOORD5;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
TEXTURE2D(_PBRMap);SAMPLER(sampler_PBRMap);
TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);


half4 GetFinalBaseColor(Varyings input)
{
    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) ;
}


HMKSurfaceData InitSurfaceData(Varyings input)
{
    half3 mra = SAMPLE_TEXTURE2D(_PBRMap, sampler_PBRMap, input.uv).rgb;// tex2D(pbrMap, input.uv).rgb;
    float4 finalBaseColor = GetFinalBaseColor(input);
    
    half3 albedo = finalBaseColor.rgb * _BaseColor;
    half alpha = finalBaseColor.a;
    #if defined(_PBRMAP_ON)
        half metallic = mra.r * _MetallicScale;
        half roughness = mra.g * _RoughnessScale;
        half occlusion = LerpWhiteTo(mra.b, _OcclusionScale);
    #else
        half metallic = _MetallicScale;
        half roughness = _RoughnessScale;
        half occlusion = _OcclusionScale;
    #endif

    return InitSurfaceData(albedo, alpha, metallic, roughness, occlusion);
}


HMKLightingData InitLightingData(Varyings input)
{
    //采样法线贴图
    half4 var_NormalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv);
    // half3 bitangentWS = (cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w);
    half3 normalTS = UnpackNormalScale(var_NormalMap, _BumpScale);
    half3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
    float3 normalWS = TransformTangentToWorld(normalTS, TBN);
    #if defined(LIGHTMAP_ON)
        return InitLightingData(input.positionWS, normalWS, input.lightmapUV);
    #else
        return InitLightingData(input.positionWS, normalWS);
    #endif
}

Varyings vert(Attributes input)
{
    Varyings output;
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.uv = input.uv;
    float3 normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));
    float3 tangentWS = TransformObjectToWorldDir(input.tangentOS);
    half tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
    float3 bitangentWS = cross(normalWS, tangentWS) * tangentSign;
    half fogFactor = ComputeFogFactor(output.positionCS.z);

    output.normalWS = normalWS;
    output.tangentWS = tangentWS;
    output.bitangentWS = bitangentWS;
    output.fogFactor = fogFactor;
    
    #if defined(LIGHTMAP_ON)
        HMK_OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    #endif
    return output;
}


float4 frag(Varyings input): SV_Target
{
    HMKSurfaceData surfaceData = InitSurfaceData(input);
    HMKLightingData lightingData = InitLightingData(input);
    
    #if defined(_ALPHATEST_ON)
        clip(surfaceData.alpha - _Cutoff);
    #endif
    
    half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
    finalRGB = MixFog(finalRGB, input.fogFactor);
    return half4(finalRGB, surfaceData.alpha);
}