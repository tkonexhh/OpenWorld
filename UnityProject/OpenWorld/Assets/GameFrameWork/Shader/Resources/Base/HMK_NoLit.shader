

Shader "HMK/NoLit"
{
    Properties
    {
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Header(Base Color)]
        [MainColor]_BaseColor ("固有色", color) = (1, 1, 1, 1)
        [NoScaleOffset] _BaseMap ("BaseMap", 2D) = "white" { }
        [NoScaleOffset] _PBRMap ("PBR贴图 R:金属度 G:粗糙度 B:AO  A:Emission", 2D) = "white" { }
        [NORMAL] [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" { }
        _BumpScale ("Bump Scale", range(0, 3)) = 1
        _MetallicScale ("MetallicScale", range(0, 1)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 1)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 1)) = 1

        [Header(Emission)]
        _EmissionScale ("Emission Scale", range(0, 3)) = 0
        [HDR] _EmissionColor ("Emission Color", color) = (1, 1, 1)
        _BreathSpeed ("_BreathSpeed", float) = 1
        [Header(Option)]
        // Blending state
        [HideInInspector] _Surface ("__surface", Float) = 0.0
        [HideInInspector] _Blend ("__blend", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _AlphaClip ("__clip", Float) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)]  _Cull ("__Cull", float) = 2.0

        _ReceiveShadows ("Receive Shadows", Float) = 1.0
        // Editmode props
        [HideInInspector] _QueueOffset ("Queue offset", Float) = 0.0
    }
    SubShader
    {
        
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" "Queue" = "Transparent" }
            
            Cull[_Cull]
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            
            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature _PBRMAP_ON
            // #pragma multi_complie  _GIMAP_ON
            #pragma shader_feature  _EMISSION_BREATH_ON
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "./HMK_Lit_Input.hlsl"
            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                #if defined(LIGHTMAP_ON)
                    float2 lightmapUV: TEXCOORD1;
                #endif
                half3 normalOS: NORMAL;
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
                half3 normalWS: NORMAL;
                half3 tangentWS: TEXCOORD3;
                half3 bitangentWS: TEXCOORD4;
                // half fogFactor: TEXCOORD5;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            half4 GetFinalBaseColor(Varyings input)
            {
                return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) ;
            }


            HMKSurfaceData InitSurfaceData(Varyings input)
            {
                // half4 mra = SAMPLE_TEXTURE2D(_PBRMap, sampler_PBRMap, input.uv);
                float4 finalBaseColor = GetFinalBaseColor(input);
                
                half3 albedo = finalBaseColor.rgb * _BaseColor;
                half alpha = finalBaseColor.a;
                // #if defined(_PBRMAP_ON)
                //     half metallic = mra.r * _MetallicScale;
                //     half roughness = mra.g * _RoughnessScale;
                //     half occlusion = LerpWhiteTo(mra.b, _OcclusionScale);
                //     half3 emission = mra.a * _EmissionScale * _EmissionColor;
                // #else
                    half metallic = _MetallicScale;
                half roughness = _RoughnessScale;
                half occlusion = _OcclusionScale;
                half3 emission = _EmissionScale * _EmissionColor;
                // #endif

                #ifdef _EMISSION_BREATH_ON
                    half breath = sin((_Time.y * _BreathSpeed)) ;//-1 1
                    emission *= lerp(0.1, 1, (breath + 1) * 0.5);// 0 1
                #endif

                return InitSurfaceData(albedo, alpha, metallic, roughness, occlusion, emission);
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                float3 normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));
                float3 tangentWS = TransformObjectToWorldDir(input.tangentOS);
                half tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
                float3 bitangentWS = cross(normalWS, tangentWS) * tangentSign;
                // half fogFactor = ComputeFogFactor(output.positionCS.z);

                output.normalWS = normalWS;
                output.tangentWS = tangentWS;
                output.bitangentWS = bitangentWS;
                // output.fogFactor = fogFactor;
                
                #if defined(LIGHTMAP_ON)
                    HMK_OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                #endif
                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                HMKSurfaceData surfaceData = InitSurfaceData(input);
                // HMKLightingData lightingData = InitLightingData(input);
                
                #if defined(_ALPHATEST_ON)
                    clip(surfaceData.alpha - _Cutoff);
                #endif
                

                // half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                // finalRGB = MixFog(finalRGB, input.fogFactor);
                return half4(surfaceData.albedo, surfaceData.alpha);
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

            #include "./HMK_Lit_Input.hlsl"
            #include "./HMK_ShadowCasterPass.hlsl"

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

            #include "./HMK_Lit_Input.hlsl"
            #include "./HMK_DepthOnlyPass.hlsl"

            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
