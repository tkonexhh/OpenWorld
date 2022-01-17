Shader "HMK/StylizedLit"
{
    Properties
    {
        // Specular vs Metallic workflow
        [HideInInspector] _WorkflowMode ("WorkflowMode", Float) = 1.0

        [MainTexture] _BaseMap ("Albedo", 2D) = "white" { }
        [HDR][MainColor] _BaseColor ("Color", Color) = (0, 0, 0, 0)

        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        //StylizedPBR
        //[Header(StylizedDiffuse)]
        [Space(10)]

        _BrushTex ("Brush Texture(R : Med Tone, G:Shadow, B:Reflect)", 2D) = "white" { }

        _MedBrushStrength ("Med Tone Brush Strength", Range(0, 1)) = 0
        _ShadowBrushStrength ("Shadow Brush Strength", Range(0, 1)) = 0
        _ReflBrushStrength ("Reflect Brush Strength", Range(0, 1)) = 0

        [Space(10)]
        _Width ("Out Line Width", Range(0, 20)) = 3
        _SpecularExponent ("Anisotropy", vector) = (1, 1, 0, 0)
        _MedColor ("Med Tone Color", Color) = (1, 1, 1, 1)
        _MedThreshold ("Med Tone Threshold", Range(0, 1)) = 1
        _MedSmooth ("Med Tone Smooth", Range(0, 0.5)) = 0.25

        [Space(10)]
        _ShadowColor ("Shadow Color", Color) = (0, 0, 0, 1)
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.5
        _ShadowSmooth ("Shadow Smooth", Range(0, 0.5)) = 0.25

        [Space(10)]
        _ReflectColor ("Reflect Color", Color) = (0, 0, 0, 0)
        _ReflectThreshold ("Reflect Threshold", Range(0, 1)) = 0
        _ReflectSmooth ("Reflect Smooth", Range(0, 0.5)) = 0.25

        _GIIntensity ("GI Intensity", Range(0, 4)) = 1

        //[Header(StylizedReflection)]
        [Toggle] _GGXSpecular ("GGX Specular", float) = 0
        _SpecularLightOffset ("Specular Light Offset", Vector) = (0, 0, 0, 0)
        _SpecularThreshold ("Specular Threshold", Range(0.1, 2)) = 0.5
        _SpecularSmooth ("Specular Smooth", Range(0, 0.5)) = 0.5
        _SpecularIntensity ("Specular Intensity", float) = 1

        [Space(10)]
        [Toggle] _DirectionalFresnel ("Directional Fresnel", float) = 0
        _FresnelThreshold ("Fresnel Threshold", Range(0, 1)) = 0.5
        _FresnelSmooth ("Fresnel Smooth", Range(0, 0.5)) = 0.5
        _FresnelIntensity ("Fresnel Intensity", float) = 1

        _ReflProbeIntensity ("Non Metal Reflection Probe Intensity", float) = 1
        _MetalReflProbeIntensity ("Metal Reflection Probe Intensity", float) = 1

        [Space(30)]
        _Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.5
        _GlossMapScale ("Smoothness Scale", Range(0.0, 1.0)) = 1.0
        _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0

        _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap ("Metallic", 2D) = "white" { }

        _SpecColor ("Specular", Color) = (0.2, 0.2, 0.2)
        _SpecGlossMap ("Specular", 2D) = "white" { }



        [ToggleOff] _SpecularHighlights ("Specular Highlights", Float) = 1.0
        [ToggleOff] _EnvironmentReflections ("Environment Reflections", Float) = 1.0

        _BumpScale ("Scale", Float) = 1.0
        _BumpMap ("Normal Map", 2D) = "bump" { }

        _OcclusionStrength ("Strength", Range(0.0, 1.0)) = 1.0
        // _OcclusionMap ("Occlusion", 2D) = "white" { }

        _EmissionColor ("Color", Color) = (0, 0, 0)
        _EmissionMap ("Emission", 2D) = "white" { }

        // Blending state
        [HideInInspector] _Surface ("__surface", Float) = 0.0
        [HideInInspector] _Blend ("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip ("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _Cull ("__cull", Float) = 2.0

        _ReceiveShadows ("Receive Shadows", Range(0, 1)) = 1.0     //얘도 살려둠
        // Editmode props
        [HideInInspector] _QueueOffset ("Queue offset", Float) = 0.0

        // ObsoleteProperties
        [HideInInspector] _MainTex ("BaseMap", 2D) = "white" { }
        [HideInInspector] _Color ("Base Color", Color) = (1, 1, 1, 1)
        [HideInInspector] _GlossMapScale ("Smoothness", Float) = 0.0
        [HideInInspector] _Glossiness ("Smoothness", Float) = 0.0
        [HideInInspector] _GlossyReflections ("EnvironmentReflections", Float) = 0.0
        _Opacity ("Opacity", range(0, 1)) = 0
    }

    SubShader
    {
        // Universal Pipeline tag is required. If Universal render pipeline is not set in the graphics settings
        // this Subshader will fail. One can add a subshader below or fallback to Standard built-in to make this
        // material work with both Universal Render Pipeline and Builtin Unity Pipeline
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        LOD 300

        // ------------------------------------------------------------------
        //  Forward pass. Shades all light in a single pass. GI + emission + Fog
        Pass
        {
            Name "Outline"

            Stencil
            {
                Ref   2
                ReadMask 255
                WriteMask 255
                Comp Always
                pass replace
                Fail replace
                ZFail Keep
                //replace

            }
            Cull front
            ZWrite On
            ZTest LEqual
            Blend one Zero, one Zero


            HLSLPROGRAM

            #pragma multi_compile_fog

            #pragma multi_compile_instancing
            #pragma vertex OutlineVertex
            #pragma fragment OutlineFrag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./../Base/HMK_StylizedLitInput.hlsl"
            #include "./../HLSLincludes/Common/HMK_Dither.hlsl"

            struct VertexInputOutline
            {
                float4 vertex: POSITION;
                half2 uv: TEXCOORD0;
                float3 normal: NORMAL;
                float4 vertexColor: COLOR;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutputOutline
            {
                float4 positionCS: POSITION;
                half fogCoord: TEXCOORD0;
                half2 uv: TEXCOORD1;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutputOutline OutlineVertex(VertexInputOutline input)
            {
                VertexOutputOutline output = (VertexOutputOutline)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);


                float3 scale;
                scale.x = length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x));
                scale.y = length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y));
                scale.z = length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z));
                // float3 objectScale = float3(length(unity_ObjectToWorld[ 0 ].xyz), length(unity_ObjectToWorld[ 1 ].xyz), length(unity_ObjectToWorld[ 2 ].xyz));
                input.vertex.xyz += input.normal * 0.001 * _Width / scale ;

                output.positionCS = TransformObjectToHClip(input.vertex.xyz);
                output.fogCoord = ComputeFogFactor(output.positionCS.z);
                output.uv = input.uv;
                return output;
            }

            //  Helper

            half4 OutlineFrag(VertexOutputOutline input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half4 color = 0;//_OutlineColor;
                color.rgb = MixFog(color.rgb, input.fogCoord);

                half4 Alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                // float DissolveTex = SAMPLE_TEXTURE2D(_BrushTex, sampler_BrushTex, input.uv * 0.5 * _BrushTex_ST.xy + _BrushTex_ST.zw).a;
                // half DissolveTex2 = step(DissolveTex, 1.05 - _Cutoff * 1.2);
                float Alpha2 = DitherOutput(input.positionCS);

                clip(Alpha2 - _Opacity);

                return float4(color.rgb, 1);
            }
            ENDHLSL

        }

        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Stencil
            {
                Ref   2
                ReadMask 255
                WriteMask 255
                Comp Always
                pass replace
                Fail replace
                ZFail Keep
                //replace

            }


            ZTest LEqual
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM

            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICSPECGLOSSMAP
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // #pragma shader_feature _OCCLUSIONMAP

            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature _SPECULAR_SETUP
            #pragma shader_feature _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fog
            #pragma multi_compile  _GIMAP_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment
            #include "./../Base/HMK_StylizedLitInput.hlsl"
            // #include "HMK_StylizedLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "./../HLSLincludes/Common/HMK_Dither.hlsl"


            //#include "LitInput.hlsl"
            //#include "LitForwardPass.hlsl"


            #pragma multi_compile _ _USEBRUSHTEX_ON

            #ifndef UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
                #define UNIVERSAL_FORWARD_LIT_PASS_INCLUDED


                struct Attributes
                {
                    float4 positionOS: POSITION;
                    float3 normalOS: NORMAL;
                    float4 tangentOS: TANGENT;
                    float2 texcoord: TEXCOORD0;
                    float2 texcoord2: TEXCOORD1;
                    // float2 lightmapUV: TEXCOORD2;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct Varyings
                {
                    float2 uv: TEXCOORD0;
                    float2 uv2: TEXCOORD1;
                    // DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

                    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                        float3 positionWS: TEXCOORD2;
                    #endif

                    float3 normalWS: TEXCOORD3;
                    #ifdef _NORMALMAP
                        float4 tangentWS: TEXCOORD4;    // xyz: tangent, w: sign
                    #endif
                    float3 viewDirWS: TEXCOORD5;

                    half4 fogFactorAndVertexLight: TEXCOORD6; // x: fogFactor, yzw: vertex light

                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        float4 shadowCoord: TEXCOORD7;
                    #endif

                    float4 positionCS: SV_POSITION;

                    UNITY_VERTEX_INPUT_INSTANCE_ID
                    UNITY_VERTEX_OUTPUT_STEREO
                };

                void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
                {
                    inputData = (InputData)0;

                    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                        inputData.positionWS = input.positionWS;
                    #endif

                    half3 viewDirWS = SafeNormalize(input.viewDirWS);
                    #ifdef _NORMALMAP
                        float sgn = input.tangentWS.w;      // should be either +1 or -1
                        float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                        inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
                    #else
                        inputData.normalWS = input.normalWS;
                    #endif

                    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                    inputData.viewDirectionWS = viewDirWS;

                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        inputData.shadowCoord = input.shadowCoord;
                    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                    #else
                        inputData.shadowCoord = float4(0, 0, 0, 0);
                    #endif

                    inputData.fogCoord = input.fogFactorAndVertexLight.x;
                    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                    inputData.bakedGI = 1;// SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
                    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                    inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
                }

                ///////////////////////////////////////////////////////////////////////////////
                //                  Vertex and Fragment functions                            //
                ///////////////////////////////////////////////////////////////////////////////

                // Used in Standard (Physically Based) shader
                Varyings LitPassVertex(Attributes input)
                {
                    Varyings output = (Varyings)0;

                    UNITY_SETUP_INSTANCE_ID(input);
                    UNITY_TRANSFER_INSTANCE_ID(input, output);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                    // normalWS and tangentWS already normalize.
                    // this is required to avoid skewing the direction during interpolation
                    // also required for per-vertex lighting and SH evaluation
                    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                    float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                    // already normalized from normal transform to WS.
                    output.normalWS = normalInput.normalWS;
                    output.viewDirWS = viewDirWS;
                    #ifdef _NORMALMAP
                        real sign = input.tangentOS.w * GetOddNegativeScale();
                        output.tangentWS = half4(normalInput.tangentWS.xyz, sign);
                    #endif

                    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                    // OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

                    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                        output.positionWS = vertexInput.positionWS;
                    #endif

                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        output.shadowCoord = GetShadowCoord(vertexInput);
                    #endif

                    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                    output.uv2 = input.texcoord2;
                    return output;
                }



                half3 DirectStylizedBDRF(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
                {
                    #ifndef _SPECULARHIGHLIGHTS_OFF
                        float3 halfDir = SafeNormalize(float3(lightDirectionWS) + float3(viewDirectionWS));

                        float NoH = saturate(dot(normalWS, halfDir));
                        half LoH = saturate(dot(lightDirectionWS, halfDir));

                        // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
                        // BRDFspec = (D * V * F) / 4.0
                        // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
                        // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
                        // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
                        // https://community.arm.com/events/1155

                        // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
                        // We further optimize a few light invariant terms
                        // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
                        float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

                        half LoH2 = LoH * LoH;
                        half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

                        // On platforms where half actually means something, the denominator has a risk of overflow
                        // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
                        // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
                        #if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
                            specularTerm = specularTerm - HALF_MIN;
                            specularTerm = clamp(specularTerm, 0.1, 100.0); // Prevent FP16 overflow on mobiles
                        #endif

                        half3 color = lerp(LinearStep(_SpecularThreshold - _SpecularSmooth, _SpecularThreshold + _SpecularSmooth, specularTerm), specularTerm, _GGXSpecular) * brdfData.specular * max(0, _SpecularIntensity) + max(0.01, brdfData.diffuse);
                        return color;
                    #else
                        return brdfData.diffuse;
                    #endif
                }

                half3 LightingStylizedPhysicallyBased(BRDFData brdfData, half3 radiance, half3 lightColor, half3 lightDirectionWS, half3 normalWS, half3 viewDirectionWS)
                {
                    return DirectStylizedBDRF(brdfData, normalWS, normalize(lightDirectionWS + _SpecularLightOffset.xyz), viewDirectionWS) * radiance;
                }

                half3 LightingStylizedPhysicallyBased(BRDFData brdfData, half3 radiance, Light light, half3 normalWS, half3 viewDirectionWS)
                {
                    return LightingStylizedPhysicallyBased(brdfData, radiance, clamp(light.color, 0.3, 1), light.direction, normalWS, viewDirectionWS);
                }

                //indirect Specular


                half3 EnvironmentBRDFCustom(BRDFData brdfData, half3 radiance, half3 indirectDiffuse, half3 indirectSpecular, half fresnelTerm)
                {
                    half3 c = indirectDiffuse * brdfData.diffuse ;
                    // return c;
                    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
                    c += surfaceReduction * indirectSpecular * lerp(brdfData.specular * radiance, brdfData.grazingTerm, fresnelTerm);
                    return c;
                }


                half3 StylizedGlobalIllumination(BRDFData brdfData, half3 radiance, half3 bakedGI, half occlusion, InputData inputData, half3 viewDirectionWS, half metallic, half ndotl)
                {
                    float3 normalWS = inputData.normalWS;
                    half4 irradiance = ShadeIrradiance(inputData.positionWS, normalWS);
                    occlusion = min(occlusion, irradiance.a);
                    occlusion = occlusion ;//* 0.5 + 0.5;
                    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
                    half fresnelTerm = LinearStep(_FresnelThreshold - _FresnelSmooth, _FresnelThreshold += _FresnelSmooth, 1.0 - saturate(dot(normalWS, viewDirectionWS))) * max(0, _FresnelIntensity) * ndotl;
                    half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
                    //间接光漫反射
                    half3 indirectDiffuse = irradiance.rgb * _GIIntensity * occlusion * 0.5 + irradiance.rgb * 0.5 * _GIIntensity ;
                    half DiffuseInt = pow(clamp((0.299 * indirectDiffuse.r + 0.587 * indirectDiffuse.g + 0.114 * indirectDiffuse.b), 0.2, 0.8), 2.2) ;
                    indirectDiffuse = (lerp((indirectDiffuse * 0.5 + brdfData.diffuse.rgb * 0.5), indirectDiffuse * brdfData.diffuse.rgb / 2, DiffuseInt) + min(ambient, float3(0.9, 0.9, 0.9)))  ;
                    // indirectDiffuse = max(indirectDiffuse * 1, brdfData.diffuse.rgb * 0.3);//* max(indirectDiffuse, 0.5));//MixGIAndIrradiance(bakedGI, irradiance.rgb * _GIIntensity, occlusion) * occlusion;
                    // indirectDiffuse = min(max(brdfData.diffuse.rgb * 0.8, brdfData.diffuse.rgb * indirectDiffuse), max(brdfData.diffuse.rgb * 0.8, (brdfData.diffuse.rgb + indirectDiffuse)));
                    //half3 indirectDiffuse = MixGIAndIrradiance(bakedGI, float3(0.045, 0.045, 0.05) * _GIIntensity, occlusion) * occlusion * 3;
                    // return brdfData.diffuse.rgb / 2.2  ;
                    //return indirectDiffuse;
                    half3 indirectSpecularResult = min(GlossyEnvironmentReflection(brdfData.perceptualRoughness, reflectVector, occlusion), ambient + DiffuseInt);
                    //间接光高光
                    half3 indirectSpecular = indirectSpecularResult * lerp(max(0, _ReflProbeIntensity), max(0, _MetalReflProbeIntensity), metallic) ;
                    // return fresnelTerm;
                    return EnvironmentBRDFCustom(brdfData, radiance, indirectDiffuse, indirectSpecular, fresnelTerm);
                }



                half3 CalculateRadiance(Light light, half3 normalWS, half3 brush, half3 brushStrengthRGB)
                {
                    half NdotL = dot(normalWS, light.direction);
                    #if _USEBRUSHTEX_ON
                        half halfLambertMed = NdotL * lerp(0.5, brush.r, brushStrengthRGB.r) + 0.5;
                        half halfLambertShadow = NdotL * lerp(0.5, brush.g, brushStrengthRGB.g) + 0.5;
                        half halfLambertRefl = NdotL * lerp(0.5, brush.b, brushStrengthRGB.b) + 0.5;
                    #else
                        half halfLambertMed = NdotL * 0.5 + 0.5;
                        half halfLambertShadow = halfLambertMed;
                        half halfLambertRefl = halfLambertMed;
                    #endif
                    half smoothMedTone = LinearStep(_MedThreshold - _MedSmooth, _MedThreshold + _MedSmooth, halfLambertMed);
                    half3 MedToneColor = lerp(_MedColor.rgb, 1, smoothMedTone);
                    half smoothShadow = LinearStep(_ShadowThreshold - _ShadowSmooth, _ShadowThreshold + _ShadowSmooth, halfLambertShadow * (lerp(1, light.distanceAttenuation * light.shadowAttenuation, _ReceiveShadows)));
                    half3 ShadowColor = lerp(_ShadowColor.rgb, MedToneColor, smoothShadow);   //그림자를 합쳐주는 부분이 포인트!
                    // return ShadowColor;
                    half smoothReflect = LinearStep(_ReflectThreshold - _ReflectSmooth, _ReflectThreshold + _ReflectSmooth, halfLambertRefl);
                    half3 ReflectColor = lerp(_ReflectColor.rgb, ShadowColor, smoothReflect);
                    half3 radiance = clamp(light.color, 0.5, 1) * ReflectColor;//lightColor * (lightAttenuation * NdotL);
                    return radiance;
                }


                half4 UniversalFragmentStylizedPBR(InputData inputData, SurfaceData surfaceData, half2 uv)
                {
                    half3 albedo = surfaceData.albedo;
                    half metallic = surfaceData.metallic;
                    half3 specular = surfaceData.specular;
                    half smoothness = surfaceData.smoothness;
                    half occlusion = surfaceData.occlusion;
                    half emission = 0;//surfaceData.emission;
                    half alpha = surfaceData.alpha;

                    BRDFData brdfData;
                    InitializeBRDFData(albedo, metallic, max(specular, 0.1), smoothness, alpha, brdfData);

                    Light mainLight = GetMainLight(inputData.shadowCoord);
                    #if _USEBRUSHTEX_ON
                        float3 brushTex = SAMPLE_TEXTURE2D(_BrushTex, sampler_BrushTex, uv * _BrushTex_ST.xy + _BrushTex_ST.zw).rgb;
                        float3 radiance = CalculateRadiance(mainLight, inputData.normalWS, brushTex, float3(_MedBrushStrength, _ShadowBrushStrength, _ReflBrushStrength));
                    #else
                        float3 radiance = CalculateRadiance(mainLight, inputData.normalWS, 0.5, float3(0, 0, 0));
                    #endif
                    // return half4(radiance, alpha);;
                    inputData.bakedGI = ShadeGI(inputData.normalWS);

                    float ndotl = LinearStep(_ShadowThreshold - _ShadowSmooth, _ShadowThreshold + _ShadowSmooth, dot(mainLight.direction, inputData.normalWS) * 0.5 + 0.5);

                    half3 color = LightingStylizedPhysicallyBased(brdfData, radiance, mainLight, inputData.normalWS, inputData.viewDirectionWS);
                    // return half4(color, alpha);

                    // color = 0;
                    color += StylizedGlobalIllumination(brdfData, radiance, inputData.bakedGI, occlusion, inputData, inputData.viewDirectionWS, metallic, lerp(1, ndotl, _DirectionalFresnel));
                    // return half4(color, alpha);

                    //******额外光照*****
                    int additionalLightsCount = GetAdditionalLightsCount();
                    for (int i = 0; i < additionalLightsCount; ++i)
                    {
                        int perObjectLightIndex = GetPerObjectLightIndex(i);
                        Light light = GetAdditionalLight(perObjectLightIndex, inputData.positionWS);
                        color += LightingPhysicallyBased(brdfData, light, inputData.normalWS, inputData.viewDirectionWS);
                    }


                    color += emission;
                    return half4(color, alpha);
                }


                // Used in Standard (Physically Based) shader
                half4 LitPassFragment(Varyings input): SV_Target
                {
                    UNITY_SETUP_INSTANCE_ID(input);
                    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                    SurfaceData surfaceData;
                    InitializeStandardLitSurfaceData(input.uv, surfaceData);

                    InputData inputData;
                    InitializeInputData(input, surfaceData.normalTS, inputData);
                    Light mainLight = GetMainLight();
                    half4 color = UniversalFragmentStylizedPBR(inputData, surfaceData, input.uv);
                    half3 worldViewDir = inputData.viewDirectionWS ;

                    half3 UpVector = half3(0, 1, 0);
                    half3 TangentV = cross(inputData.normalWS, UpVector);
                    half3 TangentU = cross(inputData.normalWS, TangentV);
                    half3 H = normalize(worldViewDir + mainLight.direction);
                    half4 SpecularExponent = _SpecularExponent;
                    half3 SpecNormalX = H - (TangentU * dot(H, TangentU));
                    half3 SpecNormalY = H - (TangentV * dot(H, TangentV));
                    float NDotHX = max(0., dot(SpecNormalX, H));
                    float NDotHXk = pow(pow(NDotHX, SpecularExponent.x * 2), 100);
                    NDotHXk *= SpecularExponent.z;
                    float NDotHY = max(0., dot(SpecNormalY, H));
                    float NDotHYk = pow(NDotHY, SpecularExponent.y * 0.5);
                    NDotHYk *= SpecularExponent.w;
                    float SpecTerm = NDotHXk * NDotHYk;
                    half3 emission = SampleEmission(input.uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
                    // emission *= abs(sin((_Time.y * 3)));
                    color.rgb += emission;
                    color.rgb *= max(1, mainLight.color);
                    color.rgb += SpecTerm * (1 - surfaceData.metallic);
                    color.rgb = MixFog(color.rgb, inputData.fogCoord) * 1;
                    half fresnel = dot(inputData.normalWS, worldViewDir);
                    fresnel = saturate(pow((1 - fresnel), 10) * 2);
                    // float DissolveTex = SAMPLE_TEXTURE2D(_BrushTex, sampler_BrushTex, input.uv * 0.5 * _BrushTex_ST.xy + _BrushTex_ST.zw).a;
                    // half DissolveTex2 = step(DissolveTex, 1.05 - _Cutoff * 1.2);
                    // DissolveTex = step(DissolveTex, 1 - _Cutoff * 1.2);
                    // DissolveTex = DissolveTex2 - DissolveTex;

                    // DissolveTex = DissolveTex2 - DissolveTex;
                    // color.rgb = color.rgb * DissolveTex2 + (1 - DissolveTex2) * float3(1, 1, 1);
                    half4 Alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv2);

                    color.rgb *= Alpha.a;
                    color.rgb += fresnel * _BaseColor.rgb;
                    // color.rgb = clamp(color.rgb, color.rgb , color.rgb * 2);
                    color.a = OutputAlpha(color.a);

                    float Alpha2 = DitherOutput(input.positionCS);

                    clip(Alpha2 - _Opacity);
                    color.rgb = saturate(color.rgb);
                    return color;
                }
            #endif

            ENDHLSL

        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            Stencil
            {
                Ref   2
                ReadMask 255
                WriteMask 255
                Comp Always
                pass replace
                Fail replace
                ZFail Keep
                //replace

            }
            ZWrite On
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM

            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment



            #include "./../Base/HMK_StylizedLitInput.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL

        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            Stencil
            {
                Ref   2
                ReadMask 255
                WriteMask 255
                Comp Always
                pass replace
                Fail replace
                ZFail Keep
                //replace

            }
            ZWrite On
            ColorMask 0
            Cull off
            HLSLPROGRAM

            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            // #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "./../Base/HMK_StylizedLitInput.hlsl"


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./../HLSLincludes/Common/HMK_Dither.hlsl"

            struct Attributes
            {
                float4 position: POSITION;
                float2 texcoord: TEXCOORD0;
                float3 normal: NORMAL;
                float4 vertexColor: COLOR;
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

                float3 scale;
                scale.x = length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x));
                scale.y = length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y));
                scale.z = length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z));
                // float3 objectScale = float3(length(unity_ObjectToWorld[ 0 ].xyz), length(unity_ObjectToWorld[ 1 ].xyz), length(unity_ObjectToWorld[ 2 ].xyz));
                input.position.xyz += input.normal * 0.001 * _Width / scale ;

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input): SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half4 var_Base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half alpha = var_Base.a;
                // float DissolveTex = SAMPLE_TEXTURE2D(_BrushTex, sampler_BrushTex, input.uv * 0.5 * _BrushTex_ST.xy + _BrushTex_ST.zw).a;
                // half DissolveTex2 = step(DissolveTex, 1.05 - _Cutoff * 1.2);

                // clip(alpha * DissolveTex2 - 0.01);

                clip(alpha - _Cutoff);

                float Alpha = DitherOutput(input.positionCS);

                clip(Alpha - _Opacity);

                return 0;
            }

            ENDHLSL

        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.StylizedLitShader"
}
