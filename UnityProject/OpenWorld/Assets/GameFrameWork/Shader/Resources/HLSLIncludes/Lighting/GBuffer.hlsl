#pragma one

#include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"

struct GBufferOutput
{
    half4 GBuffer0: SV_Target0;
    half4 GBuffer1: SV_Target1;
    half4 GBuffer2: SV_Target2;
    half4 GBuffer3: SV_Target3; // Camera color attachment

};


GBufferOutput OutputGBuffer(HMKSurfaceData surfaceData, HMKLightingData lightingData)
{
    GBufferOutput output;
    output.GBuffer0 = half4(surfaceData.albedo, 0);
    output.GBuffer1 = half4(surfaceData.metallic, 0, 0, surfaceData.occlusion);
    output.GBuffer2 = half4(lightingData.normalWS, 1 - surfaceData.roughness);
    output.GBuffer3 = half4(0, 0, 0, 1);
    return output;
}
