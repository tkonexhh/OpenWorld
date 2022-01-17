

Shader "HMK/AmplifyImpostor/Runtime"
{
    Properties
    {
        [MainColor]_BaseColor ("固有色", color) = (1, 1, 1, 1)
        [NoScaleOffset]_Albedo ("Impostor Albedo & Alpha", 2D) = "white" { }
        [NoScaleOffset]_Normals ("Impostor Normal & Depth", 2D) = "white" { }
        _AI_Clip ("Impostor Clip", Range(0, 1)) = 0.5
        [HideInInspector]_Frames ("Frames", Float) = 16
        [HideInInspector]_ImpostorSize ("Impostor Size", Float) = 1
        [HideInInspector]_Offset ("Offset", Vector) = (0, 0, 0, 0)
        [HideInInspector]_AI_SizeOffset ("Size & Offset", Vector) = (0, 0, 0, 0)
        _Parallax ("Parallax", Range(-1, 1)) = 1
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
            
            CBUFFER_START(UnityPerMaterial)
            uniform float _AI_Clip;
            uniform float _AI_FramesX;
            uniform float _AI_FramesY;
            uniform float _AI_ImpostorSize;
            uniform float _AI_Parallax;
            uniform float3 _AI_Offset;
            uniform float4 _AI_SizeOffset;
            
            CBUFFER_END

            TEXTURE2D(_Albedo);SAMPLER(sampler_Albedo);
            TEXTURE2D(_Normals);SAMPLER(sampler_Normals);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float4 UVsFrame1: TEXCOORD5;
                float4 UVsFrame2: TEXCOORD6;
                float4 UVsFrame3: TEXCOORD7;
                float4 octaframe: TEXCOORD8;
                float4 positionVS: TEXCOORD9;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };



            
            
            Varyings vert(Attributes input)
            {
                Varyings output;


                // OctaImpostorVertex(input.positionOS, input.normalOS, output.UVsFrame1, output.UVsFrame2, output.UVsFrame3, output.octaframe, output.positionVS);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;


                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                half4 var_MainTex = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, input.uv);
                return var_MainTex;
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
