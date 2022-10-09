

Shader "Hidden/PostProcessing/ColorAdjustments"
{

    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ACES.hlsl"

    half4 _Params;
    half4 _ColorFilter;
    half3 _WhiteBalance;

    #define PostExposure       _Params.x
    #define Contrast           _Params.y
    #define HueShift           _Params.z
    #define Saturation         _Params.w

    half3 ColorGradePostExposure(half3 color)
    {
        return color * PostExposure;
    }

    half3 ColorGradingContrast(half3 color)
    {
        return(color - ACEScc_MIDGRAY) * Contrast + ACEScc_MIDGRAY;
    }

    half3 ColorGradeColorFilter(half3 color)
    {
        return color * _ColorFilter.rgb;
    }

    half3 ColorGradeingHueShift(half3 color)
    {
        color = RgbToHsv(color);
        half hue = color.x + HueShift;
        color.x = RotateHue(hue, 0.0, 1.0);
        return HsvToRgb(color);
    }

    half3 ColorGradeingSaturation(half3 color)
    {
        half luminance = Luminance(color);
        return(color - luminance) * Saturation + luminance;
    }

    half3 ColorGradeWhiteBalance(half3 color)
    {
        color = LinearToLMS(color);
        color *= _WhiteBalance.rgb;
        return LMSToLinear(color);
    }

    half4 Frag(VaryingsDefault input): SV_Target
    {
        half3 color = GetScreenColor(input.uv);
        color = ColorGradePostExposure(color);
        color = ColorGradeWhiteBalance(color);
        color = ColorGradingContrast(color);
        color = ColorGradeColorFilter(color);
        color = max(color, 0.0);
        color = ColorGradeingHueShift(color);
        color = ColorGradeingSaturation(color);
        color = max(color, 0.0);
        return half4(color, 1);
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "ColorAdjustments"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment Frag

            ENDHLSL

        }
    }
}