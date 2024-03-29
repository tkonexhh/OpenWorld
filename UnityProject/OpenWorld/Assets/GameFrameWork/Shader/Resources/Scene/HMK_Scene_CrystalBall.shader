Shader "HMK/Scene/CrystalBall"
{
    Properties
    {
        [HDR]_colorTint ("ColorTint", color) = (1, 1, 1, 1)
        _BaseMap ("BaseMap", 2D) = "white" { }
        // _NRATex ("NRA", 2D) = "white" { }
        _CubeMap ("Cubemap", Cube) = "white" { }
        // _roughnessMax ("RoughnessMax", range(0, 1)) = 1
        // _roughnessMin ("RoughnessMin", range(0, 1)) = 0
        // _OpacityMax ("OpacityMax", range(0, 1)) = 1
        // _OpacityMin ("OpacityMin", range(0, 1)) = 0
        _FresnelInt ("FresnelInt", range(0.001, 5)) = 1
        _FresnelRange ("FresnelRange", range(0, 5)) = 1
    }




    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


    CBUFFER_START(UnityPerMaterial)
    half _roughnessMax;
    half _roughnessMin;
    half _OpacityMax;
    half _OpacityMin;
    half _FresnelInt;
    half _FresnelRange;
    half4 _colorTint;

    CBUFFER_END

    TEXTURE2D(_BaseMap);
    SAMPLER(sampler_BaseMap);
    TEXTURECUBE(_CubeMap);
    SAMPLER(sampler_CubeMap);

    // TEXTURE2D(_NRATex);
    // SAMPLER(sampler_NRATex);


    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        Pass
        {
            Tags { "RenderType" = "Geometry" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }

            Cull Back
            Blend One Zero
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            half3 Saturation_float(float3 In, float Saturation)
            {
                float luma = dot(In, float3(0.2126729, 0.7151522, 0.0721750));
                return luma.xxx + Saturation.xxx * (In - luma.xxx);
            }

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD1;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
            };



            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;


                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                Light mainLight = GetMainLight();
                mainLight.color.rgb = clamp(mainLight.color.rgb, 0.8, 1.5);

                float4 screenPos = ComputeScreenPos(input.positionCS);


                float2 screenUv = screenPos.xy / screenPos.w;

                // float4 colrefrac = tex2D(_CameraOpaqueTexture, screenUv);
                float3 worldViewDir = normalize((_WorldSpaceCameraPos.xyz - input.positionWS));

                half4 MainTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                // half4 NRATexMap = SAMPLE_TEXTURE2D(_NRATex, sampler_NRATex, input.uv);

                // float reconstructZ = sqrt(1.0 - saturate(dot(NRATexMap.xy, NRATexMap.xy)));
                // float3 normalVector = normalize(float3(NRATexMap.x, NRATexMap.y, reconstructZ));
                float3 worldReflection = reflect(-worldViewDir, normalize(input.normalWS));

                float4 reflectionColor = SAMPLE_TEXTURECUBE(_CubeMap, sampler_CubeMap, worldReflection);

                reflectionColor.rgb *= _colorTint.rgb * mainLight.color.rgb;

                half3 refracVec = refract(worldViewDir, input.positionWS, _OpacityMax);

                half4 EnvReflectColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, -worldReflection, 0);


                half3 RefracColor = DecodeHDREnvironment(EnvReflectColor, unity_SpecCube0_HDR);


                // half fresnel = saturate(_FresnelRange + (1 - _FresnelRange) * (pow(dot(worldViewDir, input.normalWS), _FresnelInt)));
                half fresnel = pow(1 - max(0, dot(input.normalWS, worldViewDir)), _FresnelRange);

                half4 finalcolor = lerp(float4(RefracColor, 1), reflectionColor, fresnel);

                // return MainTex;



                // finalcolor = lerp((finalcolor * _colorTint), finalcolor, fresnel);





                // return float4(fresnel.rrr, 1);
                return float4(finalcolor.rgb, 1);
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

            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            // #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // #include "./../Base/HMK_Lit_Input.hlsl"
            #include "./../Base/HMK_ShadowCasterPass.hlsl"


            ENDHLSL

        }
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM

            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // #include "./../Base/HMK_Lit_Input.hlsl"
            #include "./../Base/HMK_DepthOnlyPass.hlsl"

            ENDHLSL

        }
    }
    FallBack "Diffuse"
}