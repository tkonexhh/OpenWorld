//合并风场
Shader "HMK/Hidden/WindComposite"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalForward" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half2 _WindUV;
            half2 _WindUV1;
            half2 _WindUV2;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                half4 n1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv - _WindUV);
                half4 n2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv - _WindUV1);
                half3 n3 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv - _WindUV2);
                half4 n4 = 0;
                half4 sum = half4(n1.r, n1.g + n2.g, n1.b + n2.b + n3.b, 0);
                const half4 weights = half4(0.5, 0.25, 0.1250, 0.0625);
                return sum.r * weights.x + sum.g * weights.y + sum.b * weights.z;
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
