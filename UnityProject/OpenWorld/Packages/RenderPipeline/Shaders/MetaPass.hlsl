#ifndef RENDERPIPELINE_META_PASS_INCLUDED
#define RENDERPIPELINE_META_PASS_INCLUDED

struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
};

struct Varyings
{
    float2 uv: TEXCOORD0;
    float4 positionCS: SV_POSITION;
};

Varyings MetaPassVertex(Attributes input)
{
    //TODO
    Varyings output;
    output.positionCS = 0.0;
    output.uv = input.uv;
    return output;
}

half4 MetaPassFragment(Varyings input): SV_Target
{
    return 0;
}

#endif