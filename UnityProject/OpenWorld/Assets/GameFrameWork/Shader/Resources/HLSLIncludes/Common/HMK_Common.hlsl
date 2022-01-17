#pragma once

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"



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
    return Linear01Depth(depth, _ZBufferParams);
    // return  1.0 / (_ZBufferParams.x * depth + _ZBufferParams.y);

}
