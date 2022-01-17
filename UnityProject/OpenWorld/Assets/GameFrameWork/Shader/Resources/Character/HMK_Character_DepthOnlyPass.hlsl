#ifndef UNIVERSAL_DEPTH_ONLY_PASS_INCLUDED
#define UNIVERSAL_DEPTH_ONLY_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "./../HLSLincludes/Common/HMK_Dither.hlsl"

CBUFFER_START(UnityPerMaterial)
#if defined(_ALPHATEST_ON)
    half _Cutoff;
#endif
half _Opacity;
CBUFFER_END

TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

struct Attributes
{
    float4 vertex: POSITION;
    float2 uv: TEXCOORD0;
    float3 normal: NORMAL;
    float4 vertexColor: COLOR;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS: POSITION;
    float2 uv: TEXCOORD0;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings DepthOnlyVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);


    float3 scale;
    scale.x = length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x));
    scale.y = length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y));
    scale.z = length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z));

    input.vertex.xyz += input.normal * 0.001 * 5 * input.vertexColor.r / scale;
    output.positionCS = TransformObjectToHClip(input.vertex.xyz);
    output.uv = input.uv;
    return output;
}

half4 DepthOnlyFragment(Varyings input): SV_TARGET
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    float Alpha = DitherOutput(input.positionCS);

    clip(Alpha - _Opacity);


    return 0;
}
#endif
