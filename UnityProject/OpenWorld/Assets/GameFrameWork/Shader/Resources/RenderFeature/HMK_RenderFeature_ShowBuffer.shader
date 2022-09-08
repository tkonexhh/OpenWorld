Shader "Hidden/RenderFeature/ShowBuffer"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "./../HLSLIncludes/Common/HMK_Common.hlsl"
    #include "./../../../Script/Render/Volume/Shader/PostProcessing.hlsl"

    CBUFFER_START(UnityPerMaterial)
    float _Args;
    float4 _CameraDepthTexture_TexelSize;
    CBUFFER_END



    
    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "Depth Texture"
            
            HLSLPROGRAM

            #pragma vertex VertDefault
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            float4 frag(VaryingsDefault input): SV_Target
            {
                half depth = SampleSceneDepth(input.uv).r;
                return Linear01Depth(depth, _ZBufferParams) * _Args;
            }
            
            ENDHLSL

        }

        Pass
        {
            Name "World Normal"
            HLSLPROGRAM

            #pragma vertex VertWorld
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Common.hlsl"

            float3 reconstructPosition(in float2 uv, in float z, in float4x4 InvVP)
            {
                float x = uv.x * 2.0f - 1.0f;
                float y = (1.0 - uv.y) * 2.0f - 1.0f;
                float4 position_s = float4(x, y, z, 1.0f);
                float4 position_v = mul(InvVP, position_s);
                return position_v.xyz / position_v.w;
            }
            

            half4 frag(VaryingsWorld i): SV_Target
            {
                float2 uv = i.uv;
                float2 uv0 = uv; // center
                float2 uv1 = uv + float2(1, 0) * _MainTex_TexelSize.xy; // right
                float2 uv2 = uv + float2(0, 1) * _MainTex_TexelSize.xy; // top

                float depth0 = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, uv0, 0).r;
                float depth1 = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, uv1, 0).r;
                float depth2 = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, uv2, 0).r;

                float3 P0 = reconstructPosition(uv0, depth0, unity_CameraInvProjection);
                float3 P1 = reconstructPosition(uv1, depth1, unity_CameraInvProjection);
                float3 P2 = reconstructPosition(uv2, depth2, unity_CameraInvProjection);

                float3 normal = normalize(cross(P1 - P0, P2 - P0));
                return half4(normal, 1);
            }

            ENDHLSL

        }
    }
    FallBack "Diffuse"
}