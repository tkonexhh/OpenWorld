#pragma once

CBUFFER_START(UnityPerMaterial)
float _CutOff;
half4 _BaseColor;
half3 _ColorTop;
half3 _ColorBottom;
half _ColorRange;

half _SpecularStrength;
half3 _SpecularColor;

half4 _HueVariation;
float4 _FadeParams;


//Wind
half _WindVertexRand, _WindObjectRand, _WindRandStrength;

//bending
half4 _BendTint;
half4 _BurnTint;

CBUFFER_END



