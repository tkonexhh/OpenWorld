Shader "HMK/Scene/BlendTerrain"
{
    Properties
    {
        // [Toggle(_GIMAP_ON)]_GIMAP_ON ("_GIMAP_ON", Float) = 0.0
        // _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Header(Base Properties)]
        [MainColor]_BaseColor ("ColorTint", color) = (1, 1, 1, 1)
        [NoScaleOffset] _BaseMap ("BaseMap", 2D) = "white" { }
        // [NoScaleOffset] _PBRMap ("MRA", 2D) = "white" { }
        [NoScaleOffset]_NormalPBRMap ("RG:法线 B:粗糙度 A:AO", 2D) = "bump" { }
        _MetallicScale ("MetallicScale", range(0, 1)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 4)) = 3
        _OcclusionScale ("OcclusionScale", range(0, 1)) = 1
        [Header(VertexBlend Properties)]
        [Toggle(UseVertexBlend)] UseVertexBlend ("UseVertexBlend", Float) = 0
        [Toggle(UseAlphaMask)] UseAlphaMask ("UseAlphaMask", Float) = 0
        _BlendRangeMin ("BlendRangeMin", range(0, 1)) = 0
        _BlendRangeMax ("BlendRangeMax", range(0, 1)) = 1
        _BlendMapTiling ("BlendMapTiling", range(0.001, 1)) = 1
        //_BlendMapTiling ("BlendMapTiling", range(0, 20)) = 1
        // _BlendNoiseTiling ("BlendNoiseTiling", range(0, 100)) = 1
        // [NoScaleOffset]_BlendNoise ("BlendNoise", 2D) = "white" { }
        [NoScaleOffset]_BlendColorMap ("BlendBaseMap", 2D) = "white" { }
        [NoScaleOffset]_BlendNormalMap ("BlendNormalPRBMap", 2D) = "bump" { }
        // _BlendColor ("BlendColorTint", color) = (1, 1, 1, 1)
        // _Saturation ("Saturation", float) = 0.79
        // _BlendMapInt ("BlendMapInt", range(0, 2)) = 1
        _BumpScale ("BumpScale", range(0, 10)) = 1.0
        _TerrainHeightNormal_TexelSize ("TerrainHeightNormal_TexelSize", vector) = (0, 0, 0, 0)

        [Header(TerrianBlend Properties)]
        [Toggle(UseBlend)] UseBlend ("UseBlend", Float) = 0
        [NoScaleOffset] _TerrainHeightNormal ("Terrain Height Normal", 2D) = "white" { }
        _Shift ("DepthShift", range(0, 1)) = 0.2
        _AlphaShift ("Alpha Shift", Range(-5, 5)) = 0
        _AlphaWidth ("Alpha Contraction", Range(1, 10)) = 4
        _TerrainSize ("TerrainSize", vector) = (1, 1, 1, 1)
        _TerrainPos ("TerrainPos", vector) = (0, 0, 0, 0)
        _ShadowOffset ("ShadowOffset", vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry+2" }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite on
            Cull Back

            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            //#pragma multi_compile  _GIMAP_ON
            #pragma shader_feature UseVertexBlend
            #pragma shader_feature UseBlend
            #pragma shader_feature UseAlphaMask
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma vertex vert
            #pragma fragment frag


            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Normal.hlsl"


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
                half fogFactor: TEXCOORD5;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)

            half4 _ShadowOffset;
            float4 _TerrainSize, _TerrainPos;
            half4 _TerrainHeightNormal_TexelSize;

            half4 _BaseColor, _BlendDepthColor, _BlendColor;
            half _MetallicScale, _RoughnessScale, _OcclusionScale, _Saturation, _BlendMapInt, _Shift;
            float _BlendRangeMin, _BlendRangeMax, _BlendMapTiling, _BumpScale, _AlphaShift, _AlphaWidth ;

            CBUFFER_END
            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            // sampler2D _PBRMap;
            TEXTURE2D(_NormalPBRMap);SAMPLER(sampler_NormalPBRMap);
            sampler2D _MetallicMap;
            sampler2D _RoughnessMap;

            sampler2D _BlendNormalMap;
            sampler2D _BlendColorMap;
            TEXTURE2D(_TerrainHeightNormal); SAMPLER(sampler_TerrainHeightNormal);


            float DecodeFloatRG(float2 enc)
            {
                float2 kDecodeDot = float2(1.0 / 255, 1.0);
                return dot(enc, kDecodeDot);
            }
            //DepthCaculate
            float2 BlendMask(half3 positionWS, half3 normalWS, half2 uv)
            {
                float Wop = 0;
                //vertex mask



                #if UseVertexBlend
                    Wop = NormalizeNormalPerPixel(normalWS).g;
                    Wop = saturate(smoothstep(_BlendRangeMin, _BlendRangeMax, Wop));

                #endif
                // half BlendNoiseMap = tex2D(_BlendNoise, uv * _BlendNoiseTiling).r;
                // Wop = clamp(((Wop - 0.5) * (clamp(BlendNoiseMap, 0.05, 1)) + Wop), 0, 1);
                #if UseBlend
                    //Depth mask
                    float2 terrainUV = (positionWS.xz - _TerrainPos.xz) / _TerrainSize.xz;
                    // float2 terrainUV = (positionWS.xz) / float2(500.0, 500.0) ;//_TerrainSize.xz;
                    terrainUV = (terrainUV * (_TerrainHeightNormal_TexelSize.zw - 1.0f) + 0.5) * _TerrainHeightNormal_TexelSize.xy;
                    // terrainUV = (terrainUV * (float2(513.0, 513.0) - 1.0f) + 0.5) * float2(1.0 / 513.0, 1.0 / 513.0);

                    float4 terrainSample = SAMPLE_TEXTURE2D_LOD(_TerrainHeightNormal, sampler_TerrainHeightNormal, terrainUV * float2(1, 1), 0);
                    float terrainHeight = DecodeFloatRG(terrainSample.rg) * _TerrainSize.y + _TerrainPos.y;
                    // float terrainHeight = terrainSample.r * _TerrainSize.y + _TerrainPos.y;
                    float HeightMask = smoothstep(0.0h, 1.0h, 1.0h - saturate((terrainHeight - positionWS.y + _AlphaShift) * _AlphaWidth));

                    return float2(HeightMask, Wop);
                #endif

                return float2(1, Wop);
            }

            half4 GetFinalBaseColor(Varyings input)
            {

                half4 Albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor ;

                half4 FinalColor = Albedo;
                return FinalColor ;
            }



            HMKLightingData InitLightingData(Varyings input, float2 normalXY)
            {

                float3 normalTS;
                NormalReconstructZ(normalXY, normalTS);


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
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = input.uv;
                output.normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));
                float3 tangentWS = TransformObjectToWorldDir(input.tangentOS);
                half tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
                float3 bitangentWS = cross(output.normalWS, tangentWS) * tangentSign;
                half fogFactor = ComputeFogFactor(output.positionCS.z);

                output.tangentWS = tangentWS;
                output.bitangentWS = bitangentWS;
                output.fogFactor = fogFactor;
                #if UseBlend
                    float fac = _ProjectionParams.y * 10;
                    #if UNITY_REVERSED_Z
                        output.positionCS.z += _Shift / max(_ProjectionParams.y, output.positionCS.w) * fac;
                    #else
                        output.positionCS.z -= _Shift / max(_ProjectionParams.y, output.positionCS.w) * fac;

                    #endif
                #endif

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                float2 uv = input.uv;
                half4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
                half4 var_NormalPBRMap = SAMPLE_TEXTURE2D(_NormalPBRMap, sampler_NormalPBRMap, uv);
                float2 BlendMaskGet = BlendMask(input.positionWS, input.normalWS, input.uv);


                float2 uv_Top = input.positionWS.xy * _BlendMapTiling;
                float2 uv_Left = input.positionWS.yz * _BlendMapTiling;
                float2 uv_Right = input.positionWS.xz * _BlendMapTiling;
                //混合材质顶层法线计算
                half4 VertexBlendNRATop = tex2D(_BlendNormalMap, uv_Top);
                half4 VertexBlendNRALeft = tex2D(_BlendNormalMap, uv_Left);
                half4 VertexBlendNRARight = tex2D(_BlendNormalMap, uv_Right);
                half4 blend1 = lerp(VertexBlendNRALeft, VertexBlendNRATop, abs(input.normalWS.z));
                blend1 = lerp(blend1, VertexBlendNRARight, abs(input.normalWS.y));


                float blendMaskGetG = saturate(BlendMaskGet.g * 2.2);
                float2 normalBlend = blendMaskGetG * blend1.rg + (1 - blendMaskGetG) * var_NormalPBRMap.rg ;

                float2 normalXY = normalBlend ;


                normalXY = normalXY * 2 - 1;
                float roughness = var_NormalPBRMap.b;
                float occlusion = var_NormalPBRMap.a;
                float4 finalBaseColor = GetFinalBaseColor(input);

                HMKSurfaceData surfaceData;
                surfaceData.roughness = saturate(((1 - blendMaskGetG) * roughness + blendMaskGetG * blend1.b) * _RoughnessScale);
                surfaceData.occlusion = ((1 - blendMaskGetG) * occlusion + blendMaskGetG * blend1.a) * _OcclusionScale;

                //混合材质顶层颜色计算
                half4 VertexBlendColor4 = tex2D(_BlendColorMap, uv_Top);
                half4 VertexBlendColor5 = tex2D(_BlendColorMap, uv_Left);
                half4 VertexBlendColor6 = tex2D(_BlendColorMap, uv_Right);

                half4 blend2 = lerp(VertexBlendColor5, VertexBlendColor4, abs(input.normalWS.z));
                blend2 = lerp(blend2, VertexBlendColor6, saturate(abs(input.normalWS.y)));
                // surfaceData.albedo = saturate(1 - min(blendMaskGetG, finalBaseColor.a)) * finalBaseColor + saturate(min(blendMaskGetG, finalBaseColor.a)) * blend2;//  * _Saturation * blend1.a;

                surfaceData.albedo = lerp(finalBaseColor, blend2, min(blendMaskGetG, finalBaseColor.a));
                #ifdef UseAlphaMask
                    surfaceData.albedo = finalBaseColor.a * blend2 + saturate(1 - finalBaseColor.a) * var_BaseMap;

                    surfaceData.roughness = saturate(((1 - finalBaseColor.a) * roughness + finalBaseColor.a * blend1.b) * _RoughnessScale);
                    surfaceData.occlusion = saturate(((1 - finalBaseColor.a) * occlusion + finalBaseColor.a * blend1.a) * _OcclusionScale);

                #endif

                surfaceData.alpha = 1;
                surfaceData.metallic = _MetallicScale;


                HMKLightingData lightingData = InitLightingData(input, normalXY);

                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                finalRGB = saturate(MixFog(finalRGB, input.fogFactor));

                finalRGB = saturate(finalRGB);

                // return float4(blend2.rgb, 1);
                return half4(finalRGB, BlendMaskGet.r);
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
            Cull back
            // Cull[_Cull] // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            // #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Shadow.hlsl"

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment



            struct Attributes
            {
                float4 positionOS: POSITION;
                float3 normalOS: NORMAL;
                float2 texcoord: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float4 positionCS: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            CBUFFER_START(UnityPerMaterial)

            half4 _ShadowOffset;
            half4 _TerrainSize, _TerrainPos;

            half4 _BaseColor, _BlendDepthColor, _BlendColor;
            half _MetallicScale, _RoughnessScale, _OcclusionScale, _Saturation, _BlendMapInt, _Shift;
            half _BlendRangeMin, _BlendRangeMax, _BlendMapTiling, _BumpScale, _AlphaShift, _AlphaWidth ;

            CBUFFER_END
            float4 GetShadowPositionHClip1(Attributes input)
            {
                Light mainlight = GetMainLight();
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, mainlight.direction));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_aVALUE);

                #endif
                float camLength = length(_WorldSpaceCameraPos - TransformObjectToWorld(input.positionOS));
                camLength = lerp(0.05, 0, (saturate(camLength * 0.1))) ;
                return positionCS + float4(0, 0, 0, camLength) ;
            }


            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);

                output.uv = input.texcoord;
                output.positionCS = GetShadowPositionHClip(input.positionOS, input.normalOS) + _ShadowOffset;
                return output;
            }

            half4 ShadowPassFragment(Varyings input): SV_TARGET
            {
                // #if defined(_ALPHATEST_ON)
                //     half4 var_Base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                //     half alpha = var_Base.a;
                //     clip(alpha - _Cutoff);
                // #endif

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
            Cull back

            HLSLPROGRAM

            #pragma target 4.5
            #pragma shader_feature UseBlend
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // #ifndef UNIVERSAL_DEPTH_ONLY_PASS_INCLUDED
            //     #define UNIVERSAL_DEPTH_ONLY_PASS_INCLUDED


            struct Attributes
            {
                float4 position: POSITION;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float4 positionCS: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            CBUFFER_START(UnityPerMaterial)

            half4 _ShadowOffset;
            half4 _TerrainSize, _TerrainPos;
            half4 _BaseColor, _BlendDepthColor, _BlendColor;
            half _MetallicScale, _RoughnessScale, _OcclusionScale, _Saturation, _BlendMapInt, _Shift;
            half _BlendRangeMin, _BlendRangeMax, _BlendMapTiling, _BumpScale, _AlphaShift, _AlphaWidth;

            CBUFFER_END


            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                #if UseBlend
                    float fac = _ProjectionParams.y * 10;
                    #if UNITY_REVERSED_Z
                        output.positionCS.z += _Shift / max(_ProjectionParams.y, output.positionCS.w) * fac;
                    #else
                        output.positionCS.z -= _Shift / max(_ProjectionParams.y, output.positionCS.w) * fac;

                    #endif
                #endif
                output.uv = input.uv;//TRANSFORM_TEX(input.texcoord, _BaseMap);

                return output;
            }

            half4 DepthOnlyFragment(Varyings input): SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                return 0;
            }

            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
