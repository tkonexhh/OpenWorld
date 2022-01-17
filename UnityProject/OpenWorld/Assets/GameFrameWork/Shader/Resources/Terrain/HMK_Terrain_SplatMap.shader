Shader "HMK/Terrain/Terrain_SplatMap"
{
    Properties
    {
        _Control ("Control (RGBA)", 2D) = "white" { }
        _Splat0 ("Splat0 (R)", 2D) = "white" { }
        _Splat1 ("Splat1 (G)", 2D) = "white" { }
        _Splat2 ("Splat2 (B)", 2D) = "white" { }
        _Splat3 ("Splat3 (A)", 2D) = "white" { }
        [NoScaleOffset]_NormalPBRMap0 ("RG:法线 B:粗糙度 A:AO", 2D) = "white" { }
        [NoScaleOffset]_NormalPBRMap1 ("RG:法线 B:粗糙度 A:AO", 2D) = "white" { }
        [NoScaleOffset]_NormalPBRMap2 ("RG:法线 B:粗糙度 A:AO", 2D) = "white" { }
        [NoScaleOffset]_NormalPBRMap3 ("RG:法线 B:粗糙度 A:AO", 2D) = "white" { }
        _RoughnessScale ("RoughnessScale", range(0, 3)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 3)) = 1
        
        _Weight ("Blend Weight", Range(0.001, 1)) = 1
        _UVScale ("贴图 UVScale", Range(0.001, 1)) = 0.2
        // _CliffBlend ("Cliff Blend", Range(0, 1)) = 0.2

        // [Toggle]_CliffRender ("三向峭壁渲染", float) = 0
        // _UVMap ("UVMap", 2D) = "white" { }

        [Toggle(EnableHeightBlend)]_EnalbeHeightBlend ("开启高度混合", float) = 0
        [Toggle(EnableAntiTilling)]_EnableAntiTilling ("开启ANTI-tilling", float) = 0
        _FadeDistance ("fadeDistance", vector) = (300, 1000, 2000, 0)
    }
    SubShader
    {
        Tags { "Queue" = "Geometry-100" "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            ZTest LEqual
            ZWrite On
            Blend One Zero
            
            HLSLPROGRAM

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            //--------------------------------------
            // Shader Feature
            #pragma shader_feature _ EnableHeightBlend
            #pragma shader_feature _ EnableAntiTilling
            // #pragma multi_compile  _GIMAP_ON

            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Normal.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
            float _Weight;
            float _UVScale;
            // float _CliffBlend;
            #if defined(EnableAntiTilling)
                float3 _FadeDistance;
            #endif
            float _RoughnessScale, _OcclusionScale;
            CBUFFER_END
            
            
            TEXTURE2D(_Control);SAMPLER(sampler_Control);
            TEXTURE2D(_Splat0);SAMPLER(sampler_Splat0);TEXTURE2D(_Splat1);TEXTURE2D(_Splat2);TEXTURE2D(_Splat3);
            TEXTURE2D(_NormalPBRMap0);SAMPLER(sampler_NormalPBRMap0);TEXTURE2D(_NormalPBRMap1);TEXTURE2D(_NormalPBRMap2);TEXTURE2D(_NormalPBRMap3);

            TEXTURE2D(_UVMap);SAMPLER(sampler_UVMap);
            

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
                float4 tangentOS: TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float4 tangentWS: TANGENT;
                half fogFactor: TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            void SplatmapMix(float2 uv, half4 splatControl, inout half3 albedo, inout half roughness, inout half occlusion, inout half3 normalTS)
            {
                half4 albedos[4];
                albedos[0] = SAMPLE_TEXTURE2D(_Splat0, sampler_Splat0, uv);
                albedos[1] = SAMPLE_TEXTURE2D(_Splat1, sampler_Splat0, uv);
                albedos[2] = SAMPLE_TEXTURE2D(_Splat2, sampler_Splat0, uv);
                albedos[3] = SAMPLE_TEXTURE2D(_Splat3, sampler_Splat0, uv);


                half4 normalRASamples[4];
                normalRASamples[0] = SAMPLE_TEXTURE2D(_NormalPBRMap0, sampler_NormalPBRMap0, uv);
                normalRASamples[1] = SAMPLE_TEXTURE2D(_NormalPBRMap1, sampler_NormalPBRMap0, uv);
                normalRASamples[2] = SAMPLE_TEXTURE2D(_NormalPBRMap2, sampler_NormalPBRMap0, uv);
                normalRASamples[3] = SAMPLE_TEXTURE2D(_NormalPBRMap3, sampler_NormalPBRMap0, uv);

                albedo = 0;
                //高度混合
                #if defined(EnableHeightBlend)

                    half4 blend = 0;
                    blend.r = albedos[0].a;
                    blend.g = albedos[1].a;
                    blend.b = albedos[2].a;
                    blend.a = albedos[3].a;
                    half ma = max(blend.r, max(blend.g, max(blend.b, blend.a)));
                    blend = max(blend - ma + _Weight, 0) * splatControl;
                    blend = blend / (blend.r + blend.g + blend.b + blend.a);

                    albedo = albedos[0] * blend.r;
                    albedo += albedos[1] * blend.g;
                    albedo += albedos[2] * blend.b;
                    albedo += albedos[3] * blend.a;
                    
                #else
                    albedo = albedos[0] * splatControl.r ;
                    albedo += albedos[1] * splatControl.g ;
                    albedo += albedos[2] * splatControl.b ;
                    albedo += albedos[3] * splatControl.a ;
                #endif
                // albedo = saturate(albedo);

                half2 normalSample = 0;
                normalSample = normalRASamples[0].rg * splatControl.r;
                normalSample += normalRASamples[1].rg * splatControl.g;
                normalSample += normalRASamples[2].rg * splatControl.b;
                normalSample += normalRASamples[3].rg * splatControl.a;
                normalSample = normalSample * 2 - 1;

                NormalReconstructZ(normalSample, normalTS);

                roughness = 0;
                roughness = normalRASamples[0].b * splatControl.r;
                roughness += normalRASamples[1].b * splatControl.g;
                roughness += normalRASamples[2].b * splatControl.b;
                roughness += normalRASamples[3].b * splatControl.a;
                roughness = saturate(roughness);

                occlusion = 0;
                occlusion = normalRASamples[0].a * splatControl.r;
                occlusion += normalRASamples[1].a * splatControl.g;
                occlusion += normalRASamples[2].a * splatControl.b;
                occlusion += normalRASamples[3].a * splatControl.a;
                occlusion = saturate(occlusion);
            }

            half4 hash4(half2 p)
            {
                return frac(sin(half4(1.0 + dot(p, half2(37.0, 17.0)),
                2.0 + dot(p, half2(11.0, 47.0)),
                3.0 + dot(p, half2(41.0, 29.0)),
                4.0 + dot(p, half2(23.0, 31.0)))) * 103.0);
            }

            ///////////////////////////////////////////////////////////////////////////////
            //                  Vertex and Fragment functions                            //
            ///////////////////////////////////////////////////////////////////////////////
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.tangentWS = input.tangentOS;
                output.uv = input.uv;
                output.fogFactor = ComputeFogFactor(output.positionCS.z);

                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = input.uv;
                float3 normalWS = normalize(input.normalWS);
                // return float4(normalWS, 1);
                half4 var_Control = SAMPLE_TEXTURE2D(_Control, sampler_Control, uv);

                float2 uv_Top = (input.positionWS.xz * _UVScale);
                // generate per-tile transform

                // uv_Top = frac(uv_Top);
                // return half4(uv_Top, 0, 1);
                // half4 ofa = hash4(uv_Top);
                // return ofa;
                // ofa.zw = sign(ofa.zw - 0.5);
                // uv_Top = uv_Top * ofa.zw + ofa.xy;
                // return SAMPLE_TEXTURE2D(_UVMap, sampler_UVMap, uv_Top);
                // return ofa;
                // return half4(uv_Top, 0, 1);

                half3 albedo = 0;
                half roughness = 0;
                half occlusion = 1;
                half3 normalTS = 0;
                half metallic = 0;
                //ANTI Tilling 视距混合法
                #if defined(EnableAntiTilling)
                    float viewDistance = distance(input.positionWS, _WorldSpaceCameraPos);
                    float fade1 = viewDistance / _FadeDistance.x;
                    float fade2 = viewDistance / _FadeDistance.y;
                    //   float fade1 = viewDistance / _FadeDistance.r;
                    float clampDistance = clamp(fade1, 0, 1);
                    float clampDistance2 = clamp(fade2, 0, 1);
                    half3 albedo1, albedo2, albedo3;
                    half roughness1 = 0, roughness2 = 0, roughness3 = 0;
                    half3 normalTS1 = 0, normalTS2 = 0, normalTS3 = 0;
                    SplatmapMix(uv_Top, var_Control, albedo1, roughness1, occlusion, normalTS1);
                    SplatmapMix(uv_Top / 4, var_Control, albedo2, roughness2, occlusion, normalTS2);
                    SplatmapMix(uv_Top / 8, var_Control, albedo3, roughness3, occlusion, normalTS3);
                    
                    // return lerp(color1, color2, clampDistance);
                    albedo = lerp(lerp(albedo1, albedo2, clampDistance), albedo3, clampDistance2);
                    roughness = lerp(lerp(roughness1, roughness2, clampDistance), roughness3, clampDistance2);
                    normalTS = lerp(lerp(normalTS1, normalTS2, clampDistance), normalTS3, clampDistance2);
                #else
                    
                    SplatmapMix(uv_Top, var_Control, albedo, roughness, occlusion, normalTS);
                #endif
                
                half3 bitangentWS = (cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w);
                half3x3 TBN = float3x3(input.tangentWS.xyz, bitangentWS, normalWS);
                normalWS = (TransformTangentToWorld(normalTS, TBN));

                roughness = _RoughnessScale * roughness;
                occlusion = _OcclusionScale * occlusion;
                // return half4(albedo, 1);
                HMKSurfaceData surfaceData = InitSurfaceData(albedo, 1, metallic, roughness, occlusion);
                HMKLightingData lightingData = InitLightingData(input.positionWS, normalWS);
                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                finalRGB = MixFog(finalRGB, input.fogFactor);
                return float4(finalRGB, surfaceData.alpha);
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
            Cull off // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

            HLSLPROGRAM

            // #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "./../Base/HMK_Lit_Input.hlsl"
            #include "./../Base/HMK_ShadowCasterPass.hlsl"

            ENDHLSL

        }



        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM

            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
            ENDHLSL

        }
    }

    
    FallBack "Diffuse"
    CustomEditor "HMKTerrainShaderGUI"
}
