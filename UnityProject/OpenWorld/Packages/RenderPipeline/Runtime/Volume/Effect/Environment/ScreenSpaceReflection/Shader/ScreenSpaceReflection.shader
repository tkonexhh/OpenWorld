

Shader "Hidden/PostProcessing/Environment/ScreenSpaceReflection"
{
    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"

    half4 Frag(VaryingsDefault input): SV_Target
    {
        half3 color = GetScreenColor(input.uv);
        return half4(color, 1);
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "AutoExposure"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment Frag

            ENDHLSL

        }
    }
}