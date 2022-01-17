Shader "HMK/Scene/InstancedIndirectGrassTexture"
{
    Properties
    {
        [Header(Option)]
        [Toggle(_ALPHATEST_ON)]_AlphaClip ("__clip", Float) = 0.0
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        
        _BaseColor ("Base Color", color) = (1, 1, 1, 1)
        _MainMap ("Main Texture", 2D) = "white" { }
        
        [Header(Wind)]
        _WindStrength ("Wind Strength", range(0, 3)) = 1
        _WindHeight ("Wind Height", range(0, 3)) = 0.7

        [Header(Interactive)]//交互
        _InteractRange ("交互范围", range(0, 10)) = 1
        _InteractForce ("交互力量", range(0, 4)) = 1
        _InteractTopOffset ("交互上偏移", range(0, 4)) = 1
        _InteractBottomOffset ("交互下偏移", range(0, 4)) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            ZWrite On
            ZTest Less
            Cull Off

            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ _ALPHATEST_ON
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
            #include "./../../HLSLIncludes/Common/HMK_Struct.hlsl"
            #include "./HMK_Scene_Grass_Common.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half _Cutoff;
            half4 _BaseColor;

            half _InteractRange, _InteractForce, _InteractTopOffset, _InteractBottomOffset;
            //Global Property
            int _InteractivesCount;//交互物体数量
            half3 _Interactives[100];//交互物体 最大支持20个交互物体

            half _WindStrength, _WindHeight;
            
            StructuredBuffer<GrassTRS> _AllInstancesTransformBuffer;//只含有坐标信息 下面需要吧缩放旋转也考虑上
            StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;
            CBUFFER_END

            
            TEXTURE2D(_MainMap);SAMPLER(sampler_MainMap);

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionOS: TEXCOORD3;
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD0;
            };
            

            Varyings vert(Attributes input, uint instanceID: SV_InstanceID)
            {
                //适用旋转
                GrassTRS trs = _AllInstancesTransformBuffer[_VisibleInstanceOnlyTransformIDBuffer[instanceID]];
                input.positionOS = mul(Rotation(half3(0, trs.rotateY, 0)), input.positionOS);

                Varyings output;
                half3 perGrassPivotPosWS = input.positionOS + trs.position;// _AllInstancesTransformBuffer[instanceID];
                half3 positionWS = perGrassPivotPosWS;
                
                //适用缩放
                input.positionOS.xyz *= (trs.scale + 0.2);

                half mask = input.uv.y;
                //风力效果
                GrassApplyWind(_WindStrength, _WindHeight, mask, positionWS);
                //交互效果
                ApplyInteractive(_InteractivesCount, _Interactives, _InteractRange, _InteractForce, _InteractTopOffset, _InteractBottomOffset, mask, positionWS);

                //光照
                //草的顶点数量少,着色直接在顶点阶段做完
                
                output.positionOS = input.positionOS;
                output.positionCS = TransformWorldToHClip(positionWS);
                output.positionWS = positionWS;
                output.uv = input.uv;
                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                //需要采样贴图了 光照不能放在顶点阶段做了
                half3 N = normalize(half3(0, 1, 0));
                HMKLightingData lightingData = InitLightingData(input.positionWS, N);

                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainMap, sampler_MainMap, input.uv);
                HMKSurfaceData surfaceData;
                surfaceData.albedo = var_MainTex.rgb * _BaseColor.rgb;
                surfaceData.alpha = var_MainTex.a;
                #if defined(_ALPHATEST_ON)
                    clip(surfaceData.alpha - _Cutoff);
                #endif
                half3 lightingResult = GrassShadeAllLight(surfaceData, lightingData, input.positionOS.y);
                half3 finalRGB = lightingResult;

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
            // #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON

            // #include "./../Base/HMK_DepthOnlyPass.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./../../HLSLIncludes/Common/HMK_Struct.hlsl"
            #include "./HMK_Scene_Grass_Common.hlsl"
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float uv: TEXCOORD0;
            };

            

            CBUFFER_START(UnityPerMaterial)
            #if defined(_ALPHATEST_ON)
                half _Cutoff;
            #endif
            
            half _InteractRange, _InteractForce, _InteractTopOffset, _InteractBottomOffset;
            //Global Property
            int _InteractivesCount;//交互物体数量
            half3 _Interactives[100];//交互物体 最大支持20个交互物体

            half _WindStrength, _WindHeight;
            
            StructuredBuffer<GrassTRS> _AllInstancesTransformBuffer;//只含有坐标信息 下面需要吧缩放旋转也考虑上
            StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;
            CBUFFER_END

            #if defined(_ALPHATEST_ON)
                TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            #endif

            Varyings DepthOnlyVertex(Attributes input, uint instanceID: SV_InstanceID)
            {
                //适用旋转
                GrassTRS trs = _AllInstancesTransformBuffer[_VisibleInstanceOnlyTransformIDBuffer[instanceID]];
                input.positionOS = mul(Rotation(half3(0, trs.rotateY, 0)), input.positionOS);

                Varyings output;
                half3 perGrassPivotPosWS = input.positionOS + trs.position;// _AllInstancesTransformBuffer[instanceID];
                half3 positionWS = perGrassPivotPosWS;
                
                //适用缩放
                input.positionOS.xyz *= trs.scale;

                //风力效果
                half mask = input.uv.y;
                GrassApplyWind(_WindStrength, _WindHeight, mask, positionWS);
                //交互效果
                ApplyInteractive(_InteractivesCount, _Interactives, _InteractRange, _InteractForce, _InteractTopOffset, _InteractBottomOffset, mask, positionWS);

                output.positionCS = TransformWorldToHClip(positionWS);
                output.uv = input.uv;
                return output;
            }

            half4 DepthOnlyFragment(Varyings input): SV_TARGET
            {
                #if defined(_ALPHATEST_ON)
                    half4 var_Base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                    half alpha = var_Base.a;
                    clip(alpha - _Cutoff);
                #endif

                return 0;
            }

            ENDHLSL

        }
    }
    Fallback "Universal Render Pipeline/Particles/Simple Lit"
}


