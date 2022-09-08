#pragma once

void NormalReconstructZ(float2 In, out float3 Out)
{
    float reconstructZ = sqrt(1.0 - saturate(dot(In.xy, In.xy)));
    float3 normalVector = float3(In.x, In.y, reconstructZ);
    Out = normalize(normalVector);
}

float3 HeightToNormal(float height, float3 normalWS, float3 posWS)
{
    float3 worldDirivativeX = ddx(posWS * 30);
    float3 worldDirivativeY = ddy(posWS * 30);
    float3 crossX = cross(normalWS, worldDirivativeX);
    float3 crossY = cross(normalWS, worldDirivativeY);
    float3 d = abs(dot(crossY, worldDirivativeX));
    float3 inToNormal = ((((height + ddx(height)) - height) * crossY) + (((height + ddy(height)) - height) * crossX)) * sign(d);
    inToNormal.y *= -1.0;
    return normalize((d * normalWS) - inToNormal);
}
