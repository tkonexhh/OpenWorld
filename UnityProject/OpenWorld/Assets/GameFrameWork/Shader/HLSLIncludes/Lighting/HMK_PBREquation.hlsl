#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

//法线分布函数
float GGXNDF(float roughness, float NdotH)
{
    float roughnessSqr = roughness * roughness;
    float NdotHSqr = NdotH * NdotH;
    float TanNdotHSqr = (1 - NdotHSqr) / NdotHSqr;
    float s = roughness / (NdotHSqr * (roughnessSqr + TanNdotHSqr));
    return(1.0 / 3.1415926535) * s * s;
}

//几何阴影函数
float GGXGSF(float NdotL, float NdotV, float roughness)
{
    float roughnessSqr = roughness * roughness;
    float NdotLSqr = NdotL * NdotL;
    float NdotVSqr = NdotV * NdotV;
    float SmithL = (2 * NdotL) / (NdotL + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotLSqr));
    float SmithV = (2 * NdotV) / (NdotV + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotVSqr));
    float Gs = (SmithL * SmithV); return Gs;
}

float D_Function(float roughness, float NdotH)
{
    float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);
    // float lerpSquareRoughness = (1 / (1 + roughness * roughness));
    float D = lerpSquareRoughness / (pow((NdotH * NdotH * (lerpSquareRoughness - 1) + 1), 2) * PI);//与虚幻一致
    return D;
}

float G_Function(float NdotL, float NdotV, float roughness, float kInDirectLight)
{
    float GLeft = NdotL / lerp(NdotL, 1, kInDirectLight);
    float GRight = NdotV / lerp(NdotV, 1, kInDirectLight);
    // float GLeft = NdotL / (NdotL * (1 - kInDirectLight) + kInDirectLight);
    // float GRight = NdotV / (NdotV * (1 - kInDirectLight) + kInDirectLight);
    //和虚幻不同
    float G = GLeft * GRight;
    return G;
}

float G_Function(float NdotL, float NdotV, float roughness)
{
    float kInDirectLight = pow(roughness + 1, 2) / 8;
    return G_Function(NdotL, NdotV, roughness, kInDirectLight);
}

float3 F_Function(float VdotH, float3 F0)
{
    float3 F = F0 + (1 - F0) * exp2((-5.55473 * VdotH - 6.98316) * VdotH);//与虚幻一致
    return F;
}