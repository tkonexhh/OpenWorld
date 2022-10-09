

Shader "Hidden/PostProcessing/ColorAdjustment/ChannelMixer"
{
    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ACES.hlsl"

    half4 _ChannelMixerRed;
    half4 _ChannelMixerGreen;
    half4 _ChannelMixerBlue;

    half3 ColorGradeChannelMixer(half3 color)
    {
        return mul(half3x3(_ChannelMixerRed.rgb, _ChannelMixerGreen.rgb, _ChannelMixerBlue.rgb), color);
    }

    half4 Frag(VaryingsDefault input): SV_Target
    {
        half3 color = GetScreenColor(input.uv);
        color = ColorGradeChannelMixer(color);
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