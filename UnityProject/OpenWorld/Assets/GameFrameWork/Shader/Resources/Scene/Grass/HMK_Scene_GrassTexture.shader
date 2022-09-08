/*
这个Shader和InstancedIndirectGrass
是为了提供个地编与实际效果保持一致

实际上渲染用到的是InstancedIndirectGrass
*/
Shader "HMK/Scene/GrassTexture"
{
    Properties
    {
        [Header(Option)]
        [Toggle(_ALPHATEST_ON)]_AlphaClip ("__clip", Float) = 0.0
        _CutOff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        
        _BaseColor ("Base Color", color) = (1, 1, 1, 1)
        _BaseMap ("BaseMap", 2D) = "white" { }
        
        [Header(Specular)]
        _SpecularStrength ("Specular Strength", range(0, 3)) = 1
        _SpecularColor ("Specular Color", Color) = (0, 0, 0, 0)


        [Header(Randomlized)]
        _WindVertexRand ("Vertex randomization", Range(0.0, 1.0)) = 0.6
        _WindObjectRand ("Object randomization", Range(0.0, 1.0)) = 0.5
        _WindRandStrength ("Random per-object strength", Range(0.0, 1.0)) = 0.5
        

        [Header(Bending)]
        _BendTint ("Bending tint", Color) = (0.8, 0.8, 0.8, 1.0)


        [Header(Hue)]
        _HueVariation ("Hue Variation xyz:color w:weight", Color) = (1, 0.63, 0, 0)
        [Header(Fade)]
        _FadeParams ("Fade params (X=Start, Y=End, Z=Toggle W =Interverse", vector) = (50, 60, 0, 0)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            Cull Off
            ZWrite On

            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./HMK_Scene_Grass_Input.hlsl"
            #include "./HMK_Scene_Grass_Common.hlsl"
            #include "./../../HLSLIncludes/Common/Fog.hlsl"


            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float2 uv2: TEXCOORD1;
                half4 color: COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct Varyings
            {
                float4 positionOS: TEXCOORD3;
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD0;
                float2 uv2: TEXCOORD1;
            };


            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                float3 positionOS = input.positionOS.xyz;
                float3 positionWS = TransformObjectToWorld(positionOS);
                half mask = input.uv2.y;

                WindSettings windSettings = InitWindSettings(mask, _WindVertexRand, _WindObjectRand, _WindRandStrength);
                BendSettings bendSettings = InitBendSettings(mask);
                float4 windVec = GetWindOffset2(positionOS, positionWS, windSettings, ObjectPosRand01());
                float4 bendVec = GetBendOffset(positionWS, bendSettings);
                float3 offsets = lerp(windVec.xyz, bendVec.xyz, bendVec.a);
                positionWS.xz -= offsets.xz;
                positionWS.y -= offsets.y;

                output.positionWS = positionWS;
                output.positionOS = input.positionOS;
                output.positionCS = TransformWorldToHClip(positionWS);
                output.uv = input.uv;
                output.uv2 = input.uv2;
                
                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                // return input.uv2.y;
                //需要采样贴图了 光照不能放在顶点阶段做了
                half3 N = normalize(half3(0, 1, 0));
                HMKLightingData lightingData = InitLightingData(input.positionWS, N);

                half4 var_MainTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                HMKSurfaceData surfaceData;
                surfaceData.albedo = var_MainTex.rgb * _BaseColor.rgb;
                surfaceData.alpha = var_MainTex.a;
                #if defined(_ALPHATEST_ON)
                    clip(surfaceData.alpha - _CutOff);
                #endif
                half3 lightingResult = GrassShadeAllLight(surfaceData, lightingData, input.positionOS.y, _SpecularStrength);
                half3 finalRGB = lightingResult;
                // #if _FOG_ON
                //     finalRGB = ApplyFog(finalRGB, input.positionWS);
                // #endif

                return half4(finalRGB, 1);
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

            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // #include "./../Base/HMK_DepthOnlyPass.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./../../HLSLIncludes/Common/HMK_Common.hlsl"
            #include "./HMK_Scene_Grass_Input.hlsl"
            #include "./HMK_Scene_Grass_Common.hlsl"
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float2 uv2: TEXCOORD1;
                half4 color: COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            

            

            // #if defined(_ALPHATEST_ON)
            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            // #endif

            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 positionOS = input.positionOS.xyz;
                float3 positionWS = TransformObjectToWorld(positionOS);
                half mask = input.uv2.y;

                WindSettings windSettings = InitWindSettings(mask, _WindVertexRand, _WindObjectRand, _WindRandStrength);
                BendSettings bendSettings = InitBendSettings(mask);
                float4 windVec = GetWindOffset2(positionOS, positionWS, windSettings, ObjectPosRand01());
                float4 bendVec = GetBendOffset(positionWS, bendSettings);
                float3 offsets = lerp(windVec.xyz, bendVec.xyz, bendVec.a);
                positionWS.xz -= offsets.xz;
                positionWS.y -= offsets.y;


                output.positionWS = positionWS;
                output.positionCS = TransformWorldToHClip(positionWS);
                output.uv = input.uv;

                return output;
            }

            half4 DepthOnlyFragment(Varyings input): SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                #if defined(_ALPHATEST_ON)
                    half4 var_Base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                    half alpha = var_Base.a;
                    clip(alpha - _CutOff);
                #endif

                return 0;
            }

            ENDHLSL

        }
    }
    Fallback "Universal Render Pipeline/Particles/Simple Lit"
}


