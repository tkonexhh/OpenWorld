Shader "HMK/Scene/InstancedIndirectGrass"
{
    Properties
    {
        [Header(BaseColor)]
        _CutOff ("Cut off", range(0, 1)) = 0.5
        _ColorTop ("ColorTop", color) = (0.5, 1, 0, 1)
        _ColorBottom ("ColorBottom", color) = (0, 1, 0, 1)
        _ColorRange ("ColorRange", range(-1, 1)) = 1.0
        _SpecularStrength ("Specular Strength", range(0, 2)) = 0.3


        [Header(Randomlized)]
        _WindVertexRand ("Vertex randomization", Range(0.0, 1.0)) = 0.6
        _WindObjectRand ("Object randomization", Range(0.0, 1.0)) = 0.5
        _WindRandStrength ("Random per-object strength", Range(0.0, 1.0)) = 0.5
        

        // [Header(Gusting)]
        // _WindGustStrength ("Gusting strength", Range(0.0, 1.0)) = 0.2
        // _WindGustFreq ("Gusting frequency", Range(0.0, 10.0)) = 4
        // [NoScaleOffset] _WindGustMap ("Gust map", 2D) = "black" { }
        // _WindGustTint ("Gusting tint", Range(0.0, 1.0)) = 0.066

        [Header(Bending)]
        _BendTint ("Bending tint", Color) = (0.8, 0.8, 0.8, 1.0)
        _BurnTint ("Burn tint", Color) = (0, 0, 0, 1)


        [Header(Hue)]
        _HueVariation ("Hue Variation xyz:color w:weight", Color) = (1, 0.63, 0, 0)
        [Header(Fade)]
        _FadeParams ("Fade params (X=Start, Y=End, Z=Toggle W =Interverse", vector) = (50, 100, 0, 0)
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
            #include "./HMK_Scene_Grass_Input.hlsl"
            #include "./HMK_Scene_Grass_Common.hlsl"
            

            
            StructuredBuffer<GrassTRS> _AllInstancesTransformBuffer;//只含有坐标信息 下面需要吧缩放旋转也考虑上
            StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                half4 color: COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
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
                input.positionOS.xyz *= (trs.scale + 0.5);

                half mask = input.uv.y;
                //风力效果
                WindSettings windSettings = InitWindSettings(mask, _WindVertexRand, _WindObjectRand, _WindRandStrength);
                float4 windOffset = GetWindOffset(input.positionOS, positionWS, windSettings, ObjectPosRand01());
                positionWS.xz += windOffset.xz;
                positionWS.y -= windOffset.y;


                //交互效果
                // ApplyInteractive(_InteractivesCount, _Interactives, _InteractRange, _InteractForce, _InteractTopOffset, _InteractBottomOffset, mask, positionWS);

                //光照
                //草的顶点数量少,着色直接在顶点阶段做完
                half3 N = normalize(half3(0, 1, 0));
                HMKLightingData lightingData = InitLightingData(positionWS, N);
                HMKSurfaceData surfaceData;
                surfaceData.albedo = lerp(_ColorBottom, _ColorTop, saturate(input.positionOS.y + _ColorRange));

                #ifdef EFFECT_HUE_VARIATION
                    half3 lightingResult = GrassShadeAllLight(surfaceData, lightingData, input.positionOS.y, _SpecularStrength, _HueVariation);
                #else
                    half3 lightingResult = GrassShadeAllLight(surfaceData, lightingData, input.positionOS.y, _SpecularStrength);
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

            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./../../HLSLIncludes/Common/HMK_Struct.hlsl"
            #include "./HMK_Scene_Grass_Input.hlsl"
            #include "./HMK_Scene_Grass_Common.hlsl"
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                half4 color: COLOR;
            };
            
            struct Varyings
            {
                float4 positionCS: SV_POSITION;
            };

            StructuredBuffer<GrassTRS> _AllInstancesTransformBuffer;//只含有坐标信息 下面需要吧缩放旋转也考虑上
            StructuredBuffer<uint> _VisibleInstanceOnlyTransformIDBuffer;


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
                WindSettings windSettings = InitWindSettings(mask, _WindVertexRand, _WindObjectRand, _WindRandStrength);
                float4 windOffset = GetWindOffset(input.positionOS, positionWS, windSettings, ObjectPosRand01());
                positionWS.xz += windOffset.xz;
                positionWS.y -= windOffset.y;
                
                //交互效果
                // ApplyInteractive(_InteractivesCount, _Interactives, _InteractRange, _InteractForce, _InteractTopOffset, _InteractBottomOffset, mask, positionWS);

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


