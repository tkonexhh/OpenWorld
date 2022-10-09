

Shader "Hidden/PostProcessing/ColorAdjustment/SplitToning"
{
    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ACES.hlsl"

    half4 _SplitToningShadows;
    half4 _SplitToningHighlights;

    half3 ColorGradeSplitToning(half3 color)
    {
        color = PositivePow(color, 1.0 / 2.2);
        half t = saturate(Luminance(saturate(color)) + _SplitToningShadows.a);
        half3 shadows = lerp(0.5, _SplitToningShadows.rgb, 1.0 - t);
        half3 highlights = lerp(0.5, _SplitToningHighlights.rgb, t);
        color = SoftLight(color, shadows.rgb);
        color = SoftLight(color, highlights.rgb);
        return PositivePow(color, 2.2);
    }

    half4 Frag(VaryingsDefault input): SV_Target
    {
        half3 color = GetScreenColor(input.uv);
        color = ColorGradeSplitToning(color);
        return half4(color, 1);
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "SplitToning"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment Frag

            ENDHLSL

        }
    }
}