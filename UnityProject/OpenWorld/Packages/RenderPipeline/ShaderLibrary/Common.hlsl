﻿#ifndef RENDERPIPELINE_COMMON_INCLUDED
#define RENDERPIPELINE_COMMON_INCLUDED

float Square(float v)
{
    return v * v;
}

float2 Square(float2 x)
{
    return x * x;
}

float3 Square(float3 x)
{
    return x * x;
}

float4 Square(float4 x)
{
    return x * x;
}

float pow2(float x)
{
    return x * x;
}

float2 pow2(float2 x)
{
    return x * x;
}

float3 pow2(float3 x)
{
    return x * x;
}

float4 pow2(float4 x)
{
    return x * x;
}

float pow3(float x)
{
    return x * x * x;
}

float2 pow3(float2 x)
{
    return x * x * x;
}

float3 pow3(float3 x)
{
    return x * x * x;
}

float4 pow3(float4 x)
{
    return x * x * x;
}

float pow4(float x)
{
    float xx = x * x;
    return xx * xx;
}

float2 pow4(float2 x)
{
    float2 xx = x * x;
    return xx * xx;
}

float3 pow4(float3 x)
{
    float3 xx = x * x;
    return xx * xx;
}

float4 pow4(float4 x)
{
    float4 xx = x * x;
    return xx * xx;
}

float pow5(float x)
{
    float xx = x * x;
    return xx * xx * x;
}

float2 pow5(float2 x)
{
    float2 xx = x * x;
    return xx * xx * x;
}

float3 pow5(float3 x)
{
    float3 xx = x * x;
    return xx * xx * x;
}

float4 pow5(float4 x)
{
    float4 xx = x * x;
    return xx * xx * x;
}


inline float CharlieL(float x, float r)
{
    r = saturate(r);
    r = 1 - (1 - r) * (1 - r);
    float a = lerp(25.3245, 21.5473, r);
    float b = lerp(3.32435, 3.82987, r);
    float c = lerp(0.16801, 0.19823, r);
    float d = lerp(-1.27393, -1.97760, r);
    float e = lerp(-4.85967, -4.32054, r);
    return a / (1 + b * pow(x, c)) + d * x + e;
}

#endif

