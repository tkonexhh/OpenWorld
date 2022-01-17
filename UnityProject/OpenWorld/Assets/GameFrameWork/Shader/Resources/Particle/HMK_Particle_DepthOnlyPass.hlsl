#ifndef UNIVERSAL_DEPTH_ONLY_PASS_INCLUDED
#define UNIVERSAL_DEPTH_ONLY_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)
#if defined(_ALPHATEST_ON)
    half _Cutoff;
#endif
CBUFFER_END

TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

struct Attributes
{
    half4 vertex: POSITION;
    half4 normal: NORMAL;
    half2 texcoord0: TEXCOORD0;
    half4 texcoord1: TEXCOORD1;
    half4 texcoord2: TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    half4 pos: SV_POSITION;
    half2 uv0: TEXCOORD0;


    float3 Color: TEXCOORD1;
    float DissolveOp: TEXCOORD2;
    float3 BaseColor: TEXCOORD3;
    float UVDissolve: TEXCOORD4;
    float BaseColorInt: TEXCOORD5;
};

Varyings DepthOnlyVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);



    output.pos = TransformObjectToHClip(input.vertex.xyz);
    output.uv0 = input.texcoord0;
    return output;
}

half4 DepthOnlyFragment(Varyings input): SV_TARGET
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);


    return 0;
}
#endif
