#pragma once

///////////////////////////////////////////////////////////////////////////////
//                          Bender                                           //
///////////////////////////////////////////////////////////////////////////////
float4 _BendMapUV;
TEXTURE2D(_BendMap); SAMPLER(sampler_BendMap);float4 _BendMap_TexelSize;
TEXTURE2D(_CutMap); SAMPLER(sampler_CutMap);



struct BendSettings
{
    float mask;
};

BendSettings InitBendSettings(float mask)
{
    BendSettings settings = (BendSettings)0;
    settings.mask = mask;
    return settings;
}

//Bend map UV
float2 GetBendMapUV(in float3 positionWS)
{
    float2 uv = _BendMapUV.xy / _BendMapUV.z + (_BendMapUV.z / (_BendMapUV.z * _BendMapUV.z)) * positionWS.xz;

    // #ifdef FLIP_UV
    //     uv.y = 1 - uv.y;
    // #endif

    return uv;
}

float4 GetBendVectorLOD(float3 positionWS)
{

    if (_BendMapUV.w == 0) return float4(0.5, positionWS.y, 0.5, 0.0);

    float2 uv = GetBendMapUV(positionWS);

    float4 v = SAMPLE_TEXTURE2D_LOD(_BendMap, sampler_BendMap, uv, 0).rgba;

    //Remap from 0.1 to -1.1
    v.xz = v.xz * 2.0 - 1.0;

    float edgeMask = 1;//BoundsEdgeMask(positionWS.xz);

    return v * edgeMask;
}

float CreateDirMask(float2 uv)
{
    float center = pow((uv.y * (1 - uv.y)) * 4, 4);

    return saturate(center);
}

//Creates a tube mask from the trail UV.y. Red vertex color represents lifetime strength
float CreateTrailMask(float2 uv, float lifetime)
{
    float center = saturate((uv.y * (1.0 - uv.y)) * 8.0);

    //Mask out the start of the trail, avoids grass instantly bending (assumes UV mode is set to "Stretch")
    float tip = saturate(uv.x * 16.0);

    return center * lifetime * tip;
}

float4 GetBendOffset(float3 positionWS, BendSettings settings)
{

    float4 vec = GetBendVectorLOD(positionWS);

    float4 offset = float4(positionWS, vec.a);

    const float grassHeight = positionWS.y;
    const float bendHeight = vec.y;
    const float dist = grassHeight - bendHeight;

    const float weight = saturate(dist);

    offset.xz = -vec.xz * settings.mask * weight * 1;
    offset.y = settings.mask * (vec.a * 0.75) * weight * 1;

    // offset.xz = vec.xz * b.mask * weight * b.pushStrength;
    // offset.y = b.mask * (vec.a * 0.75) * weight * b.flattenStrength;
    
    //Pass the mask, so it can be used to lerp between wind and bend offset vectors
    offset.a = vec.a * weight;

    //Apply mask
    offset.xyz *= offset.a;

    return offset;
}

half4 GetCutMapLOD(float3 positionWS)
{

    if (_BendMapUV.w == 0) return 0;

    float2 uv = GetBendMapUV(positionWS);

    half4 v = SAMPLE_TEXTURE2D_LOD(_CutMap, sampler_CutMap, uv, 0).rgba;

    return v ;
}

half4 GetCut(float3 positionWS)
{
    half4 vec = GetCutMapLOD(positionWS);
    return vec;
}




