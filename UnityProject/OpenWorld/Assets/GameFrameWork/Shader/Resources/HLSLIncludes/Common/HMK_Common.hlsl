#pragma once

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

half luminance(half3 color)
{
    return dot(color, half3(0.222, 0.707, 0.071));
}


half4x4 Rotation(half3 rotation)
{
    float radX = radians(rotation.x);
    float radY = radians(rotation.y);
    float radZ = radians(rotation.z);

    half sinX = sin(radX);
    half cosX = cos(radX);
    half sinY = sin(radY);
    half cosY = cos(radY);
    half sinZ = sin(radZ);
    half cosZ = cos(radZ);
    return half4x4(
        cosY * cosZ, -cosY * sinZ, sinY, 0.0,
        cosX * sinZ + sinX * sinY * cosZ, cosX * cosZ - sinX * sinY * sinZ, -sinX * cosY, 0.0,
        sinX * sinZ - cosX * sinY * cosZ, sinX * cosZ + cosX * sinY * sinZ, cosX * cosY, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}


half3 Rotation(half3 position, half3 rotation)
{
    return mul(Rotation(rotation), position);
}

half LinearStep(half minValue, half maxValue, half In)
{
    return saturate((In - minValue) / (maxValue - minValue));
}



float Linear01Depth(float depth)
{
    // return 1.0 / (_ZBufferParams.x * depth + _ZBufferParams.y);
    return Linear01Depth(depth, _ZBufferParams);
}

float LinearEyeDepth(float depth)
{
    // return 1.0 / (zBufferParam.z * depth + zBufferParam.w);
    return LinearEyeDepth(depth, _ZBufferParams);
}


inline half3 GammaToLinearSpace(half3 sRGB)
{
    // Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
    return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);

    // Precise version, useful for debugging.
    //return half3(GammaToLinearSpaceExact(sRGB.r), GammaToLinearSpaceExact(sRGB.g), GammaToLinearSpaceExact(sRGB.b));

}

inline half3 LinearToGammaSpace(half3 linRGB)
{
    linRGB = max(linRGB, half3(0.h, 0.h, 0.h));
    // An almost-perfect approximation from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
    return max(1.055h * pow(linRGB, 0.416666667h) - 0.055h, 0.h);

    // Exact version, useful for debugging.
    //return half3(LinearToGammaSpaceExact(linRGB.r), LinearToGammaSpaceExact(linRGB.g), LinearToGammaSpaceExact(linRGB.b));

}


float ClampRange(float input, float minimum, float maximum)
{
    return saturate((input - minimum) / (maximum - minimum));
}