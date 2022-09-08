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
            #include "./../../Hidden/Wind.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _LayerSpeeds;
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
            


            half4 frag(Varyings input): SV_Target
            {
                float2 uv1 = input.uv - _LayerSpeeds.xx * (WindMoveOffset);
                float2 uv2 = input.uv - _LayerSpeeds.yy * (WindMoveOffset);
                float2 uv3 = input.uv - _LayerSpeeds.zz * (WindMoveOffset);
                float2 uv4 = input.uv - _LayerSpeeds.ww * (WindMoveOffset);


                half4 n1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv1);
                half4 n2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv2);
                half4 n3 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv3);
                half4 n4 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv4);
                
                half4 sum = half4(n1.r, n1.g + n2.g, n1.b + n2.b + n3.b, n1.a + n2.a + n3.a + n4.a);
                const half4 weights = half4(0.5, 0.25, 0.1250, 0.0625);
                return(sum.r * weights.x + sum.g * weights.y + sum.b * weights.z + sum.a * weights.w) * (1 + _WindStrength * 0.01);
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
