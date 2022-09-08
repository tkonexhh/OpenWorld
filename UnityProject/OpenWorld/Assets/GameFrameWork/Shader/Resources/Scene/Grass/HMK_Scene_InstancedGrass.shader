Shader "HMK/Scene/Grass"
{
    Properties
    {
        [Header(BaseColor)]
        // _CutOff ("Cut off", range(0, 1)) = 0.5
        _ColorTop ("ColorTop", color) = (0.5, 1, 0, 1)
        _ColorBottom ("ColorBottom", color) = (0, 1, 0, 1)
        _ColorRange ("ColorRange", range(-1, 1)) = 1.0
        [Header(Specular)]
        _SpecularStrength ("Specular Strength", range(0, 3)) = 1
        _SpecularColor ("Specular Color", Color) = (0, 0, 0, 0)


        [Header(Randomlized)]
        _WindVertexRand ("Vertex randomization", Range(0.0, 1.0)) = 0.6
        _WindObjectRand ("Object randomization", Range(0.0, 1.0)) = 0.5
        _WindRandStrength ("Random per-object strength", Range(0.0, 1.0)) = 0.5
        

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
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./HMK_Scene_Grass_Input.hlsl"
            #include "./HMK_Scene_Grass_Common.hlsl"
            #include "./../../HLSLIncludes/Common/HMK_Dither.hlsl"
            #include "./../../HLSLIncludes/Common/HMK_Common.hlsl"
            
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
                float3 positionWS: TEXCOORD2;
                float4 positionSS: TEXCOORD3;
                float3 color: COLOR0;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                float3 positionOS = input.positionOS.xyz;
                float3 positionOSCut = 0;
                float3 positionWS = TransformObjectToWorld(positionOS);
                float3 positionWS_Cut = TransformObjectToWorld(positionOSCut);
                

                half mask = input.uv.y;

                WindSettings windSettings = InitWindSettings(mask, _WindVertexRand, _WindObjectRand, _WindRandStrength);
                BendSettings bendSettings = InitBendSettings(mask);
                half4 windVec = GetWindOffset2(positionOS, positionWS, windSettings, ObjectPosRand01());
                half4 bendVec = GetBendOffset(positionWS, bendSettings);

                half3 offsets = lerp(windVec.xyz, bendVec.xyz, bendVec.a);
                
                // offsets = lerp(offsets, float3(offsets.x, 10, offsets.z), cutVec.r);
                // offsets.y = lerp(offsets.y, -10, cutVec.r);
                positionWS.xyz -= offsets.xyz;

                half4 cutVec = GetCut(positionWS_Cut);
                half cutValue = step(0.9, cutVec.r);
                positionWS = lerp(positionWS, positionWS_Cut, cutValue);

                //光照
                //草的顶点数量少,着色直接在顶点阶段做完
                half3 N = half3(0, 1, 0);
                HMKLightingData lightingData = InitLightingData(positionWS, N);
                HMKSurfaceData surfaceData;
                
                surfaceData.albedo = lerp(_ColorBottom, _ColorTop, saturate(input.uv.y + _ColorRange));//上下渐变颜色
                surfaceData.albedo = lerp(surfaceData.albedo, surfaceData.albedo * _BendTint.rgb, bendVec.a);//压倒颜色
                surfaceData.albedo = ApplyHueColor(surfaceData.albedo, _HueVariation);//颜色渐变

                half3 lightingResult = GrassShadeAllLight(surfaceData, lightingData, input.positionOS.y, _SpecularStrength);
                
                
                output.positionCS = TransformWorldToHClip(positionWS);
                output.positionWS = positionWS;
                output.positionSS = ComputeScreenPos(output.positionCS);
                
                output.color = lightingResult;
                output.color = lerp(output.color, _BurnTint.rgb, cutVec.b);//燃烧颜色

                output.uv = input.uv;

                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                

                // ApplyDistanceFade(_CutOff, input.positionCS, input.positionWS, _FadeParams);

                half f = DistanceFadeFactor(input.positionWS, _FadeParams);
                //  return f;
                half dither = DitherOutputSS(input.positionSS);
                //
                dither = step(dither, f);
                clip(dither - 0.5);
                // return dither;

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

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./../../HLSLIncludes/Common/HMK_Common.hlsl"
            #include "./HMK_Scene_Grass_Input.hlsl"
            #include "./HMK_Scene_Grass_Common.hlsl"
            
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
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 positionOS = input.positionOS.xyz;
                float3 positionOSCut = 0;
                float3 positionWS = TransformObjectToWorld(positionOS);
                float3 positionWS_Cut = TransformObjectToWorld(positionOSCut);
                
                half mask = input.uv.y;

                WindSettings windSettings = InitWindSettings(mask, _WindVertexRand, _WindObjectRand, _WindRandStrength);
                BendSettings bendSettings = InitBendSettings(mask);
                half4 windVec = GetWindOffset2(positionOS, positionWS, windSettings, ObjectPosRand01());
                half4 bendVec = GetBendOffset(positionWS, bendSettings);
                half3 offsets = lerp(windVec.xyz, bendVec.xyz, bendVec.a);
                positionWS.xz -= offsets.xz;
                positionWS.y -= offsets.y;

                half4 cutVec = GetCut(positionWS_Cut);
                half cutValue = step(0.9, cutVec.r);
                positionWS = lerp(positionWS, positionWS_Cut, cutValue);

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


