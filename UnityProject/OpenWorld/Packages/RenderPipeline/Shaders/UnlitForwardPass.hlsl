#ifndef RENDERPIPELINE_UNLIT_FORWARD_INCLUDED
#define RENDERPIPELINE_UNLIT_FORWARD_INCLUDED

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
    float2 uv: TEXCOORD0;
    float3 normalWS: NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};



Varyings UnlitPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.uv = input.uv;
    return output;
}


float4 UnlitPassFragment(Varyings input): SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    half4 baseMap = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, input.uv);
    half4 baseColor = baseMap * _BaseColor;
    
    #ifdef _ALPHATEST_ON
        clip(baseColor.a - _Cutoff);
    #endif

    return baseColor;
}

#endif