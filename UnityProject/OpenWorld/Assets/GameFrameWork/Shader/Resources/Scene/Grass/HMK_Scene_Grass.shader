/*
这个Shader和InstancedIndirectGrass
是为了提供个地编与实际效果保持一致

实际上渲染用到的是InstancedIndirectGrass
*/
Shader "HMK/Scene/Grass"
{
    Properties
    {
        [Header(BaseColor)]
        _ColorTop ("ColorTop", color) = (0.5, 1, 0, 1)
        _ColorBottom ("ColorBottom", color) = (0, 1, 0, 1)
        _ColorRange ("ColorRange", range(-1, 1)) = 1.0

        [Header(Wind)]
        _WindStrength ("Wind Strength", range(0, 3)) = 1
        _WindHeight ("Wind Height", range(0, 3)) = 0.7

        [Header(Interactive)]//交互
        _InteractRange ("交互范围", range(0, 10)) = 1
        _InteractForce ("交互力量", range(0, 4)) = 1
        _InteractTopOffset ("交互上偏移", range(0, 4)) = 1
        _InteractBottomOffset ("交互下偏移", range(0, 4)) = 1


        [Header(Hue)]
        [Toggle(EFFECT_HUE_VARIATION)] _Hue ("Use Color Hue", Float) = 0
        _HueVariation ("Hue Variation xyz:color w:weight", Color) = (0, 0, 0, 0)

        //Make SRP Batch works
        // [HideInInspector]_InteractivesCount ("", float) = 100
        // [HideInInspector]_Interactives ("", vector) = (0, 0, 0, 0)

    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            Cull Off

            HLSLPROGRAM

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            //--------------------------------------
            // Material Keywords
            #pragma shader_feature EFFECT_HUE_VARIATION
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog

            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./HMK_Scene_Grass_Common.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _ColorTop;
            half4 _ColorBottom;
            half _ColorRange;

            half _InteractRange, _InteractForce, _InteractTopOffset, _InteractBottomOffset;
            //Global Property
            int _InteractivesCount;//交互物体数量
            half3 _Interactives[100];//交互物体 最大支持20个交互物体

            half _WindStrength, _WindHeight;

            #ifdef EFFECT_HUE_VARIATION
                half4 _HueVariation;
            #endif

            CBUFFER_END

            

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 color: COLOR0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                half3 positionWS = TransformObjectToWorld(input.positionOS);
                half mask = input.uv.y;
                //风力效果
                GrassApplyWind(_WindStrength, _WindHeight, mask, positionWS);
                //交互效果
                ApplyInteractive(_InteractivesCount, _Interactives, _InteractRange, _InteractForce, _InteractTopOffset, _InteractBottomOffset, mask, positionWS);

                //光照
                //草的顶点数量少,着色直接在顶点阶段做完
                half3 N = normalize(half3(0, 1, 0));
                HMKLightingData lightingData = InitLightingData(positionWS, N);
                HMKSurfaceData surfaceData;
                surfaceData.albedo = lerp(_ColorBottom, _ColorTop, saturate(input.uv.y + _ColorRange));

                #ifdef EFFECT_HUE_VARIATION
                    half3 lightingResult = GrassShadeAllLight(surfaceData, lightingData, input.positionOS.y, _HueVariation);
                #else
                    half3 lightingResult = GrassShadeAllLight(surfaceData, lightingData, input.positionOS.y);
                #endif
                
                output.positionCS = TransformWorldToHClip(positionWS);
                half fogFactor = ComputeFogFactor(output.positionCS.z);
                lightingResult = MixFog(lightingResult, fogFactor);
                output.color = lightingResult;
                
                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                return half4(input.color, 1);
            }
            ENDHLSL

        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull Off

            HLSLPROGRAM

            // #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // #include "./../Base/HMK_DepthOnlyPass.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./../../HLSLIncludes/Common/HMK_Common.hlsl"
            #include "./HMK_Scene_Grass_Common.hlsl"
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            
            CBUFFER_START(UnityPerMaterial)
            half _InteractRange, _InteractForce, _InteractTopOffset, _InteractBottomOffset;
            // //Global Property
            int _InteractivesCount;//交互物体数量
            half3 _Interactives[100];//交互物体 最大支持20个交互物体

            half _WindStrength, _WindHeight;
            CBUFFER_END

            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                half3 positionWS = TransformObjectToWorld(input.positionOS);

                //风力效果
                half mask = input.uv.y;
                GrassApplyWind(_WindStrength, _WindHeight, mask, positionWS);
                // //交互效果
                ApplyInteractive(_InteractivesCount, _Interactives, _InteractRange, _InteractForce, _InteractTopOffset, _InteractBottomOffset, mask, positionWS);

                output.positionCS = TransformWorldToHClip(positionWS);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input): SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                return 0;
            }

            ENDHLSL

        }
    }
    Fallback "Universal Render Pipeline/Particles/Simple Lit"
}


