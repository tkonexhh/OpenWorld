// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "HMK/UI/ImageSpriteAlpha4"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _AlphaTex ("MainTex A", 2D) = "white" { }
        _Color ("Color", COLOR) = (1, 1, 1, 1)
        _AlphaCut ("Alpha Cut", Float) = 0.1
        _ZWrite ("ZWrite", Float) = 1.0 // On

    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }
        Pass
        {
            Cull Back
            ZTest Lequal
            ZWrite [_ZWrite]
            Fog
            {
                Mode Off
            }
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            // #include "UnityCG.cginc"
            // #include "../CGIncludes/LingrenCG.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./../HLSLIncludes/UI/HMKUI.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Common.hlsl"
            
            #pragma fragment frag
            #pragma vertex vert

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float _AlphaCut;
            CBUFFER_END

            sampler2D _MainTex;
            sampler2D _AlphaTex;
            

            struct Input
            {
                float4 vertex: POSITION;
                float2 texcoord: TEXCOORD0;
            };
            
            struct OutPut
            {
                float4 vertex: POSITION;
                float2 texcoord: TEXCOORD0;
            };
            
            OutPut vert(Input v)
            {
                OutPut o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.texcoord = v.texcoord;
                return o;
            }
            
            half4 frag(OutPut i): COLOR
            {
                half4 color = tex2D(_MainTex, i.texcoord);
                half colorA = DecodeRGB2Alpha(tex2D(_AlphaTex, i.texcoord).rgb);
                clip(colorA - _AlphaCut);
                color.a = (colorA - _AlphaCut) / (1 - _AlphaCut);
                return color * _Color;
            }
            ENDHLSL

        }
    }
}
