#pragma once

#include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
#include "./../HLSLIncludes/Common/HMK_Normal.hlsl"

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS: SV_POSITION;
    float2 uv: TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};



///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

Varyings DepthOnlyVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.uv = input.uv;

    return output;
}


half4 DepthOnlyFragment(Varyings input): SV_Target
{
    return 0;
}