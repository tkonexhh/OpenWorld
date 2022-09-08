#ifndef UNIVERSAL_DEPTH_ONLY_PASS_INCLUDED
#define UNIVERSAL_DEPTH_ONLY_PASS_INCLUDED


// TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv: TEXCOORD0;
    float4 positionCS: SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings DepthOnlyVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.uv = input.uv;//TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    return output;
}

half4 DepthOnlyFragment(Varyings input): SV_TARGET
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    #if defined(_ALPHATEST_ON)
        half4 var_Base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
        half alpha = var_Base.a;
        clip(alpha - _Cutoff);
    #endif

    
    return 0;
}
#endif
