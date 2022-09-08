

Shader "HMK/Scene/Flag"
{
    Properties
    {
        [Header(Option)]
        [Toggle(_ALPHATEST_ON)] _AlphaClip ("__clip", Float) = 0.0
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Header(Base Color)]
        [MainColor]_BaseColor ("固有色", color) = (1, 1, 1, 1)
        [NoScaleOffset]_BaseMap ("BaseMap", 2D) = "white" { }
        // [NoScaleOffset]_NormalPBRMap ("RG:法线 B:粗糙度 A:AO", 2D) = "bump" { }
        // _BumpScale ("Bump Scale", range(0, 3)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 1)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 1)) = 1

        _WindDir ("风频率(xyz)", Vector) = (1, 2, 3, 0)
        _WindPow ("风强度(xyz)", Vector) = (1, 0, 2, 0)
        _TimeScale ("风速", range(0, 200)) = 1
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "./Hidden/Wind.hlsl"

    CBUFFER_START(UnityPerMaterial)
    half4 _BaseColor;
    // half _BumpScale;
    half _RoughnessScale, _OcclusionScale;
    half _Cutoff;

    float4 _WindDir;
    float4 _WindPow;
    float _TimeScale;

    CBUFFER_END

    TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

    float3 GetWindOffset(float3 positionOS, float mask)
    {
        return float3(
            sin((positionOS.z * _WindDir.z + positionOS.y * _WindDir.y) + LeavesPRBOffset * _TimeScale) * _WindPow.x,
            sin((positionOS.x * _WindDir.x + positionOS.z * _WindDir.z) + LeavesPRBOffset * _TimeScale) * _WindPow.y,
            sin((positionOS.x * _WindDir.x + positionOS.y * _WindDir.y) + LeavesPRBOffset * _TimeScale) * _WindPow.z)
        * mask;
    }


    ENDHLSL

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
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile _ LOD_FADE_CROSSFADE
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #pragma vertex vert
            #pragma fragment frag


            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Normal.hlsl"
            

            // TEXTURE2D(_NormalPBRMap);SAMPLER(sampler_NormalPBRMap);

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                #if defined(LIGHTMAP_ON)
                    float2 lightmapUV: TEXCOORD1;
                #endif
                float2 uv2: TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD0;
                #if defined(LIGHTMAP_ON)
                    HMK_DECLARE_LIGHTMAP(lightmapUV, 1);
                #endif
                // float2 uv2: TEXCOORD1;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            HMKLightingData InitLightingData(Varyings input)
            {
                float3 normalWS = float3(0, 1, 0);
                #if defined(LIGHTMAP_ON)
                    return InitLightingData(input.positionWS, normalWS, input.lightmapUV);
                #else
                    return InitLightingData(input.positionWS, normalWS);
                #endif
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                
                input.positionOS.xyz += GetWindOffset(input.positionOS.xyz, input.uv2.y);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = input.uv;
                // output.uv2 = input.uv2;
                
                #if defined(LIGHTMAP_ON)
                    HMK_OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                #endif
                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                float2 uv = input.uv;
                // float2 uv2 = input.uv2;
                // return input.uv2.y;
                
                half4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
                
                
                half3 albedo = var_BaseMap.rgb * _BaseColor.rgb;
                half alpha = var_BaseMap.a;
                half metallic = 0;
                half occlusion = 1;//LerpWhiteTo(occlusion, _OcclusionScale);
                half roughness = _RoughnessScale;//roughness * _RoughnessScale;
                half emission = 0;
                HMKSurfaceData surfaceData = InitSurfaceData(albedo, alpha, metallic, roughness, occlusion, emission);
                #if defined(_ALPHATEST_ON)
                    clip(surfaceData.alpha - _Cutoff);
                #endif


                HMKLightingData lightingData = InitLightingData(input);
                
                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                

                return half4(finalRGB, surfaceData.alpha);
            }
            
            ENDHLSL

        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            Cull Off

            HLSLPROGRAM

            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            // #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Shadow.hlsl"
            // #include "./../Base/HMK_ShadowCasterPass.hlsl"
            

            struct Attributes
            {
                float4 positionOS: POSITION;
                float3 normalOS: NORMAL;
                float2 uv: TEXCOORD0;
                float2 uv2: TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float4 positionCS: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);

                output.uv = input.uv;
                input.positionOS.xyz += GetWindOffset(input.positionOS.xyz, input.uv2.y);
                output.positionCS = GetShadowPositionHClip(input.positionOS, input.normalOS);
                return output;
            }

            half4 ShadowPassFragment(Varyings input): SV_TARGET
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

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // #include "./../Base/HMK_DepthOnlyPass.hlsl"

            

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float2 uv2: TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float4 positionCS: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.uv = input.uv;//TRANSFORM_TEX(input.texcoord, _BaseMap);
                input.positionOS.xyz += GetWindOffset(input.positionOS.xyz, input.uv2.y);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input): SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if defined(_ALPHATEST_ON)
                    half4 var_Base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                    half alpha = var_Base.a;
                    clip(alpha - _Cutoff);
                #endif

                // Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
                return 0;
            }

            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
