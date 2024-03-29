﻿

Shader "Hidden/PostProcessing/Glitch/ImageBlockV2"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
    }
    
    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"

    uniform half3 _Params;
    uniform half4 _Params2;

    #define _TimeX _Params.x
    #define _Offset _Params.y
    #define _Fade _Params.z
    #define _BlockLayer1_U _Params2.x
    #define _BlockLayer1_V _Params2.y
    #define _BlockLayer1_Indensity _Params2.z
    #define _RGBSplit_Indensity _Params2.w

    
    float randomNoise(float2 seed)
    {
        return frac(sin(dot(seed * floor(_TimeX * 30.0), float2(127.1, 311.7))) * 43758.5453123);
    }
    
    float randomNoise(float seed)
    {
        return randomNoise(float2(seed, 1.0));
    }
    
    float4 Frag(VaryingsDefault i): SV_Target
    {
        float2 uv = i.uv.xy;
        
        float2 blockLayer1 = floor(uv * float2(_BlockLayer1_U, _BlockLayer1_V));
        
        float lineNoise = pow(randomNoise(blockLayer1), _BlockLayer1_Indensity) * _Offset -pow(randomNoise(5.1379), 7.1) * _RGBSplit_Indensity;
        
        float4 colorR = GetScreenColor(uv);
        float4 colorG = GetScreenColor(uv + float2(lineNoise * 0.05 * randomNoise(5.0), 0));
        float4 colorB = GetScreenColor(uv - float2(lineNoise * 0.05 * randomNoise(31.0), 0));
        
        float4 result = float4(float3(colorR.r, colorG.g, colorB.b), colorR.a + colorG.a + colorB.a);
        result = lerp(colorR, result, _Fade);
        
        return result;
    }
    
    
    float4 Frag_Debug(VaryingsDefault i): SV_Target
    {
        float2 uv = i.uv.xy;
        
        float2 blockLayer1 = floor(uv * float2(_BlockLayer1_U, _BlockLayer1_V));
        
        // float lineNoise = pow(randomNoise(blockLayer1), _BlockLayer1_Indensity) * _Offset;
        float lineNoise = pow(randomNoise(blockLayer1), _BlockLayer1_Indensity) * _Offset -pow(randomNoise(5.1379), 7.1) * _RGBSplit_Indensity;
        
        return float4(lineNoise, lineNoise, lineNoise, 1);
    }

    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment Frag
            
            ENDHLSL

        }
        
        Pass
        {
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment Frag_Debug
            
            ENDHLSL

        }
    }
}
