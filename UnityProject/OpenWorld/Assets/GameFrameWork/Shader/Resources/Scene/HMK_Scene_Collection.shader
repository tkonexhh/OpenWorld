

Shader "HMK/Scene/Collection"
{
    Properties
    {
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Header(Base Color)]
        [MainColor]_BaseColor ("固有色", color) = (1, 1, 1, 1)

        [HDR]_MaskColorTint ("MaskColorTint", color) = (1, 1, 1, 1)
        [NoScaleOffset] _BaseMap ("BaseMap", 2D) = "white" { }
        [NoScaleOffset] _PBRMap ("PBR贴图 R:金属度 G:粗糙度 B:AO  A:Emission", 2D) = "white" { }
        [NORMAL] [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" { }

        _BumpScale ("Bump Scale", range(0, 3)) = 1
        [NoScaleOffset]_NoiseMap ("溶解贴图", 2D) = "white" { }
        _DissolveOpacity ("DissolveOpacity", Range(-0.1, 1)) = 1
        [HDR]_DissolveColor ("DissolveColor", color) = (1, 1, 1, 1)
        _NoiseTiling ("NoiseTiling", range(0, 2)) = 1
        _MetallicScale ("MetallicScale", range(0, 1)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 1)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 1)) = 1

        [Header(Emission)]
        _EmissionScale ("Emission Scale", range(0, 3)) = 0
        [HDR] _EmissionColor ("Emission Color", color) = (1, 1, 1)



        [IntRange] _UseRelection ("Use Reflection", range(0, 1)) = 0
        _CubeMap ("Cubemap", Cube) = "white" { }
        _RefractTiling ("RefractTiling", range(0, 10)) = 1
        _RefractInt ("RefractInt", range(0, 10)) = 1
        [HDR]_fresnelColor ("fresnelColor", color) = (1, 1, 1, 1)
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

        //GI state
        [HideInInspector] _GIMap ("__giMap", Float) = 0.0
    }




    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)
    half4 _BaseColor, _DissolveColor, _MaskColorTint;
    half _BumpScale;
    half _MetallicScale, _RoughnessScale, _OcclusionScale, _EmissionScale, _DissolveOpacity, _NoiseTiling;
    half _Cutoff;
    half3 _EmissionColor;
    half4 _fresnelColor;
    half _UseRelection;
    half _RefractInt, _RefractTiling;
    CBUFFER_END

    TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
    TEXTURE2D(_PBRMap);SAMPLER(sampler_PBRMap);
    TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
    TEXTURE2D(_NoiseMap);SAMPLER(sampler_NoiseMap);
    TEXTURECUBE(_CubeMap);SAMPLER(sampler_CubeMap);


    ENDHLSL

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
            #pragma multi_complie  _GIMAP_ON
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
            #pragma multi_compile_fog
            // #pragma shader_feature _FOG_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag
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
                half fogFactor: TEXCOORD5;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };





            half4 GetFinalBaseColor(Varyings input)
            {
                return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) ;
            }


            HMKSurfaceData InitSurfaceData(Varyings input)
            {
                half4 mra = SAMPLE_TEXTURE2D(_PBRMap, sampler_PBRMap, input.uv);// tex2D(pbrMap, input.uv).rgb;
                float4 finalBaseColor = GetFinalBaseColor(input);

                half3 albedo = finalBaseColor.rgb * _BaseColor;




                half alpha = finalBaseColor.a;
                #if defined(_PBRMAP_ON)
                    half metallic = mra.r * _MetallicScale;
                    half roughness = mra.g * _RoughnessScale;
                    half occlusion = LerpWhiteTo(mra.b, _OcclusionScale);
                    half3 emission = mra.a * _EmissionScale * _EmissionColor;
                #else
                    half metallic = _MetallicScale;
                    half roughness = _RoughnessScale;
                    half occlusion = _OcclusionScale;
                    half3 emission = 0;
                #endif

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
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = input.uv;
                float3 normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));
                float3 tangentWS = TransformObjectToWorldDir(input.tangentOS);
                half tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
                float3 bitangentWS = cross(normalWS, tangentWS) * tangentSign;
                half fogFactor = ComputeFogFactor(output.positionCS.z);

                output.normalWS = normalWS;
                output.tangentWS = tangentWS;
                output.bitangentWS = bitangentWS;
                output.fogFactor = fogFactor;

                #if defined(LIGHTMAP_ON)
                    HMK_OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                #endif
                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                HMKSurfaceData surfaceData = InitSurfaceData(input);
                HMKLightingData lightingData = InitLightingData(input);
                Light mainLight = GetMainLight();
                mainLight.color.rgb = clamp(mainLight.color.rgb, 0.8, 1.2);
                #if defined(_ALPHATEST_ON)
                    clip(surfaceData.alpha - _Cutoff);
                #endif

                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);



                float3 worldViewDir = normalize((_WorldSpaceCameraPos.xyz - input.positionWS));

                half3 MainTex = finalRGB;




                finalRGB = surfaceData.alpha * finalRGB + (1 - surfaceData.alpha) * (surfaceData.albedo.rgb) * _MaskColorTint.rgb * mainLight.color;


                if (_UseRelection != 0)
                {
                    half3 normal = lightingData.normalWS;
                    half noise = SAMPLE_TEXTURE2D(_PBRMap, sampler_PBRMap, input.uv * _RefractTiling).r;
                    // half3 RefractColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) ;
                    // return float4(surfaceData.albedo.rgb, 1);
                    // return noise;
                    float3 normalVector = lightingData.normalWS;
                    float3 worldReflection = reflect(-worldViewDir, normalize(lightingData.normalWS));

                    float4 reflectionColor = SAMPLE_TEXTURECUBE(_CubeMap, sampler_CubeMap, worldReflection + float3(noise * _RefractInt, 0, 0))  ;


                    reflectionColor.rgb = (1 - surfaceData.alpha) * reflectionColor.rgb * surfaceData.albedo.rgb * _EmissionColor + (surfaceData.alpha) * MainTex;


                    half3 finalcolor = reflectionColor.rgb ;//lerp(surfaceData.albedo, reflectionColor.rgb, 0.5) ;


                    half fresnel = saturate(pow(dot(worldViewDir, lightingData.normalWS), 3) * 2);

                    // finalRGB = lerp(finalcolor * _EmissionColor, reflectionColor, fresnel) ;

                    // finalRGB = surfaceData.alpha * finalRGB + (1 - surfaceData.alpha) * finalRGB * _MaskColorTint.rgb * mainLight.color;
                    finalRGB = lerp(finalcolor, _fresnelColor.rgb * finalcolor, fresnel) ;
                }





                float4 dissolveMap = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, input.uv * _NoiseTiling);


                float dissolveColor = lerp(1, 0, step(dissolveMap.r, (0.98 - _DissolveOpacity)));


                finalRGB = dissolveColor * finalRGB + (1 - dissolveColor) * _DissolveColor.rgb;

                clip(dissolveMap.r - (0.93 - _DissolveOpacity));

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


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Shadow.hlsl"


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


            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);

                output.uv = input.texcoord;//TRANSFORM_TEX(input.texcoord, _BaseMap);
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
                float4 dissolveMap = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, input.uv * _NoiseTiling);


                float dissolveColor = lerp(1, 0, step(dissolveMap.r, (0.98 - _DissolveOpacity)));



                clip(dissolveColor - (0.95 - _DissolveOpacity));

                // Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
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

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            #include "./../Base/HMK_DepthOnlyPass.hlsl"


            ENDHLSL

        }
    }
    FallBack "Diffuse"
    // CustomEditor "HMKLitShaderGUI"

}
