#pragma once

#include "./../HLSLIncludes/Common/HMK_Normal.hlsl"

float UV_Noise(float2 xy)
{
    return frac(52.9829189f
    * frac(xy.x * 0.06711056f
    + xy.y * 0.00583715f));
}

float3 get_depth_blended_weights(float3 splat_weights, float3 height3)
{
    float dh = 0.2;

    float3 h = height3 + splat_weights;

    // TODO Keep improving multilayer blending, there are still some edge cases...
    // Mitigation: nullify layers with near-zero splat
    h *= smoothstep(0, 0.05, splat_weights);

    float3 d = h + dh;
    d.r -= max(h.g, h.b);
    d.g -= max(h.r, h.b);
    d.b -= max(h.g, h.r);

    float3 w = clamp(d, 0, 1);
    // Had to normalize, since this approach does not preserve components summing to 1
    return w / (w.x + w.y + w.z);
}





void SplatmapMix(TEXTURE2D_ARRAY_PARAM(albedoArray, albedoArraySampler), TEXTURE2D_ARRAY_PARAM(nraArray, nraArraySampler), float2 uv, float2 index, float splat_weights, inout half3 albedo, inout half roughness, inout half occlusion, inout half3 normalTS, inout half4 blend)
{
    
    half4 albedos[3];
    
    albedos[0] = SAMPLE_TEXTURE2D_ARRAY(albedoArray, albedoArraySampler, uv, index.x);
    albedos[1] = SAMPLE_TEXTURE2D_ARRAY(albedoArray, albedoArraySampler, uv, index.y);
    // albedos[2] = SAMPLE_TEXTURE2D_ARRAY(albedoArray, albedoArraySampler, uv, index.z);

    // albedos[0] = SAMPLE_TEXTURE2D_ARRAY(albedoArray, albedoArraySampler, uv, 0);
    // albedos[1] = SAMPLE_TEXTURE2D_ARRAY(albedoArray, albedoArraySampler, uv, 1);
    // albedos[2] = SAMPLE_TEXTURE2D_ARRAY(albedoArray, albedoArraySampler, uv, 2);

    // splat_weights.xyz = get_depth_blended_weights(splat_weights, float3(albedos[0].a, albedos[1].a, albedos[2].a));


    // half4 nra[3];
    // nra[0] = SAMPLE_TEXTURE2D_ARRAY(nraArray, nraArraySampler, uv, index.x);
    // nra[1] = SAMPLE_TEXTURE2D_ARRAY(nraArray, nraArraySampler, uv, index.y);
    // nra[2] = SAMPLE_TEXTURE2D_ARRAY(nraArray, nraArraySampler, uv, index.z);

    albedo = 0;
    albedo += albedos[0] * splat_weights ;
    albedo += albedos[1] * (1 - splat_weights);
    // albedo += albedos[2] * splat_weights.z;

    // albedo = albedos[1];

    // half2 normalSample = 0;
    // normalSample = nra[0].rg * splat_weights.x;
    // normalSample += nra[1].rg * splat_weights.y;
    // normalSample += nra[2].rg * splat_weights.z;
    

    // normalSample = normalSample * 2 - 1;

    // normalSample = 1;

    // NormalReconstructZ(normalSample, normalTS);
    

    // roughness = 0;
    // roughness = nra[0].b * splat_weights.x;
    // roughness += nra[1].b * splat_weights.y;
    

    // occlusion = 0;
    // occlusion = nra[0].a * splat_weights.x;
    // occlusion += nra[1].a * splat_weights.y;

}




