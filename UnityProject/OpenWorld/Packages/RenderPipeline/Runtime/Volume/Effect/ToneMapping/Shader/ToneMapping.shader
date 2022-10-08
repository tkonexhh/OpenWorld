

Shader "Hidden/PostProcessing/Tonemapping"
{

    HLSLINCLUDE

    #include "../../../Shader/PostProcessing.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ACES.hlsl"


    half4 FragReinhard(VaryingsDefault input): SV_Target
    {
        half4 color = GetScreenColor(input.uv);
        color.rgb /= color.rgb + 1.0;
        return color;
    }

    half4 FragNeutral(VaryingsDefault input): SV_Target
    {
        half4 color = GetScreenColor(input.uv);
        color.rgb = min(color.rgb, 60.0);
        color.rgb = NeutralTonemap(color.rgb);
        return color;
    }

    half4 FragACES(VaryingsDefault input): SV_Target
    {
        half4 color = GetScreenColor(input.uv);
        color.rgb = min(color.rgb, 60.0);
        color.rgb = AcesTonemap(unity_to_ACES(color.rgb));
        return color;
    }

    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Name "Tonemapping Reinhard"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment FragReinhard

            ENDHLSL

        }

        Pass
        {
            Name "Tonemapping Neutral"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment FragNeutral

            ENDHLSL

        }
        Pass
        {
            Name "Tonemapping ACES"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment FragACES

            ENDHLSL

        }
    }
}