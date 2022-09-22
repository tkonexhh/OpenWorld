#ifndef RENDERPIPELINE_META_PASS_INCLUDED
#define RENDERPIPELINE_META_PASS_INCLUDED

#include "./../ShaderLibrary/MetaInput.hlsl"



struct Attributes
{
    float4 positionOS: POSITION;
    float2 uv: TEXCOORD0;
    float2 lightMapUV: TEXCOORD1;
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
    //object space positions are stored in light map
    input.positionOS.xy = input.lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
    input.positionOS.z = input.positionOS.z > 0.0 ? FLT_MIN: 0.0;

    output.positionCS = TransformWorldToHClip(input.positionOS);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    return output;
}

half4 MetaPassFragment(Varyings input): SV_Target
{
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
    half4 base = baseMap * _BaseColor;
    //TODO
    SurfaceData surface;
    surface.albedo = base.rgb;
    surface.alpha = base.a;
    surface.metallic = _MetallicScale;
    surface.roughness = _RoughnessScale;
    BRDFData brdf = GetBRDF(surface);
    //if meta equals to zero, there is no indirect light;
    float4 meta = 0.0;
    //Calculate indirect light of diffuse
    if (unity_MetaFragmentControl.x)
    {
        meta = float4(brdf.diffuse, 1.0);
        //highly specular but rough materials also pass along some indirect light
        meta.rgb += brdf.specular * brdf.roughness * 0.5;
        meta.rgb = min(PositivePow(meta.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
    }
    //Calculate indirect light of emission
    else if (unity_MetaFragmentControl.y)
    {
        
        meta = float4(_EmissionColor, 1.0);
    }
    return base;
}

#endif