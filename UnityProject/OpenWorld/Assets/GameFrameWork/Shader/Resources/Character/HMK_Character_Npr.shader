Shader "HMK/Character/NPR"
{
    Properties
    {
        [HDR]_ColorTint ("ColorTint", color) = (1, 1, 1, 1)
        _BaseMap ("MainTex", 2D) = "white" { }
        _DarkShadowMultColor ("DarkShadowMultColor", color) = (0.79, 0.79, 0.79, 1)
        _ShadowMultColor ("ShadowMultColor", color) = (0.79, 0.79, 0.79, 1)
        _ShadowArea ("ShadowArea", Float) = 0.14
        _DarkShadowArea ("DarkShadowArea", range(0, 1)) = 0.419
        _FixDarkShadow ("FixDarkShadow", Float) = 1
        _DarkShadowSmooth ("DarkShadowSmooth", Float) = 0.3
        _ShadowSmooth ("ShadowSmooth", Float) = 0.167
        _fresnelPow ("fresnelPow", Float) = 1.0
        _fresnelInt ("fresnelInt", Float) = 1.0

        _OutlineColor ("Color (RGB) Alpha (A)", Color) = (0, 0, 0, 1)
        _Border ("Width", Float) = 5
        _ShadowIntensity ("ShadowIntensity", Float) = 0.0
        // _BaseMapAO ("AO", 2D) = "white" { }
        _ShadowOffset ("ShadowBias", vector) = (0, -0.001, 0.01, 0)
        _SpecularExponent ("Anisotropy", vector) = (1, 1, 0, 0)
        _Opacity ("Opacity", range(0, 1)) = 0
        // [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestOutline ("ZTest Outline", Int) = 4
        // [Enum(UnityEngine.Rendering.CullMode)]

    }



    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
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
            //  Blend one Zero
            Blend One Zero, One Zero
            ZTest LEqual
            ZWrite On
            Cull off

            HLSLPROGRAM

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLincludes/Common/HMK_Dither.hlsl"



            CBUFFER_START(UnityPerMaterial)
            half4 _ShadowMultColor;
            half4 _DarkShadowMultColor;
            half _ShadowArea;
            half _DarkShadowArea;
            half _FixDarkShadow;
            half _DarkShadowSmooth;
            half _ShadowSmooth;
            half4 _FresnelColor;
            half _fresnelPow;
            half _fresnelInt;
            half _ShadowIntensity;
            half4 _ShadowOffset;
            half4 _ColorTint;
            half4 _SpecularExponent;
            half _Opacity;
            half4 _OutlineColor;
            half _Border;
            CBUFFER_END

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);


            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
                float4 vertexColor: COLOR;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float4 vertexColor: COLOR;
                float4 shadowCoord: TEXCOORD1;
                float4 positionWS: TEXCOORD2;
                half4 fogFactor: TEXCOORD3;
            };



            Varyings vert(Attributes input)
            {
                Varyings output;

                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS.xyz = TransformObjectToWorld(input.positionOS.xyz);
                output.vertexColor = input.vertexColor;
                output.shadowCoord = TransformWorldToShadowCoord(output.positionWS);
                half fogFactor = ComputeFogFactor(output.positionCS.z);

                output.fogFactor = fogFactor;





                return output;
            }


            float4 frag(Varyings input): SV_Target
            {

                Light mainLight = GetMainLight(input.shadowCoord + _ShadowOffset);
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy) ;
                // half4 baseColorAO = SAMPLE_TEXTURE2D(_BaseMapAO, sampler_BaseMapAO, input.uv.xy) ;x
                // baseColor *= saturate((baseColorAO.r * 0.5) + 0.3);
                half3 ShadowColor = baseColor.rgb * _ShadowMultColor.rgb;
                // half3 DarkShadowColor = baseColor.rgb * 0.8 + unity_AmbientSky.xyz * 0.02;//_DarkShadowMultColor.rgb;
                half3 DarkShadowColor = baseColor.rgb * _DarkShadowMultColor.rgb;

                half3 worldLight = normalize(float3(mainLight.direction.x, 0, mainLight.direction.z));
                half halfLambert = dot(input.normalWS, worldLight) * 0.5 + 0.5;

                half3 ShallowShadowColor = float3(1, 0, 0);


                half rampS = smoothstep(0, _ShadowSmooth, halfLambert - _ShadowArea);
                half rampDS = smoothstep(0, _DarkShadowSmooth, halfLambert - _DarkShadowArea) ;
                DarkShadowColor = rampDS * (_FixDarkShadow * ShadowColor + (1 - _FixDarkShadow) * ShallowShadowColor) + (1 - rampDS) * DarkShadowColor;
                DarkShadowColor.rgb = lerp(DarkShadowColor.rgb, ShadowColor, rampDS);

                ShallowShadowColor = lerp(ShadowColor, baseColor.rgb, rampS);
                half3 cameraDir = -1 * mul(UNITY_MATRIX_M, transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V)) [2].xyz);

                half fresnel = dot(-cameraDir, normalize(input.normalWS));
                fresnel = clamp(abs(pow(fresnel, _fresnelPow)) * _fresnelInt, 0, 1);
                half4 FinalColor;

                FinalColor.rgb = rampDS * ShallowShadowColor + (1 - rampDS) * DarkShadowColor;
                half3 FinalColorShadow = baseColor.rgb * _DarkShadowMultColor ;
                half3 worldViewDir = normalize(_WorldSpaceCameraPos - input.positionWS);

                half3 UpVector = half3(0, 1, 0);
                half3 TangentV = cross(input.normalWS, UpVector);
                half3 TangentU = cross(input.normalWS, TangentV);
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
                FinalColor.rgb += SpecTerm;

                FinalColor.rgb = lerp(FinalColorShadow, FinalColor.rgb, smoothstep(0, 0.1, saturate(mainLight.shadowAttenuation - _ShadowIntensity))) * _ColorTint.rgb ;

                // FinalColor.rgb = FinalColorShadow;

                FinalColor.rgb *= clamp((mainLight.color.r + mainLight.color.g + mainLight.color.b) / 3, 0.8, 2) * lerp(0.15, 1, baseColor.a);



                FinalColor.rgb = MixFog(FinalColor.rgb, input.fogFactor) * 1;
                // float Alpha = max(DitherOutput(input.positionCS), 0.21);
                float Alpha = 1;
                // clip(Alpha - _Opacity);

                return float4(FinalColor.rgb, Alpha);
            }

            ENDHLSL

        }
        Pass
        {
            Name "Outline"

            //  Here we have to fool URP < 8.0: We want the outline to render AFTER the regular shaded pass.
            //  This worked fine in URP 7.4.1 but 8.x and above would draw the outine first...
            //  So we tag the outline pass as "LightMode" = "UniversalForward" whcih makes unity draw it after our "regular" pass.

            // Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Quene" = "Transparent+100" }

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
            Blend One Zero, One Zero

            HLSLPROGRAM

            #pragma target 4.5


            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma vertex OutlineVertex
            #pragma fragment OutlineFrag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "./../HLSLincludes/Common/HMK_Dither.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _ShadowMultColor;
            half4 _DarkShadowMultColor;
            half _ShadowArea;
            half _DarkShadowArea;
            half _FixDarkShadow;
            half _DarkShadowSmooth;
            half _ShadowSmooth;
            half4 _FresnelColor;
            half _fresnelPow;
            half _fresnelInt;
            half _ShadowIntensity;
            half4 _ShadowOffset;
            half4 _ColorTint;
            half4 _SpecularExponent;
            half _Opacity;
            half4 _OutlineColor;
            half _Border;
            CBUFFER_END



            struct VertexInputOutline
            {
                float4 vertex: POSITION;

                float3 normal: NORMAL;
                float4 verttexColor: COLOR;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutputOutline
            {
                float4 positionCS: POSITION;
                half fogCoord: TEXCOORD0;

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




                input.vertex.xyz += input.normal * 0.001 * _Border * input.verttexColor.r / scale;
                output.positionCS = TransformObjectToHClip(input.vertex.xyz);
                output.fogCoord = ComputeFogFactor(output.positionCS.z);


                return output;
            }

            //  Helper

            half4 OutlineFrag(VertexOutputOutline input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half4 color = _OutlineColor;
                color.rgb = MixFog(color.rgb, input.fogCoord);

                float Alpha = max(DitherOutput(input.positionCS), 0.21);
                clip(Alpha - _Opacity);



                return color;
            }
            ENDHLSL

        }
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull off

            HLSLPROGRAM

            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex1
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON


            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            // #include "./Himiko/Shader/URP/Resources/Base/
            #include "./../Character/HMK_Character_DepthOnlyPass.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _ShadowMultColor;
            half4 _DarkShadowMultColor;
            half _ShadowArea;
            half _DarkShadowArea;
            half _FixDarkShadow;
            half _DarkShadowSmooth;
            half _ShadowSmooth;
            half4 _FresnelColor;
            half _fresnelPow;
            half _fresnelInt;
            half _ShadowIntensity;
            half4 _ShadowOffset;
            half4 _ColorTint;
            half4 _SpecularExponent;

            half4 _OutlineColor;
            half _Border;
            CBUFFER_END
            Varyings DepthOnlyVertex1(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);


                float3 scale;
                scale.x = length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x));
                scale.y = length(float3(UNITY_MATRIX_M[0].y, UNITY_MATRIX_M[1].y, UNITY_MATRIX_M[2].y));
                scale.z = length(float3(UNITY_MATRIX_M[0].z, UNITY_MATRIX_M[1].z, UNITY_MATRIX_M[2].z));

                input.vertex.xyz += input.normal * 0.001 * _Border * input.vertexColor.r / scale;
                output.positionCS = TransformObjectToHClip(input.vertex.xyz);

                return output;
            }
            ENDHLSL

        }
    }

    FallBack "Diffuse"
}