#ifndef RENDERPIPELINE_DEPTH_ONLY_PASS_INCLUDED
#define RENDERPIPELINE_DEPTH_ONLY_PASS_INCLUDED

#if defined(LOD_FADE_CROSSFADE)
    #include "./../ShaderLibrary/LODCrossFade.hlsl"
#endif

struct Attributes
{
    float4 position: POSITION;
    float2 texcoord: TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv: TEXCOORD0;
    float4 positionCS: SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings DepthOnlyVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.positionCS = TransformObjectToHClip(input.position.xyz);
    return output;
}

half DepthOnlyFragment(Varyings input): SV_TARGET
{
    #ifdef _ALPHATEST_ON
        half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
        half4 baseColor = baseMap * _BaseColor;
        clip(baseColor.a - _Cutoff);
    #endif

    // #ifdef LOD_FADE_CROSSFADE
    //     LODFadeCrossFade(input.positionCS);
    // #endif

    return input.positionCS.z;
}

#endif

