

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
        color.rgb = AcesTonemap(unity_to_ACES(color.rgb));
        return color;
    }


    static const float e = 2.71828;

    float W_f(float x, float e0, float e1)
    {
        if (x <= e0)
            return 0;
        if (x >= e1)
            return 1;
        float a = (x - e0) / (e1 - e0);
        return a * a * (3 - 2 * a);
    }
    float H_f(float x, float e0, float e1)
    {
        if (x <= e0)
            return 0;
        if (x >= e1)
            return 1;
        return(x - e0) / (e1 - e0);
    }

    float GranTurismoTonemapper(float x)
    {
        float P = 1;
        float a = 1;
        float m = 0.22;
        float l = 0.4;
        float c = 1.33;
        float b = 0;
        float l0 = (P - m) * l / a;
        float L0 = m - m / a;
        float L1 = m + (1 - m) / a;
        float L_x = m + a * (x - m);
        float T_x = m * pow(x / m, c) + b;
        float S0 = m + l0;
        float S1 = m + a * l0;
        float C2 = a * P / (P - S1);
        float S_x = P - (P - S1) * pow(e, - (C2 * (x - S0) / P));
        float w0_x = 1 - W_f(x, 0, m);
        float w2_x = H_f(x, m + l0, m + l0);
        float w1_x = 1 - w0_x - w2_x;
        float f_x = T_x * w0_x + L_x * w1_x + S_x * w2_x;
        return f_x;
    }

    half4 FragGranTurismo(VaryingsDefault input): SV_Target
    {
        half4 sceneColor = GetScreenColor(input.uv);
        float r = GranTurismoTonemapper(sceneColor.r);
        float g = GranTurismoTonemapper(sceneColor.g);
        float b = GranTurismoTonemapper(sceneColor.b);
        sceneColor = float4(r, g, b, sceneColor.a);
        return sceneColor;
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

        Pass
        {
            Name "Tonemapping GranTurismo"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment FragGranTurismo

            ENDHLSL

        }
    }
}