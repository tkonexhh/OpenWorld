#ifndef RENDERPIPELINE_LIT_FORWARD_INCLUDED
#define RENDERPIPELINE_LIT_FORWARD_INCLUDED

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
    UNITY_VERTEX_INPUT_INSTANCE_ID
};



Varyings LitPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.uv = input.uv;
    return output;
}


float4 LitPassFragment(Varyings input): SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
    half4 baseColor = baseMap * _BaseColor;
    float3 normalWS = normalize(input.normalWS);
    #ifdef _ALPHATEST_ON
        clip(baseColor.a - _Cutoff);
    #endif

    SurfaceData surfaceData;
    surfaceData.albedo = baseColor.rgb;
    surfaceData.alpha = baseColor.a;
    surfaceData.metallic = _MetallicScale;
    surfaceData.roughness = _RoughnessScale;
    surfaceData.occlusion = _OcclusionScale;
    surfaceData.emission = _EmissionColor * _EmissionScale;
    // surfaceData.dither = InterleavedGradientNoise(input.positionCS.xy, 0);

    LightingData lightingData = InitLightingData(input.positionWS, normalWS);


    half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
    return half4(finalRGB, surfaceData.alpha);
}

#endif