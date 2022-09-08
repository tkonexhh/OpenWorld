#pragma once

#include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
#include "./../HLSLIncludes/Common/HMK_Normal.hlsl"
#include "./../HLSLIncludes/Common/HMK_Common.hlsl"

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    float3 normalOS: NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float3 positionWS: TEXCOORD2;
    float2 uv: TEXCOORD0;
    float3 normalWS: NORMAL;
    float3 tangentWS: TANGENT;
    float3 bitangentWS: TEXCOORD4;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


#ifdef _TERRAIN_BLEND_HEIGHT
half3 HeightBasedSplatModify(inout half4 splatControl0, inout half4 splatControl1, in half4 albedos[8])
{
    // float heightBias = 0.2;
    half heights[8];
    heights[0] = albedos[0].a * splatControl0.r;
    heights[1] = albedos[1].a * splatControl0.g;
    heights[2] = albedos[2].a * splatControl0.b;
    heights[3] = albedos[3].a * splatControl0.a;
    heights[4] = albedos[4].a * splatControl1.r;
    heights[5] = albedos[5].a * splatControl1.g;
    heights[6] = albedos[6].a * splatControl1.b;
    heights[7] = albedos[7].a * splatControl1.a;

    half maxHeight = max(heights[0], max(heights[1], max(heights[2], max(heights[3], max(heights[4], max(heights[5], max(heights[6], heights[7]))))))) - _HeightBias;

    heights[0] = max(heights[0] - maxHeight, 0) * splatControl0.r;
    heights[1] = max(heights[1] - maxHeight, 0) * splatControl0.g;
    heights[2] = max(heights[2] - maxHeight, 0) * splatControl0.b;
    heights[3] = max(heights[3] - maxHeight, 0) * splatControl0.a;
    heights[4] = max(heights[4] - maxHeight, 0) * splatControl1.r;
    heights[5] = max(heights[5] - maxHeight, 0) * splatControl1.g;
    heights[6] = max(heights[6] - maxHeight, 0) * splatControl1.b;
    heights[7] = max(heights[7] - maxHeight, 0) * splatControl1.a;
    return
    (albedos[0].rgb * heights[0]
    + albedos[1].rgb * heights[1]
    + albedos[2].rgb * heights[2]
    + albedos[3].rgb * heights[3]
    + albedos[4].rgb * heights[4]
    + albedos[5].rgb * heights[5]
    + albedos[6].rgb * heights[6]
    + albedos[7].rgb * heights[7])
    / (heights[0] + heights[1] + heights[2] + heights[3] + heights[4] + heights[5] + heights[6] + heights[7]);
}
#endif

void SplatmapMix(float2 uv, half4 splatControl0, half4 splatControl1, float3 normalWS, float3 posWS, inout half3 albedo, inout float roughness, inout float3 outNormalWS)
{

    half4 albedos[8];
    albedos[0] = SAMPLE_TEXTURE2D(_Splat0, sampler_Splat0, uv);
    albedos[1] = SAMPLE_TEXTURE2D(_Splat1, sampler_Splat0, uv);
    albedos[2] = SAMPLE_TEXTURE2D(_Splat2, sampler_Splat0, uv);
    albedos[3] = SAMPLE_TEXTURE2D(_Splat3, sampler_Splat0, uv);
    albedos[4] = SAMPLE_TEXTURE2D(_Splat4, sampler_Splat0, uv);
    albedos[5] = SAMPLE_TEXTURE2D(_Splat5, sampler_Splat0, uv);
    albedos[6] = SAMPLE_TEXTURE2D(_Splat6, sampler_Splat0, uv);
    albedos[7] = SAMPLE_TEXTURE2D(_Splat7, sampler_Splat0, uv);

    half4 nras[8];
    nras[0] = SAMPLE_TEXTURE2D(_NRA0, sampler_NRA0, uv);
    nras[1] = SAMPLE_TEXTURE2D(_NRA1, sampler_NRA0, uv);
    nras[2] = SAMPLE_TEXTURE2D(_NRA2, sampler_NRA0, uv);
    nras[3] = SAMPLE_TEXTURE2D(_NRA3, sampler_NRA0, uv);
    nras[4] = SAMPLE_TEXTURE2D(_NRA4, sampler_NRA0, uv);
    nras[5] = SAMPLE_TEXTURE2D(_NRA5, sampler_NRA0, uv);
    nras[6] = SAMPLE_TEXTURE2D(_NRA6, sampler_NRA0, uv);
    nras[7] = SAMPLE_TEXTURE2D(_NRA7, sampler_NRA0, uv);

    albedo = 0;
    

    #ifdef _TERRAIN_BLEND_HEIGHT
        albedo = HeightBasedSplatModify(splatControl0, splatControl1, albedos);
    #else
        albedo += albedos[0].rgb * splatControl0.r ;
        albedo += albedos[1].rgb * splatControl0.g ;
        albedo += albedos[2].rgb * splatControl0.b ;
        albedo += albedos[3].rgb * splatControl0.a ;
        albedo += albedos[4].rgb * splatControl1.r ;
        albedo += albedos[5].rgb * splatControl1.g ;
        albedo += albedos[6].rgb * splatControl1.b ;
        albedo += albedos[7].rgb * splatControl1.a ;
    #endif

    roughness = 0;
    roughness += Luminance(albedos[0].rgb) * splatControl0.r;
    roughness += Luminance(albedos[1].rgb) * splatControl0.g;
    roughness += Luminance(albedos[2].rgb) * splatControl0.b;
    roughness += Luminance(albedos[3].rgb) * splatControl0.a;
    roughness += Luminance(albedos[4].rgb) * splatControl1.r;
    roughness += Luminance(albedos[5].rgb) * splatControl1.g;
    roughness += Luminance(albedos[6].rgb) * splatControl1.b;
    roughness += Luminance(albedos[7].rgb) * splatControl1.a;
    roughness = 1 - roughness;

    outNormalWS = 0;
    outNormalWS += HeightToNormal(albedos[0].a, normalWS, posWS) * splatControl0.r;
    outNormalWS += HeightToNormal(albedos[1].a, normalWS, posWS) * splatControl0.g;
    outNormalWS += HeightToNormal(albedos[2].a, normalWS, posWS) * splatControl0.b;
    outNormalWS += HeightToNormal(albedos[3].a, normalWS, posWS) * splatControl0.a;
    outNormalWS += HeightToNormal(albedos[4].a, normalWS, posWS) * splatControl1.r;
    outNormalWS += HeightToNormal(albedos[5].a, normalWS, posWS) * splatControl1.g;
    outNormalWS += HeightToNormal(albedos[6].a, normalWS, posWS) * splatControl1.b;
    outNormalWS += HeightToNormal(albedos[7].a, normalWS, posWS) * splatControl1.a;
}


///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

Varyings vert(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    float3 tangentWS = cross(normalWS, float3(0, 0, 1));//TransformObjectToWorldDir(input.tangentOS);
    half tangentSign = -1;
    float3 bitangentWS = cross(normalWS, tangentWS) * tangentSign;
    output.normalWS = normalWS;
    output.tangentWS = tangentWS;
    output.bitangentWS = bitangentWS;
    output.uv = input.uv;

    return output;
}


half4 frag(Varyings input): SV_Target
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    float2 uv = input.uv;
    float3 normalWS = normalize(input.normalWS);

    half4 var_Control0 = SAMPLE_TEXTURE2D(_Control0, sampler_Control0, uv);
    half4 var_Control1 = SAMPLE_TEXTURE2D(_Control1, sampler_Control0, uv);

    float3 uv_Terrain = (input.positionWS.xyz * _UVScale);


    half3 albedo;
    half roughness;
    float3 outNormalWS;

    SplatmapMix(uv_Terrain.xz, var_Control0, var_Control1, normalWS, input.positionWS, albedo, roughness, outNormalWS);

    float occlusion = 1;
    
    outNormalWS.xy * 2;
    normalWS = outNormalWS;//TransformTangentToWorld(TransformWorldToTangent(outNormalWS), TBN);

    roughness = _RoughnessScale * roughness;
    occlusion = LerpWhiteTo(occlusion, _OcclusionScale);
    // normalWS = normalize(lerp(normalWS, half3(0, 1, 0), ClampRange(_Wetness * roughness, 0, 1)));
    
    HMKSurfaceData surfaceData = InitSurfaceData(albedo, 1, 0, roughness, occlusion);
    HMKLightingData lightingData = InitLightingData(input.positionWS, normalWS);
    half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
    
    return half4(finalRGB, surfaceData.alpha);
}