

Shader "HMK/RenderFeature/SSAO"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Common.hlsl"
            
            CBUFFER_START(UnityPerMaterial)


            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float4 screenPos: TEXCOORD3;
                float3 viewDir: TEXCOORD2;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                float4 screenPos = ComputeScreenPos(output.positionCS);
                float4 ndcPos = (screenPos / screenPos.w) * 2 - 1;
                //计算至远屏幕方向
                float3 clipVec = float3(ndcPos.x, ndcPos.y, 1.0) * _ProjectionParams.z;
                //通过逆投影矩阵（Inverse Projection Matrix）将点转换到观察空间（View space）。
                float3 viewDir = mul(unity_CameraInvProjection, clipVec.xyzz).xyz;
                output.uv = input.uv;
                output.viewDir = viewDir;
                output.screenPos = screenPos;
                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, input.screenPos.xy);
                float linearDepth = Linear01Depth(depth);
                // return linearDepth;
                float3 positionVS = linearDepth * input.viewDir;
                return half4(positionVS, 1);
                // half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                // return var_MainTex;

            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
