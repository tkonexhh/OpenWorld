// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "HMK/UI/DefaultAlpha4"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" { }
        _AlphaTex ("Sprite Alpha Texture", 2D) = "white" { }
        _Color ("Tint", Color) = (1, 1, 1, 1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" "CanUseSpriteAtlas" = "True" }

        Stencil
        {
            Ref[_Stencil]
            Comp[_StencilComp]
            Pass[_StencilOp]
            ReadMask[_StencilReadMask]
            WriteMask[_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest[unity_GUIZTestMode]
        Blend One OneMinusSrcAlpha
        ColorMask[_ColorMask]

        Pass
        {
            Name "Default"
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            //#include "UnityCG.cginc"
            //#include "UnityUI.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./../HLSLIncludes/UI/HMKUI.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Common.hlsl"

            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex: POSITION;
                float4 color: COLOR;
                float2 texcoord: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex: SV_POSITION;
                half4 color: COLOR;
                float2 texcoord: TEXCOORD0;
                float4 worldPosition: TEXCOORD1;
                half4 mask: TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            sampler2D _AlphaTex;
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            half4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
            float _UIMaskSoftnessX;
            float _UIMaskSoftnessY;
            CBUFFER_END

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                float4 vPosition = TransformObjectToHClip(v.vertex.xyz);
                OUT.worldPosition = v.vertex;
                OUT.vertex = vPosition;

                float2 pixelSize = vPosition.w;
                pixelSize /= float2(1, 1) * abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));

                float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
                float2 maskUV = (v.vertex.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
                OUT.texcoord = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
                OUT.mask = half4(v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_UIMaskSoftnessX, _UIMaskSoftnessY) + abs(pixelSize.xy)));

                OUT.color = v.color * _Color;
                return OUT;
            }

            half4 frag(v2f IN): SV_Target
            {
                half4 texResult = tex2D(_MainTex, IN.texcoord);
                half3 colorRGB = texResult.rgb;
                half colorA = DecodeRGB2Alpha(tex2D(_AlphaTex, IN.texcoord).rgb);
                half4 finalColor = (half4(colorRGB, colorA) + _TextureSampleAdd) * IN.color;

                /*half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd);
                half4 finalColor = color * IN.color;*/

                #ifdef UNITY_UI_CLIP_RECT
                    half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(IN.mask.xy)) * IN.mask.zw);
                    finalColor.a *= m.x * m.y;
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                    clip(finalColor.a - 0.001);
                #endif

                // gray
                half pixLum = luminance(colorRGB);
                half grayWeight = (IN.color.r + IN.color.g + IN.color.b) * 0.33333;
                grayWeight = min(grayWeight * 256.0, 1.0);
                finalColor.rgb = lerp(half3(pixLum, pixLum, pixLum), finalColor.rgb, grayWeight);
                finalColor.rgb *= finalColor.a;

                return finalColor;
            }
            ENDHLSL

        }
    }
}
