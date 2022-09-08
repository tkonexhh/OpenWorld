// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "HMK/UI/ImageSprite"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _Color ("Color", COLOR) = (1, 1, 1, 1)
        _AlphaCut ("Alpha Cut", Float) = 0.1
        _ZWrite ("ZWrite", Float) = 1.0 // On
        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull ("Cull Mode", Float) = 2 // Cull Back

    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Pass
        {
            Cull [_Cull]
            ZTest Lequal
            ZWrite [_ZWrite]
            Fog
            {
                Mode Off
            }
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            // #include "UnityCG.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma fragment frag
            #pragma vertex vert

            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float _AlphaCut;
            CBUFFER_END

            sampler2D _MainTex;
            

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

            float4 frag(OutPut i): COLOR
            {
                float4 color = tex2D(_MainTex, i.texcoord);
                clip(color.a - _AlphaCut);
                color.a = (color.a - _AlphaCut) / (1 - _AlphaCut);
                return color * _Color;
            }
            ENDHLSL

        }
    }
}
