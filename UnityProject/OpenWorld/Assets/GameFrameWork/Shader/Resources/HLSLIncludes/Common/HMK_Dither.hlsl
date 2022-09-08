#pragma once

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"



float Dither4x4Bayer(int x, int y)
{
    const float dither[ 16 ] = {
        1, 9, 3, 11,
        13, 5, 15, 7,
        4, 12, 2, 10,
        16, 8, 14, 6
    };
    int r = y * 4 + x;
    return dither[r] / 16; // same # of instructions as pre-dividing due to compiler magic

}

float DitherOutputSS(float4 positionSS)
{
    float4 screenPosNorm = positionSS / positionSS.w;
    screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? screenPosNorm.z: screenPosNorm.z * 0.5 + 0.5;
    float2 clipScreen = screenPosNorm.xy * _ScreenParams.xy;
    float dither = Dither4x4Bayer(fmod(clipScreen.x, 4), fmod(clipScreen.y, 4));
    float Alpha = dither;
    return Alpha;
}

float DitherOutput(float4 positionCS)
{
    float4 positionSS = ComputeScreenPos(positionCS);
    return DitherOutputSS(positionSS);
}