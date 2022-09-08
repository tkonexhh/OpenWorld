Shader "HMK/UI/DefaultAlpha4ComAndFont_Effect"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" { }
        _AlphaTex ("Sprite Alpha Texture", 2D) = "white" { }
        _FontAlphaTex ("Font Alpha Texture", 2D) = "white" { }
        _Color ("Tint", Color) = (1, 1, 1, 1)


        [Header(Outline)]
        [Toggle]_OutlineOn ("Outline Toggle", int) = 0
        _OutlineWidth ("Outline Width", range(0, 2)) = 0.5
        _OutlineColor ("Outline Color", color) = (1, 1, 1, 1)
        
        [HideInInspector] _StencilComp ("Stencil Comparison", Float) = 8
        [HideInInspector] _Stencil ("Stencil ID", Float) = 0
        [HideInInspector] _StencilOp ("Stencil Operation", Float) = 0
        [HideInInspector] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [HideInInspector] _StencilReadMask ("Stencil Read Mask", Float) = 255

        

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

            #pragma shader_feature_fragment _ _OutlineOn

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
                float4 texcoord: TEXCOORD0;
                float4 worldPosition: TEXCOORD1;
                half4 mask: TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            sampler2D _AlphaTex;
            sampler2D _FontAlphaTex;
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            half4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
            float _UIMaskSoftnessX, _UIMaskSoftnessY;

            half _OutlineWidth;
            half3 _OutlineColor;
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
                OUT.texcoord.xy = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
                OUT.texcoord.zw = GetFontEncodeUV(v.texcoord.xy - float2(1, 1));
                OUT.mask = half4(v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_UIMaskSoftnessX, _UIMaskSoftnessY) + abs(pixelSize.xy)));

                OUT.color = v.color * _Color;
                return OUT;
            }

            half4 frag(v2f IN): SV_Target
            {
                half3 colorComRGB = tex2D(_MainTex, IN.texcoord).rgb;
                half colorComA = DecodeRGB2Alpha(tex2D(_AlphaTex, IN.texcoord).rgb);

                half3 colorFontRGB = half3(1, 1, 1);
                half colorFontA = GetFontA(_FontAlphaTex, IN.texcoord - float4(1, 1, 0, 0));
                //fixed colorFontA = tex2D(_FontAlphaTex, IN.texcoord - float2(1, 1)).a;

                half4 factor = floor(IN.texcoord.x);

                //color
                half3 colorRGB = lerp(colorComRGB, colorFontRGB, factor);
                half colorA = lerp(colorComA, colorFontA, factor);

                half4 finalColor = (half4(colorRGB, colorA) + _TextureSampleAdd) * IN.color;
                finalColor.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);

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


                //outline

                {
                    #ifdef _OutlineOn
                        float a = tex2D(_MainTex, i.texcoord + float2(-1, 0) * _OutlineWidth).a;
                        a += tex2D(_MainTex, i.texcoord + float2(1, 0) * _OutlineWidth).a;
                        a += tex2D(_MainTex, i.texcoord + float2(0, 1) * _OutlineWidth).a;
                        a += tex2D(_MainTex, i.texcoord + float2(0, -1) * _OutlineWidth).a;


                        a += tex2D(_MainTex, i.texcoord + float2(0.7071, 0.7071) * _OutlineWidth).a;
                        a += tex2D(_MainTex, i.texcoord + float2(-0.7071, 0.7071) * _OutlineWidth).a;
                        a += tex2D(_MainTex, i.texcoord + float2(0.7071, -0.7071) * _OutlineWidth).a;
                        a += tex2D(_MainTex, i.texcoord + float2(-0.7071, -0.7071) * _OutlineWidth).a;

                        clip(saturate(a) - colorRGB.a);
                    #endif
                }

                return finalColor;
            }
            ENDHLSL

        }
    }
}
