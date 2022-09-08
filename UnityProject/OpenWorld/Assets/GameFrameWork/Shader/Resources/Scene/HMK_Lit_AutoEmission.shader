

Shader "HMK/Scene/Lit_AutoEmission"
{
    Properties
    {
        [Header(Option)]
        [Toggle(_ALPHATEST_ON)] _AlphaClip ("__clip", Float) = 0.0
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Enum(UnityEngine.Rendering.CullMode)]  _Cull ("__Cull", float) = 2.0
        
        
        [Header(Base Color)]
        [MainColor]_BaseColor ("固有色", color) = (1, 1, 1, 1)
        [SingleLine] _BaseMap ("BaseMap", 2D) = "white" { }
        [SingleLine] _PBRMap ("PBR贴图 R:金属度 G:粗糙度 B:AO  A:Emission", 2D) = "white" { }
        [NORMAL] [SingleLine]_NormalMap ("法线贴图", 2D) = "bump" { }
        _BumpScale ("Bump Scale", range(0, 3)) = 1
        _MetallicScale ("MetallicScale", range(0, 1)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 1)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 1)) = 1

        [Header(Emission)]
        _EmissionScale ("Emission Scale", range(0, 3)) = 0
        [HDR] _EmissionColor ("Emission Color", color) = (1, 1, 1)


        [Toggle(_Together_ON)]_Together_on ("Together_on", Int) = 0
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)
    half4 _BaseColor;
    half _BumpScale;
    half _MetallicScale, _RoughnessScale, _OcclusionScale, _EmissionScale;
    half _Cutoff;
    half3 _EmissionColor;

    float4 _BaseMap_ST;

    CBUFFER_END

    //全局变量
    half _LightOnFactor;//开灯Factor

    TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
    TEXTURE2D(_PBRMap);SAMPLER(sampler_PBRMap);
    TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);

    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature  _Together_ON
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                #if defined(LIGHTMAP_ON)
                    float2 lightmapUV: TEXCOORD1;
                #endif
                float3 normalOS: NORMAL;
                half4 tangentOS: TANGENT;
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
                half3 tangentWS: TANGENT;
                half3 bitangentWS: TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            HMKSurfaceData InitSurfaceData(Varyings input)
            {
                half4 mra = SAMPLE_TEXTURE2D(_PBRMap, sampler_PBRMap, input.uv);
                float4 finalBaseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                
                half3 albedo = finalBaseColor.rgb * _BaseColor;
                half alpha = finalBaseColor.a;
                #ifndef _Together_ON
                    float positionFactor = frac(UNITY_MATRIX_M[0].w + UNITY_MATRIX_M[1].w + UNITY_MATRIX_M[2].w) ;
                #else
                    float positionFactor = 1;
                #endif
                // positionFactor = pow(positionFactor, 5);
                float lightOnFactor = saturate(step(0.7, positionFactor + _LightOnFactor) * _LightOnFactor);
                
                half metallic = mra.r * _MetallicScale;
                half roughness = mra.g * _RoughnessScale;
                half occlusion = LerpWhiteTo(mra.b, _OcclusionScale);
                half3 emission = mra.a * _EmissionScale * _EmissionColor * lightOnFactor;
                // emission = lightOnFactor ;
                return InitSurfaceData(albedo, alpha, metallic, roughness, occlusion, emission);
            }

            HMKLightingData InitLightingData(Varyings input)
            {
                //采样法线贴图
                half4 var_NormalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv);
                // half3 bitangentWS = (cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w);
                half3 normalTS = UnpackNormalScale(var_NormalMap, _BumpScale);
                half3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                float3 normalWS = TransformTangentToWorld(normalTS, TBN);
                #if defined(LIGHTMAP_ON)
                    return InitLightingData(input.positionWS, normalWS, input.lightmapUV);
                #else
                    return InitLightingData(input.positionWS, normalWS);
                #endif
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
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

                return output;
            }


            half4 frag(Varyings input): SV_Target
            {

                HMKSurfaceData surfaceData = InitSurfaceData(input);
                HMKLightingData lightingData = InitLightingData(input);

                #if defined(_ALPHATEST_ON)
                    clip(surfaceData.alpha - _Cutoff);
                #endif

                // float positionFactor = frac(UNITY_MATRIX_M[0].w + UNITY_MATRIX_M[1].w + UNITY_MATRIX_M[2].w);
                // float lightOnFactor = saturate(positionFactor + _LightOnFactor) * _LightOnFactor;
                // lightOnFactor = saturate(lightOnFactor);
                // return lightOnFactor;
                // return half4(surfaceData.emission, 1);

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
            Cull[_Cull] // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

            HLSLPROGRAM

            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "./../Base/HMK_ShadowCasterPass.hlsl"

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

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // #include "./HMK_Lit_Input.hlsl"
            #include "./../Base/HMK_DepthOnlyPass.hlsl"

            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
