#ifndef EXPOSURE_COMMON_INCLUDED
#define EXPOSURE_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/PhysicalCamera.hlsl"


RW_TEXTURE2D(float2, _OutputTexture);

CBUFFER_START(cb)
float4 _ExposureParams;
float4 _ExposureParams2;
CBUFFER_END

#define ParamEV100                      _ExposureParams.y
#define ParamExposureCompensation       _ExposureParams.x

#define LensImperfectionExposureScale   _ExposureParams2.z


#endif