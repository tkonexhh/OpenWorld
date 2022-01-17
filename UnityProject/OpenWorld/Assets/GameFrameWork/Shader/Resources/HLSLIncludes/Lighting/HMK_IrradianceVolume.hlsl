#pragma once

#include "./../Lighting/HMK_LightingEquation.hlsl"
#include "./HMK_SH.hlsl"

CBUFFER_START(IrradianceVolume)
float3 _GIVolumePosition;//Volume 中心点
float3 _GIVolumeWorldSize;//GI覆盖世界大小
CBUFFER_END

TEXTURE3D(_GIVolumeTex0);SAMPLER(sampler_GIVolumeTex0);
TEXTURE3D(_GIVolumeTex1);SAMPLER(sampler_GIVolumeTex1);


half4 GetAmbientColor(float3 normal, float3 coord)
{
    float4 var_SH0 = SAMPLE_TEXTURE3D(_GIVolumeTex0, sampler_GIVolumeTex0, coord);
    float3 var_SH1 = SAMPLE_TEXTURE3D(_GIVolumeTex1, sampler_GIVolumeTex1, coord);
    float ao = var_SH0.a;
    float3 sh0 = var_SH0.xyz;
    float3 sh10 = var_SH1.r;
    float3 sh11 = var_SH1.g;
    float3 sh12 = var_SH1.b;
    float3 color = sh0 * GetY0(normal) + sh10 * GetY1(normal) + sh11 * GetY2(normal) + sh12 * GetY3(normal);
    return float4(color, ao);
}

//======采样========
half4 HMKSampleIrradiance(float3 positionWS, float3 normalWS)
{
    float3 size = _GIVolumeWorldSize * 0.5;
    float3 posWS = positionWS - _GIVolumePosition;
    
    // return posWS;
    float3 coord = (posWS / size) * 0.5 + 0.5;
    half4 color = GetAmbientColor(normalWS, coord);
    return saturate(color);
}