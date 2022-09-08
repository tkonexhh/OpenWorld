#pragma once

#include "./../Common/HMK_Common.hlsl"


inline float UnityGet2DClipping(in float2 position, in float4 clipRect)
{
    float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
    return inside.x * inside.y;
}

inline half DecodeRGB2Alpha(half3 colorRGB)
{
    return(colorRGB.r + colorRGB.g * 0.00392156 + colorRGB.b * 0.00001537);
}


float Lingren_Clip(float4 pos, float softnessX, float softnessY)
{
    float alpha = abs(min(pos.x, pos.y)) / clamp(softnessY, 1, 255);
    if (alpha <= 1)
    {
        return alpha;
    }

    alpha = abs(min(pos.z, pos.w)) / clamp(softnessX, 1, 255);
    if (alpha <= 1)
    {
        return alpha;
    }

    return 1;
}

float2 GetFontEncodeUV(float2 uv)
{
    if (uv.y > 0.75)
    {
        return float2((uv.y - 0.75) / 0.25, 0.1);
    }
    else if (uv.y > 0.5)
    {
        return float2((uv.y - 0.5) / 0.25, 1.1);
    }
    else if (uv.y > 0.25)
    {
        return float2((uv.y - 0.25) / 0.25, 2.1);
    }
    else
    {
        return float2((uv.y - 0.0) / 0.25, 3.1);
    }
}


half GetFontA(sampler2D fontTex, float4 fontEncodeUV)
{
    half4 colorFontLayerRGBA = tex2D(fontTex, fontEncodeUV.xz);

    if (fontEncodeUV.w > 3)
    {
        return colorFontLayerRGBA.a;
    }
    else if (fontEncodeUV.w > 2)
    {
        return colorFontLayerRGBA.b;
    }
    else if (fontEncodeUV.w > 1)
    {
        return colorFontLayerRGBA.g;
    }
    else
    {
        return colorFontLayerRGBA.r;
    }
}

// Converts color to luminance(grayscale)
// inline half Luminance(half3 rgb)
// {
//     return dot(rgb, half3(0.0396819152, 0.458021790, 0.00609653955));
//