﻿

Shader "Hidden/PostProcessing/Glitch/WaveJitter"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
    }

    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"
    #include "../../../../Shader/NoiseLibrary.hlsl"

    #pragma shader_feature USING_FREQUENCY_INFINITE

    uniform half4 _Params;
    half2 _Resolution;

    #define _Frequency _Params.x
    #define _RGBSplit _Params.y
    #define _Speed _Params.z
    #define _Amount _Params.w

    
    float4 Frag_Horizontal(VaryingsDefault i): SV_Target
    {
        half strength = 0.0;
        #if USING_FREQUENCY_INFINITE
            strength = 1;
        #else
            strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
        #endif
        
        // Prepare UV
        float uv_y = i.uv.y * _Resolution.y;
        float noise_wave_1 = snoise(float2(uv_y * 0.01, _Time.y * _Speed * 20)) * (strength * _Amount * 32.0);
        float noise_wave_2 = snoise(float2(uv_y * 0.02, _Time.y * _Speed * 10)) * (strength * _Amount * 4.0);
        float noise_wave_x = noise_wave_1 * noise_wave_2 / _Resolution.x;
        float uv_x = i.uv.x + noise_wave_x;

        float rgbSplit_uv_x = (_RGBSplit * 50 + (20.0 * strength + 1.0)) * noise_wave_x / _Resolution.x;

        // Sample RGB Color-
        half4 colorG = GetScreenColor(float2(uv_x, i.uv.y));
        half4 colorRB = GetScreenColor(float2(uv_x + rgbSplit_uv_x, i.uv.y));
        
        return half4(colorRB.r, colorG.g, colorRB.b, colorRB.a + colorG.a);
    }

    float4 Frag_Vertical(VaryingsDefault i): SV_Target
    {
        half strength = 0.0;
        #if USING_FREQUENCY_INFINITE
            strength = 1;
        #else
            strength = 0.5 + 0.5 * cos(_Time.y * _Frequency);
        #endif

        // Prepare UV
        float uv_x = i.uv.x * _Resolution.x;
        float noise_wave_1 = snoise(float2(uv_x * 0.01, _Time.y * _Speed * 20)) * (strength * _Amount * 32.0);
        float noise_wave_2 = snoise(float2(uv_x * 0.02, _Time.y * _Speed * 10)) * (strength * _Amount * 4.0);
        float noise_wave_y = noise_wave_1 * noise_wave_2 / _Resolution.x;
        float uv_y = i.uv.y + noise_wave_y;

        float rgbSplit_uv_y = (_RGBSplit * 50 + (20.0 * strength + 1.0)) * noise_wave_y / _Resolution.y;

        // Sample RGB Color
        half4 colorG = GetScreenColor(float2(i.uv.x, uv_y));
        half4 colorRB = GetScreenColor(float2(i.uv.x, uv_y + rgbSplit_uv_y));

        return half4(colorRB.r, colorG.g, colorRB.b, colorRB.a + colorG.a);
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
            #pragma fragment Frag_Horizontal

            ENDHLSL

        }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment Frag_Vertical
            
            ENDHLSL

        }
    }
}
