#ifndef RENDERPIPELINE_LIT_FORWARD_INCLUDED
#define RENDERPIPELINE_LIT_FORWARD_INCLUDED

#include "./../ShaderLibrary/Lighting.hlsl"
#include "./../ShaderLibrary/LODCrossFade.hlsl"

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    float3 normalOS: NORMAL;
    float4 tangentOS: TANGENT;
    LIGHTMAP_ATTRIBUTE_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct Varyings
{
    float4 positionCS: SV_POSITION;
    float3 positionWS: TEXCOORD2;
    float2 uv: TEXCOORD0;
    float3 normalWS: NORMAL;
    float4 tangentWS: TANGENT;
    LIGHTMAP_VARYINGS_DATA
    UNITY_VERTEX_INPUT_INSTANCE_ID
};



Varyings LitPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    TRANSFER_LIGHTMAP_DATA(input, output);
    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.tangentWS.xyz = TransformObjectToWorldDir(input.tangentOS.xyz);
    output.tangentWS.w = input.tangentOS.w;
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    return output;
}


float4 LitPassFragment(Varyings input): SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    ClipLOD(input.positionCS, unity_LODFade.x);

    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
    half4 baseColor = baseMap * _BaseColor;

    #ifdef _ALPHATEST_ON
        clip(baseColor.a - _Cutoff);
    #endif

    #ifdef _NORMALMAP
        half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv);
        float3 normalTS = DecodeNormal(normalMap, _NormalScale);
        float3 normalWS = NormalTangentToWorld(normalTS, input.normalWS, input.tangentWS);
    #else
        float3 normalWS = normalize(input.normalWS);
    #endif



    SurfaceData surfaceData;
    surfaceData.albedo = baseColor.rgb;
    surfaceData.alpha = baseColor.a;
    surfaceData.metallic = _MetallicScale;
    surfaceData.roughness = _RoughnessScale;
    surfaceData.occlusion = _OcclusionScale;
    surfaceData.emission = _EmissionColor * _EmissionScale;

    LightingData lightingData = InitLightingData(input.positionWS, normalWS, LIGHTMAP_FRAGMENT_DATA(input));


    half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
    return half4(finalRGB, surfaceData.alpha);
}

#endif