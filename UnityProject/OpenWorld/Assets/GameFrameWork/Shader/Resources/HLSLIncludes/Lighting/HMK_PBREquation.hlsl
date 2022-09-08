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
float V_SmithGGX(float NdotL, float NdotV, float roughness)
{
    float roughnessSqr = roughness * roughness;
    float NdotLSqr = NdotL * NdotL;
    float NdotVSqr = NdotV * NdotV;
    float SmithL = (2 * NdotL) / (NdotL + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotLSqr));
    float SmithV = (2 * NdotV) / (NdotV + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotVSqr));
    float Gs = (SmithL * SmithV);
    return Gs;
}

float V_SmithGGXCorrelated(float NdotL, float NdotV, float roughness)
{
    float a2 = roughness * roughness;
    float lambdaL = NdotL * sqrt((NdotV - a2 * NdotV) * NdotV + a2);
    float lambdaV = NdotV * sqrt((NdotL - a2 * NdotL) * NdotL + a2);
    float v = 0.5 / (lambdaL + lambdaV);
    return saturate(v);
}

float V_SmithGGXCorrelated_Fast(float NdotL, float NdotV, float roughness)
{
    float v = 0.5 / lerp(2.0 * NdotL * NdotV, NdotL + NdotV, roughness);
    return saturate(v);
}


float Visibility(float NdotL, float NdotV, float roughness)
{
    return V_SmithGGXCorrelated_Fast(NdotL, NdotV, roughness);
}

// half D_GGX(half roughness, half NdotH)
// {
//     roughness = Pow4(roughness);
//     half D = (NdotH * roughness - NdotH) * NdotH + 1;
//     return roughness / (PI * D * D);
// }

float D_Function(float roughness, float NdotH)
{
    float a2 = roughness * roughness;
    float f = (NdotH * NdotH) * (a2 - 1.0) + 1.0;
    return a2 / (f * f);
}

float G_Function(float NdotL, float NdotV, float roughness, float kInDirectLight)
{
    // float GLeft = NdotL / lerp(NdotL, 1, kInDirectLight);
    // float GRight = NdotV / lerp(NdotV, 1, kInDirectLight);
    float GLeft = NdotL / (NdotL * (1 - kInDirectLight) + kInDirectLight);
    float GRight = NdotV / (NdotV * (1 - kInDirectLight) + kInDirectLight);
    //和虚幻不同
    float G = GLeft * GRight;
    return G;
}

float G_Function(float NdotL, float NdotV, float roughness)
{
    float kInDirectLight = pow(roughness + 1, 2) / 8;
    return G_Function(NdotL, NdotV, roughness, kInDirectLight);
}


// float F_Schlick(float VdotH, float F0)
// {
//     float F = F0 + (1 - F0) * pow(1 - VdotH, 5);
//     return F;
// }

float3 F_Function(float VdotH, half3 F0)
{
    // float3 F = F0 + (1 - F0) * exp2((-5.55473 * VdotH - 6.98316) * VdotH);//与虚幻一致
    // return F;
    float f = pow(1.0 - VdotH, 5.0);
    return F0 + (1 - F0) * f;
}