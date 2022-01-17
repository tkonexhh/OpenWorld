Shader "HMK/RenderFeature/ShowBuffer"
{
    Properties { }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "Depth Texture"
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float _Args;
            CBUFFER_END

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
                half4 col = SampleSceneDepth(input.uv) * _Args;
                return col;
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}