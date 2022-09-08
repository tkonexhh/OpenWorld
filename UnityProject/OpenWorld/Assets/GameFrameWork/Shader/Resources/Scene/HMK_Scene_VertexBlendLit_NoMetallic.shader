

Shader "HMK/Scene/VertexBlendLit_NoMetallic"
{
    Properties
    {
        [MainColor] _BaseColor ("固有色", color) = (1, 1, 1, 1)
        [SingleLine] _BaseMap ("BaseMap", 2D) = "white" { }
        [SingleLine] _NRAMap ("Basemap NRA", 2D) = "bump" { }

        [SingleLine]_DetailMap ("DetailMap", 2D) = "white" { }
        [SingleLine]_DetailNRAMap ("Detaail NRA", 2D) = "bump" { }

        _BumpScale ("Bump Scale", range(0, 1)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 1)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 1)) = 1
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)
    half4 _BaseColor;
    half _BumpScale;
    half _RoughnessScale, _OcclusionScale;
    CBUFFER_END

    TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
    TEXTURE2D(_NRAMap);SAMPLER(sampler_NRAMap);
    TEXTURE2D(_DetailMap);SAMPLER(sampler_DetailMap);
    TEXTURE2D(_DetailNRAMap);SAMPLER(sampler_DetailNRAMap);
    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
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
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma shader_feature _TextureView _VertexView

            #pragma vertex vert
            #pragma fragment frag


            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Normal.hlsl"
            
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                #if defined(LIGHTMAP_ON)
                    float2 lightmapUV: TEXCOORD1;
                #endif
                float3 normalOS: NORMAL;
                half4 tangentOS: TANGENT;
                half4 color: COLOR;
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
                float3 normalWS: NORMAL;
                half3 tangentWS: TEXCOORD3;
                half3 bitangentWS: TEXCOORD4;
                half4 color: COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            HMKLightingData InitLightingData(Varyings input, float2 normalXY)
            {
                //采样法线贴图
                float3 normalTS;
                NormalReconstructZ(normalXY, normalTS);
                
                // half3 normalTS = UnpackNormalScale(var_NormalMap, _BumpScale);
                half3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                float3 normalWS = TransformTangentToWorld(normalTS, TBN) ;
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
                
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = input.uv;
                float3 normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));
                float3 tangentWS = TransformObjectToWorldDir(input.tangentOS);
                half tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
                float3 bitangentWS = cross(normalWS, tangentWS) * tangentSign;
                
                output.normalWS = normalWS;
                output.tangentWS = tangentWS;
                output.bitangentWS = bitangentWS;
                
                #if defined(LIGHTMAP_ON)
                    HMK_OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                #endif
                output.color = input.color;
                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                float2 uv = input.uv;
                
                half detailMask = input.color.r;
                #ifdef _VertexView
                    return detailMask;
                #endif
                half4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
                half4 var_DetailMap = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, uv);
                half4 var_NRAMap = SAMPLE_TEXTURE2D(_NRAMap, sampler_NRAMap, uv);
                half4 var_DetailNRAMap = SAMPLE_TEXTURE2D(_DetailNRAMap, sampler_DetailNRAMap, uv);
                var_NRAMap = lerp(var_NRAMap, var_DetailNRAMap, detailMask);

                float2 normalXY = (var_NRAMap.rg);
                normalXY = normalXY * 2 - 1;
                float roughness = var_NRAMap.b;
                float occlusion = var_NRAMap.a;

                
                half3 albedo = lerp(var_BaseMap.rgb, var_DetailMap, detailMask) * _BaseColor.rgb;
                half alpha = var_BaseMap.a;
                half metallic = 0;
                occlusion = LerpWhiteTo(occlusion, _OcclusionScale);
                roughness = roughness * _RoughnessScale;

                HMKSurfaceData surfaceData = InitSurfaceData(albedo, alpha, metallic, roughness, occlusion);

                #if defined(_ALPHATEST_ON)
                    clip(surfaceData.alpha - _Cutoff);
                #endif


                HMKLightingData lightingData = InitLightingData(input, normalXY);
                
                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                

                return half4(finalRGB, surfaceData.alpha);
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
