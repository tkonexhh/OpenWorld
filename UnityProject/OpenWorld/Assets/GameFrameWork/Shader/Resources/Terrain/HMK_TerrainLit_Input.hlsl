#pragma once

TEXTURE2D(_Control0);   SAMPLER(sampler_Control0);
TEXTURE2D(_Control1);

TEXTURE2D(_Splat0);     SAMPLER(sampler_Splat0);
TEXTURE2D(_Splat1);
TEXTURE2D(_Splat2);
TEXTURE2D(_Splat3);
TEXTURE2D(_Splat4);
TEXTURE2D(_Splat5);
TEXTURE2D(_Splat6);
TEXTURE2D(_Splat7);

TEXTURE2D(_NRA0);SAMPLER(sampler_NRA0);
TEXTURE2D(_NRA1);
TEXTURE2D(_NRA2);
TEXTURE2D(_NRA3);
TEXTURE2D(_NRA4);
TEXTURE2D(_NRA5);
TEXTURE2D(_NRA6);
TEXTURE2D(_NRA7);


CBUFFER_START(UnityPerMaterial)

float _UVScale;


float _RoughnessScale, _OcclusionScale;
int _NumLayersCount;
float _HeightBias;

half _CliffBlend;

CBUFFER_END