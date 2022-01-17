Shader "HMK/Terrain/Terrain_SplatMega"
{
    Properties
    {
        _Control ("Control (RGBA)", 2D) = "white" { }
        _SplatArray ("SplatArray", 2DArray) = "white" { }
        _NormalArray ("NormalArray", 2DArray) = "white" { }
        _PBRArray ("PBRArray", 2DArray) = "while" { }
        
        _Weight ("Blend Weight", Range(0.001, 1)) = 0.2
        _UVScale ("贴图 UVScale", Range(0.001, 1)) = 0.2
        _CliffBlend ("Cliff Blend", Range(0, 1)) = 0.2

        // [Toggle]_CliffRender ("三向峭壁渲染", float) = 0

        [Toggle(HeightBlend)]_HeightBlend ("开启高度混合", float) = 0
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
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            //--------------------------------------
            // Shader Feature
            #pragma shader_feature _ HeightBlend

            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
            float _Weight;
            float _UVScale;
            float _CliffBlend;
            // float _CliffRender;
            CBUFFER_END
            
            TEXTURE2D(_Control);SAMPLER(sampler_Control);half4 _Control_TexelSize;
            TEXTURE2D_ARRAY(_SplatArray);SAMPLER(sampler_SplatArray);
            TEXTURE2D_ARRAY(_NormalArray);SAMPLER(sampler_NormalArray);
            TEXTURE2D_ARRAY(_PBRArray);SAMPLER(sampler_PBRArray);

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
                // float blendWeight: TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            void SplatmapMix(float2 uv, int index1, int index2, float weight, inout half3 albedo, inout half metallic, inout half roughness, inout half occlusion, inout half3 normalTS, inout half4 blend)
            {
                // index1 = 2.5;
                // index2 = 2.5;
                half4 albedos[2];
                
                albedos[0] = SAMPLE_TEXTURE2D_ARRAY(_SplatArray, sampler_SplatArray, uv, index1);
                albedos[1] = SAMPLE_TEXTURE2D_ARRAY(_SplatArray, sampler_SplatArray, uv, index2);

                half4 normalSamples[2];
                normalSamples[0] = SAMPLE_TEXTURE2D_ARRAY(_NormalArray, sampler_NormalArray, uv, index1);
                normalSamples[1] = SAMPLE_TEXTURE2D_ARRAY(_NormalArray, sampler_NormalArray, uv, index2);

                half4 pbrSamples[2];
                pbrSamples[0] = SAMPLE_TEXTURE2D_ARRAY(_PBRArray, sampler_PBRArray, uv, index1);
                pbrSamples[1] = SAMPLE_TEXTURE2D_ARRAY(_PBRArray, sampler_PBRArray, uv, index2);

                albedo = 0;
                #if defined(HeightBlend)

                    blend = 0;
                    blend.r = albedos[0].a;
                    blend.g = albedos[1].a;
                    half ma = max(blend.r, blend.g);
                    blend = max(blend - ma + _Weight, 0) * weight ;
                    blend = blend / (blend.r + blend.g);

                    albedo = albedos[0] * blend.r;
                    albedo += albedos[1] * blend.g;
                    
                #else
                    
                    albedo = lerp(albedos[0], albedos[1], weight);
                #endif

                // albedo = albedos[0];// * blend.r;//blend.a * splatControl.a;
                

                half4 normalSample = 0;
                normalSample = normalSamples[0] * weight;
                normalSample += normalSamples[1] * (1 - weight);
                
                normalTS = UnpackNormal(normalSample); //normalSample;

                metallic = 0;
                metallic = pbrSamples[0].r * weight;
                metallic += pbrSamples[1].r * (1 - weight);
                metallic = 0;

                roughness = 0;
                roughness = pbrSamples[0].g * weight;
                roughness += pbrSamples[1].g * (1 - weight);
                roughness = 0.2;

                occlusion = 0;
                occlusion = pbrSamples[0].b * weight;
                occlusion += pbrSamples[1].b * (1 - weight);
                occlusion = 0;
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
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.tangentWS = input.tangentOS;
                output.uv = input.uv;
                // half4 var_Control = tex2Dlod(_Control, float4(output.uv));
                // output.blendWeight = var_Control.b;
                return output;
            }

            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = input.uv;
                float3 normalWS = normalize(input.normalWS);
                // return float4(uv, 0, 1);

                float2 uv_Top = (input.positionWS.xz * _UVScale);

                half3 albedo = 0;
                half metallic = 0;
                half roughness = 0;
                half occlusion = 1;
                half3 normalTS = 0;
                half4 blend = 0;

                
                half3 var_Control = SAMPLE_TEXTURE2D(_Control, sampler_Control, uv);
                int val_Index1 = var_Control.r * 255;
                int val_Index2 = var_Control.g * 255;
                // return var_Control.r - var_Control.g;
                float weight = var_Control.b;
                SplatmapMix(uv_Top, val_Index1, val_Index2, weight, albedo, metallic, roughness, occlusion, normalTS, blend);
                // return half4(blend);
                // return half4(normalTS, 1);
                half3 bitangentWS = cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w;
                half3x3 TBN = float3x3(input.tangentWS.xyz, bitangentWS, normalWS);
                normalWS = TransformTangentToWorld(normalTS, TBN);
                // return half4(normalWS, 1);

                //ANTI Tilling
                //高度混合
                

                HMKSurfaceData surfaceData = InitSurfaceData(albedo, 1, metallic, roughness, occlusion);
                // return half4(surfaceData.albedo, 1);
                HMKLightingData lightingData = InitLightingData(input.positionWS, normalWS);

                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                
                
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
            Cull Back // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

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
}
