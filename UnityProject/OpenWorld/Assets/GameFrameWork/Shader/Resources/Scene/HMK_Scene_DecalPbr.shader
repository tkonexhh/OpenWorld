

Shader "HMK/Scene/DecalPBR"
{
    Properties
    {
        [Header(Option)]
        // [Toggle(_ALPHATEST_ON)] _AlphaClip ("__clip", Float) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)]  _Cull ("__Cull", float) = 2.0


        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Header(Base Color)]
        [MainColor]_BaseColor ("固有色", color) = (1, 1, 1, 1)
        [NoScaleOffset] _BaseMap ("BaseMap", 2D) = "white" { }
        [NoScaleOffset]_NormalPBRMap ("RG:法线 B:粗糙度 A:AO", 2D) = "bump" { }
        _BumpScale ("Bump Scale", range(0, 3)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 3)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 3)) = 1
        _Opacity ("Opacity", range(0, 1)) = 1
        [Header(WaterPuddle)]
        [Space(8)]
        [Toggle(UsePuddle)]UsePuddle ("UsePuddle", Float) = 0
        [NoScaleOffset]_HeightMap ("Heightmap", 2D) = "White" { }
        [NoScaleOffset]_WaterNormal ("WaterNormal", 2D) = "White" { }
        _WaterHeight ("WaterHeight", range(-1, 1)) = 0
        _PuddleOpacity ("PuddleOpacity", range(0, 1)) = 0

        [Header(Stencil)]
        [Space(8)]
        [IntRange] _StencilRef ("Stencil Reference", Range(0, 255)) = 0
        [IntRange] _ReadMask ("     Read Mask", Range(0, 255)) = 255
        [IntRange] _WriteMask ("     Write Mask", Range(0, 255)) = 255
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Transparent+2" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            Stencil
            {
                Ref  [_StencilRef]
                ReadMask [_ReadMask]
                WriteMask [_WriteMask]
                Comp Equal //[_StencilCompare]

            }

            ZWrite On
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest Always
            Cull   [_Cull]
            HLSLPROGRAM

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords

            #pragma multi_compile_fog
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature UsePuddle
            #pragma vertex vert
            #pragma fragment frag


            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Normal.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _BumpScale;
            half _MetallicScale, _RoughnessScale, _OcclusionScale, _EmissionScale;
            half _Cutoff;
            half3 _EmissionColor;
            half _WindSpeed;
            half _WindIntensity;
            half _PixelRange;
            half _WaterHeight;
            half _PuddleOpacity;
            half _Opacity;
            CBUFFER_END

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalPBRMap);SAMPLER(sampler_NormalPBRMap);
            TEXTURE2D(_HeightMap);SAMPLER(sampler_HeightMap);
            TEXTURE2D(_WaterNormal);SAMPLER(sampler_WaterNormal);

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;

                half3 normalOS: NORMAL;
                half4 tangentOS: TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD0;

                half3 normalWS: NORMAL;
                half3 tangentWS: TEXCOORD3;
                half3 bitangentWS: TEXCOORD4;
                half fogFactor: TEXCOORD5;
                half3 ray: TEXCOORD6;
                float4 screenPos: TEXCOORD7;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            HMKLightingData InitLightingData(Varyings input, float2 normalXY)
            {
                //采样法线贴图
                float3 normalTS;
                NormalReconstructZ(normalXY, normalTS);

                // half3 normalTS = UnpackNormalScale(var_NormalMap, _BumpScale);
                half3x3 TBN = float3x3(float3(1, 0, 0), float3(0, 0, 1), float3(0, 1, 0));
                float3 normalWS = TransformTangentToWorld(normalTS, TBN) ;

                return InitLightingData(input.positionWS, normalWS);
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                output.screenPos = ComputeScreenPos(output.positionCS);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = input.uv;
                float3 normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));
                float3 tangentWS = TransformObjectToWorldDir(input.tangentOS);
                half tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
                float3 bitangentWS = cross(normalWS, tangentWS) * tangentSign;
                half fogFactor = ComputeFogFactor(output.positionCS.z);


                output.ray = TransformWorldToView(TransformObjectToWorld(input.positionOS)).xyz * float3(-1, -1, 1);


                output.normalWS = normalWS;
                output.tangentWS = tangentWS;
                output.bitangentWS = bitangentWS;
                output.fogFactor = fogFactor;


                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                input.ray = input.ray * (_ProjectionParams.z / input.ray.z);

                float2 screenUV = input.screenPos.xy / input.screenPos.w;


                float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                float sceneZLinear = LinearEyeDepth(sceneZ, _ZBufferParams);
                half diffZ = (sceneZLinear - ComputeScreenPos(TransformWorldToHClip(input.positionWS).w)) ;
                diffZ = smoothstep(0.9, 1, diffZ);

                float depth = Linear01Depth(sceneZ, _ZBufferParams);

                float4 vpos = float4(input.ray * depth, 1);


                float3 wpos = mul(unity_CameraToWorld, vpos).xyz;



                // // float3 opos = mul(unity_WorldToObject, float4(wpos, 1)).xyz;

                float3 opos = mul(UNITY_MATRIX_I_M, float4(wpos, 1)).xyz;

                clip(float3(0.5, 0.5, 0.5) - abs(opos.xyz)) ;




                float2 texUV = opos.xz + 0.5;



                float2 uv = input.uv;


                #ifdef UsePuddle
                    half4 var_HeightMap = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, texUV);
                    half4 var_WaterNorml = SAMPLE_TEXTURE2D(_WaterNormal, sampler_WaterNormal, texUV);
                    half puddleHeight = saturate(var_HeightMap.r - _WaterHeight);

                #endif


                half4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, texUV);
                half4 var_NormalPBRMap = SAMPLE_TEXTURE2D(_NormalPBRMap, sampler_NormalPBRMap, texUV);



                float2 normalXY = (var_NormalPBRMap.rg);





                float roughness = var_NormalPBRMap.b;

                float occlusion = var_NormalPBRMap.a;

                HMKSurfaceData surfaceData;

                surfaceData.albedo = var_BaseMap.rgb;

                surfaceData.alpha = var_BaseMap.a * _Opacity;
                surfaceData.metallic = 0 ;
                surfaceData.occlusion = LerpWhiteTo(occlusion, _OcclusionScale);
                surfaceData.roughness = roughness * _RoughnessScale;
                surfaceData.emission = 0;



                #ifdef UsePuddle
                    normalXY = lerp(var_WaterNorml.rg, normalXY, puddleHeight);
                    half3 PuddleColor = lerp(var_BaseMap.rgb, _BaseColor.rgb, _PuddleOpacity);
                    surfaceData.albedo = lerp(PuddleColor, var_BaseMap.rgb, puddleHeight);
                    roughness = lerp(0, roughness, puddleHeight);
                    surfaceData.roughness = lerp(0, roughness * _RoughnessScale, puddleHeight) ;
                #endif


                normalXY = normalXY * 2 - 1;



                clip(surfaceData.alpha - _Cutoff);



                HMKLightingData lightingData = InitLightingData(input, normalXY);

                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                finalRGB = MixFog(finalRGB, input.fogFactor);
                return half4(finalRGB, surfaceData.alpha);
            }

            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
