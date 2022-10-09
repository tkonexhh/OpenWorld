

Shader "Hidden/PostProcessing/ColorAdjustment/WhiteBalance"
{

    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ACES.hlsl"

    half4 _WhiteBalance;

    half3 ColorGradeWhiteBalance(half3 color)
    {
        color = LinearToLMS(color);
        color *= _WhiteBalance.rgb;
        return LMSToLinear(color);
    }

    half4 Frag(VaryingsDefault input): SV_Target
    {
        half3 color = GetScreenColor(input.uv);
        color = ColorGradeWhiteBalance(color);
        return half4(color, 1);
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "WhiteBalance"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment Frag

            ENDHLSL

        }
    }
}
