#pragma once

//这里放置一些全局的变量

float3 _LightDir;//虚拟的光源方向,对应太阳方向 而不是真实光源方
float _Wetness;//潮湿

half _BakedIndirectStrength;//烘焙的lightmap强度
float3 _PlayerPosition;