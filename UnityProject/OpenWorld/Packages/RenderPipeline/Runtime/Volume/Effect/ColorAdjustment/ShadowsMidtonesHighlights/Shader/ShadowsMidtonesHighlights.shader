

Shader "Hidden/PostProcessing/ColorAdjustment/ShadowsMidtonesHighlights"
{
    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ACES.hlsl"

    half4 _Shadows;
    half4 _Midtones;
    half4 _Highlights;
    half4 _Range;

    half3 ColorGradingShadowsMidtonesHighlights(half3 color)
    {
        half luminance = Luminance(color);
        half shadowsWeight = 1.0 - smoothstep(_Range.x, _Range.y, luminance);
        half highlightsWeight = smoothstep(_Range.z, _Range.w, luminance);
        half midtonesWeight = 1.0 - shadowsWeight - highlightsWeight;
        return color * _Shadows.rgb * shadowsWeight +
        color * _Midtones * midtonesWeight +
        color * _Highlights * highlightsWeight;
    }

    half4 Frag(VaryingsDefault input): SV_Target
    {
        half3 color = GetScreenColor(input.uv);
        color = ColorGradingShadowsMidtonesHighlights(color);
        return half4(color, 1);
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "ChannelMixer"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment Frag

            ENDHLSL

        }
    }
}