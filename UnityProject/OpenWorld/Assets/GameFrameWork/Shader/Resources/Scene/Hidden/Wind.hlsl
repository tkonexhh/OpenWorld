#pragma once


///////////////////////////////////////////////////////////////////////////////
//                         Wind                                              //
///////////////////////////////////////////////////////////////////////////////

float3 _Params;

//变量区
half3 _WindDirection;//风向
half _WindStrength;//风力
TEXTURE2D(_WindMap);SAMPLER(sampler_WindMap);


#define WindStrength _WindStrength
#define WindDirection _WindDirection
#define WindMoveOffset _Params.xy
#define LeavesPRBOffset _Params.z

//--------------------------------------------

#define MAX_GRASS_WIND_STRENGTH 7

float ObjectPosRand01()
{
    return frac(UNITY_MATRIX_M[0][3] + UNITY_MATRIX_M[1][3] + UNITY_MATRIX_M[2][3]);
}

struct WindSettings
{
    half mask;
    half speed;
    half strength;
    float3 direction;
    half randVertex;
    half randObject;
    half randObjectStrength;
};

WindSettings InitWindSettings(half mask, half randVertex, half randObject, half randObjectStrength)
{
    WindSettings settings = (WindSettings)0;
    settings.mask = mask;
    settings.speed = 0.7f;//speed;
    settings.strength = min(_WindStrength, MAX_GRASS_WIND_STRENGTH);
    settings.strength = min(settings.strength, 0.1);
    settings.direction = normalize(_WindDirection);

    settings.randVertex = randVertex;
    settings.randObject = randObject;
    settings.randObjectStrength = randObjectStrength;

    return settings;
}



float4 GetWindOffset(in float3 positionOS, in float3 positionWS, WindSettings settings, half rand)
{
    float4 offset;
    float f = length(positionOS.xz) * settings.randVertex;
    float strength = settings.strength * 0.5 * lerp(1, rand, settings.randObjectStrength);

    //Combine
    float2 sine = sin(settings.speed * (_TimeParameters.x + (rand * settings.randObject) + f));
    // float2 sine = settings.speed * (sin(_TimeParameters.x + positionWS.x + (rand * settings.randObject) + f) * cos(_TimeParameters.x * 0.667) + 0.3) ;
    //Remap from -1/1 to 0/1
    sine = lerp(sine * 0.5 + 0.5, sine, 1);

    //Scale sine
    sine = sine * settings.mask * strength;


    //Mask by direction vector + gusting push
    offset.xz = sine * settings.direction.xz;
    offset.y = settings.mask;

    //Summed offset strength
    float windWeight = length(offset.xz) + 0.0001;
    //Slightly negate the triangle-shape curve
    windWeight = pow(windWeight, 1.5);
    offset.y *= windWeight;

    //Wind strength in alpha
    offset.a = windWeight;

    return offset;
}



//Bend map UV
float2 GetWindMapUV(in float3 positionWS)
{
    // float2 uv = _BendMapUV.xy / _BendMapUV.z + (_BendMapUV.z / (_BendMapUV.z * _BendMapUV.z)) * positionWS.xz;
    float2 uv = positionWS.xz * 0.01;

    // #ifdef FLIP_UV
    //     uv.y = 1 - uv.y;
    // #endif

    return uv;
}


float SampleWindMap(float3 positionWS)
{
    float2 uv = GetWindMapUV(positionWS);
    float v = SAMPLE_TEXTURE2D_LOD(_WindMap, sampler_WindMap, uv, 0).r;

    //Remap from 0.1 to -1.1
    v = v * 2.0 - 1.0;
    v *= min(_WindStrength, MAX_GRASS_WIND_STRENGTH);
    v *= min(_WindStrength, MAX_GRASS_WIND_STRENGTH);
    return v;
}

//响应风力 自身强度 遮罩 世界坐标
float4 GetWindOffset2(in float3 positionOS, inout float3 positionWS, WindSettings settings, float rand)
{
    float4 offset;
    float f = length(positionOS.xz) * settings.randVertex;
    float strength = settings.strength * 0.5 * lerp(1, rand, settings.randObjectStrength);

    half var_Wind = SampleWindMap(positionWS) ;

    half2 xzOffset = var_Wind * settings.mask * settings.direction.xz * strength;
    

    //Apply gusting
    float2 gust = 0;//SampleGustMapLOD(positionWS, settings).xx;

    offset.xz = (xzOffset +gust) ;
    offset.y = settings.mask;

    float windWeight = length(offset.xz) + 0.0001;
    //Slightly negate the triangle-shape curve
    windWeight = pow(windWeight, 1.5);
    offset.y *= windWeight * 0.3;

    //Wind strength in alpha
    offset.a = windWeight;
    return offset;
}


void FastSinCos(float4 val, out float4 s, out float4 c)
{
    val = val * 6.408849 - 3.1415927;
    float4 r5 = val * val;
    float4 r6 = r5 * r5;
    float4 r7 = r6 * r5;
    float4 r8 = r6 * r5;
    float4 r1 = r5 * val;
    float4 r2 = r1 * r5;
    float4 r3 = r2 * r5;
    float4 sin7 = {
        1, -0.16161616, 0.0083333, -0.00019841
    };
    float4 cos8 = {
        - 0.5, 0.041666666, -0.0013888889, 0.000024801587
    };
    s = val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;
    c = 1 + r5 * cos8.x + r6 * cos8.y + r7 * cos8.z + r8 * cos8.w;
}

float4 GetWindOffset3(in float3 positionOS, inout float3 positionWS, WindSettings settings, float rand)
{
    // const float4 _waveXSize = float4(0.048, 0.06, 0.24, 0.096);
    // const float4 _waveZSize = float4(0.024, 0.08, 0.08, 0.2);
    float4 _waveXmove = float4(0.024, 0.04, -0.12, 0.096);
    float4 _waveZmove = float4(0.006, .02, -0.02, 0.1);

    const float4 waveSpeed = float4(1.2, 2, 1.6, 4.8);

    float4 waves;
    waves = positionWS.x;
    waves += positionWS.z ;

    waves += _Time.x * waveSpeed * 1;

    float4 s, c;
    waves = frac(waves);
    FastSinCos(waves, s, c);

    float waveAmount = settings.mask ;
    s *= waveAmount;
    s *= normalize(waveSpeed);
    
    s = s * s;
    float fade = dot(s, 1.3);
    s = s * s;

    float3 waveMove = float3(0, 0, 0);
    float2 windDirXZ = settings.direction.xz * settings.strength * 20;
    waveMove.x = dot(s, _waveXmove * windDirXZ.x) * 2;
    waveMove.z = dot(s, _waveZmove * windDirXZ.y) * 2;
    // waveMove.xz *= windDirXZ;

    waveMove.x = sin(positionWS.x * 0.5 + _Time.x * settings.strength * PI * 5);
    waveMove.z = cos(positionWS.z * 0.5 + _Time.y * settings.strength * PI * 5);
    waveMove.xz *= settings.mask * 0.4;
    // float3 waveForce = -mul((float3x3)unity_WorldToObject, waveMove).xyz ;
    // return float4(sin(_Time.x * settings.strength * PI) * settings.mask, 0, sin(_Time.y * settings.strength * PI) * settings.mask, 0);
    return float4(waveMove, 1);
}