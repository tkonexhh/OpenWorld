Shader "Hidden/PostProcessing/Environment/Exposure"
{
    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ACES.hlsl"

    // TEXTURE2D(_AutoExposureLUT); SAMPLER(sampler_AutoExposureLUT);

    half4 Frag(VaryingsDefault input): SV_Target
    {
        half3 color = GetScreenColor(input.uv);
        // float ev = SAMPLE_TEXTURE2D_LOD(_AutoExposureLUT, sampler_AutoExposureLUT, float2(0, 0), 0);
        return half4(color, 1);
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "Exposure"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment Frag

            ENDHLSL

        }
    }
}