Shader "HMK/Scene/InstancedIndirectGrass"
{
    Properties
    {
        //_MainTex ("BaseColor", 2D) = "white" { }
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
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            //--------------------------------------
            // Material Keywords
            #pragma shader_feature EFFECT_HUE_VARIATION
            
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../../HLSLIncludes/Common/HMK_Struct.hlsl"
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

            StructuredBuffer<GrassTRS> _AllInstancesTransformBuffer;//只含有坐标信息 下面需要吧缩放旋转也考虑上
            StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;
            // StructuredBuffer<uint> _ArgsBuffer;
            // uint _ArgsOffset;
            CBUFFER_END


            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 color: COLOR0;
            };

            Varyings vert(Attributes input, uint instanceID: SV_InstanceID)
            {
                //适用旋转
                uint indexID = instanceID ;//+ _ArgsBuffer[_ArgsOffset];
                uint id = _VisibleInstanceOnlyTransformIDBuffer[indexID];
                GrassTRS trs = _AllInstancesTransformBuffer[id];
                // GrassTRS trs = _AllInstancesTransformBuffer[instanceID];
                input.positionOS = mul(Rotation(half3(0, trs.rotateY, 0)), input.positionOS);

                Varyings output;
                half3 perGrassPivotPosWS = input.positionOS.xyz + trs.position;// _AllInstancesTransformBuffer[instanceID];
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
                half3 N = normalize(half3(0, 1, 0));
                HMKLightingData lightingData = InitLightingData(positionWS, N);
                HMKSurfaceData surfaceData;
                surfaceData.albedo = lerp(_ColorBottom, _ColorTop, saturate(input.positionOS.y + _ColorRange));

                #ifdef EFFECT_HUE_VARIATION
                    half3 lightingResult = GrassShadeAllLight(surfaceData, lightingData, input.positionOS.y, _HueVariation);
                #else
                    half3 lightingResult = GrassShadeAllLight(surfaceData, lightingData, input.positionOS.y);
                #endif
                output.color = lightingResult;
                output.positionCS = TransformWorldToHClip(positionWS);

                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
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
            // #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON

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
            };

            

            CBUFFER_START(UnityPerMaterial)

            half _InteractRange, _InteractForce, _InteractTopOffset, _InteractBottomOffset;
            //Global Property
            int _InteractivesCount;//交互物体数量
            half3 _Interactives[100];//交互物体 最大支持20个交互物体

            half _WindStrength, _WindHeight;
            
            StructuredBuffer<GrassTRS> _AllInstancesTransformBuffer;//只含有坐标信息 下面需要吧缩放旋转也考虑上
            StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;
            CBUFFER_END

            Varyings DepthOnlyVertex(Attributes input, uint instanceID: SV_InstanceID)
            {
                int id = _VisibleInstanceOnlyTransformIDBuffer[instanceID];
                //适用旋转
                GrassTRS trs = _AllInstancesTransformBuffer[id];
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
                return output;
            }

            half4 DepthOnlyFragment(Varyings input): SV_TARGET
            {
                return 0;
            }

            ENDHLSL

        }
    }
    Fallback "Universal Render Pipeline/Particles/Simple Lit"
}


