

Shader "Hidden/PostProcessing/Environment/Bloom"
{
    HLSLINCLUDE

    #include "../../../../Shader/PostProcessing.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
    
    float4 _Params;
    TEXTURE2D(_SourceTexLowMip); float4 _SourceTexLowMip_TexelSize;
    TEXTURE2D(_Bloom_Texture);float4 _Bloom_Texture_TexelSize;

    #define Threshold           _Params.x
    #define ThresholdKnee       _Params.y
    #define Scatter             _Params.z
    #define Intensity           _Params.w

    

    half3 SafeHDR(half3 c)
    {
        return min(c, 65504.0);
    }
    half4 SafeHDR(half4 c)
    {
        return min(c, 65504.0);
    }

    half3 DecodeHDR(half4 c)
    {
        return c.xyz;
    }

    half4 GetScreenColorBicubic(float2 uv)
    {
        return SampleTexture2DBicubic(_BlitTexture, sampler_LinearClamp, uv, _BlitTexture_TexelSize, 1.0, 0.0);
    }

    half4 FragPrefilter(VaryingsDefault input): SV_Target
    {
        float2 uv = input.uv;
        #if _BLOOM_HQ
            float texelSize = _BlitTexture_TexelSize.x;
            half4 A = GetScreenColor(uv + texelSize * float2(-1.0, -1.0));
            half4 B = GetScreenColor(uv + texelSize * float2(0.0, -1.0));
            half4 C = GetScreenColor(uv + texelSize * float2(1.0, -1.0));
            half4 D = GetScreenColor(uv + texelSize * float2(-0.5, -0.5));
            half4 E = GetScreenColor(uv + texelSize * float2(0.5, -0.5));
            half4 F = GetScreenColor(uv + texelSize * float2(-1.0, 0.0));
            half4 G = GetScreenColor(uv);
            half4 H = GetScreenColor(uv + texelSize * float2(1.0, 0.0));
            half4 I = GetScreenColor(uv + texelSize * float2(-0.5, 0.5));
            half4 J = GetScreenColor(uv + texelSize * float2(0.5, 0.5));
            half4 K = GetScreenColor(uv + texelSize * float2(-1.0, 1.0));
            half4 L = GetScreenColor(uv + texelSize * float2(0.0, 1.0));
            half4 M = GetScreenColor(uv + texelSize * float2(1.0, 1.0));

            half2 div = (1.0 / 4.0) * half2(0.5, 0.125);

            half4 o = (D + E + I + J) * div.x;
            o += (A + B + G + F) * div.y;
            o += (B + C + H + G) * div.y;
            o += (F + G + L + K) * div.y;
            o += (G + H + M + L) * div.y;

            half3 color = o.xyz;
        #else
            half3 color = GetScreenColor(uv).xyz;
        #endif


        half3 SceneColor = color;
        half brightness = max(SceneColor.r, max(SceneColor.g, SceneColor.b));
        half softness = clamp(brightness - Threshold + ThresholdKnee, 0.0, 2.0 * ThresholdKnee);
        softness = (softness * softness) / (4.0 * ThresholdKnee + 1e-4);
        half multiplier = max(brightness - Threshold, softness) / max(brightness, 1e-4);
        SceneColor *= multiplier;
        SceneColor = max(SceneColor, 0);
        return half4(SceneColor, 1);
    }



    half4 FragBlurH(VaryingsDefault input): SV_Target
    {
        float texelSize = _BlitTexture_TexelSize.x * 2.0;
        float2 uv = input.uv;

        // 9-tap gaussian blur on the downsampled source
        half3 c0 = DecodeHDR(GetScreenColor(uv - float2(texelSize * 4.0, 0.0)));
        half3 c1 = DecodeHDR(GetScreenColor(uv - float2(texelSize * 3.0, 0.0)));
        half3 c2 = DecodeHDR(GetScreenColor(uv - float2(texelSize * 2.0, 0.0)));
        half3 c3 = DecodeHDR(GetScreenColor(uv - float2(texelSize * 1.0, 0.0)));
        half3 c4 = DecodeHDR(GetScreenColor(uv));
        half3 c5 = DecodeHDR(GetScreenColor(uv + float2(texelSize * 1.0, 0.0)));
        half3 c6 = DecodeHDR(GetScreenColor(uv + float2(texelSize * 2.0, 0.0)));
        half3 c7 = DecodeHDR(GetScreenColor(uv + float2(texelSize * 3.0, 0.0)));
        half3 c8 = DecodeHDR(GetScreenColor(uv + float2(texelSize * 4.0, 0.0)));

        half3 color = c0 * 0.01621622 + c1 * 0.05405405 + c2 * 0.12162162 +
        c3 * 0.19459459 + c4 * 0.22702703 + c5 * 0.19459459 +
        c6 * 0.12162162 + c7 * 0.05405405 + c8 * 0.01621622;

        return half4(SafeHDR(color), 1);
    }

    half4 FragBlurV(VaryingsDefault input): SV_Target
    {
        float texelSize = _BlitTexture_TexelSize.y;
        float2 uv = input.uv;

        // Optimized bilinear 5-tap gaussian on the same-sized source (9-tap equivalent)
        half3 c0 = DecodeHDR(GetScreenColor(uv - float2(0.0, texelSize * 3.23076923)));
        half3 c1 = DecodeHDR(GetScreenColor(uv - float2(0.0, texelSize * 1.38461538)));
        half3 c2 = DecodeHDR(GetScreenColor(uv));
        half3 c3 = DecodeHDR(GetScreenColor(uv + float2(0.0, texelSize * 1.38461538)));
        half3 c4 = DecodeHDR(GetScreenColor(uv + float2(0.0, texelSize * 3.23076923)));

        half3 color = c0 * 0.07027027 + c1 * 0.31621622
        + c2 * 0.22702703
        + c3 * 0.31621622 + c4 * 0.07027027;

        return half4(SafeHDR(color), 1);
    }

    half3 Upsample(float2 uv)
    {
        half3 highMip = DecodeHDR(SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, uv));

        #if _BLOOM_HQ && !defined(SHADER_API_GLES)
            half3 lowMip = DecodeHDR(SampleTexture2DBicubic(_SourceTexLowMip, sampler_LinearClamp, uv, _SourceTexLowMip_TexelSize.zwxy, (1.0).xx, 0.0));
        #else
            half3 lowMip = DecodeHDR(SAMPLE_TEXTURE2D(_SourceTexLowMip, sampler_LinearClamp, uv));
        #endif
        return lerp(highMip, lowMip, Scatter);
    }


    half4 FragUpsample(VaryingsDefault input): SV_Target
    {
        half3 color = Upsample(input.uv);
        return half4(color, 1);
    }

    half4 FragCombine(VaryingsDefault input): SV_Target
    {
        float2 uv = input.uv;
        half3 color = (0.0).xxx;

        color = GetScreenColor(uv).xyz;

        #if _BLOOM_HQ && !defined(SHADER_API_GLES)
            half3 bloom = DecodeHDR(SampleTexture2DBicubic(_Bloom_Texture, sampler_LinearClamp, uv, _Bloom_Texture_TexelSize.zwxy, (1.0).xx, 0.0));
        #else
            half3 bloom = DecodeHDR(SAMPLE_TEXTURE2D(_Bloom_Texture, sampler_LinearClamp, uv));
        #endif
        bloom *= Intensity;
        color += bloom;
        return half4(color, 1);
    }

    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        LOD 100
        ZTest Always ZWrite Off Cull Off

        //提取高亮区域
        Pass
        {
            Name "Bloom Prefilter"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment FragPrefilter

            #pragma multi_compile_local _ _BLOOM_HQ

            ENDHLSL

        }

        Pass
        {
            Name "Bloom Horizontal"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment FragBlurH

            ENDHLSL

        }

        Pass
        {
            Name "Bloom Vertical"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment FragBlurV

            ENDHLSL

        }

        
        Pass
        {
            Name "Bloom Upsample"
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment FragUpsample

            #pragma multi_compile_local _ _BLOOM_HQ

            ENDHLSL

        }

        Pass
        {
            Name "Bloom Combine"

            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment FragCombine

            #pragma multi_compile_local _ _BLOOM_HQ

            ENDHLSL

        }
    }
}