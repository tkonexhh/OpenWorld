
Shader "HMK/Particle/DissolveDisturbanceAdvance"
{


    Properties
    {
        [Space(10)]
        [Header(BaseColor)]
        _BaseMap ("BaseMap ", 2D) = "white" { }
        [NoscaleOffset]_DissolveMap ("DissolveMap", 2D) = "white" { }
        [HDR]_Color ("ColortTint", Color) = (1, 1, 1, 1)

        [Space(10)]
        [Header(Disturb)]
        _DisturbUSpeed ("DisturbUSpeed", float) = 0
        _DisturbVSpeed ("DisturbVSpeed", float) = 0
        _DisturbUSpeed2 ("DisturbUSpeed2", float) = 0
        _DisturbVSpeed2 ("DisturbVSpeed2", float) = 0
        _DisturbIntensity ("DisturbIntensity", float) = 0
        _DisturbIntensity2 ("DisturbIntensity2", float) = 0
        _DisturbMapTiling ("DisturbMapTiling", float) = 1

        [Space(10)]
        [Header(Dissolve)]


        _DissolveEdge ("DissolveEdge", float) = 0.1
        _DissolveMapTiling ("DissolveMapTiling", float) = 1
        _DissolveOp ("DissolveOp", float) = 1
        [HDR]_EdgeColor ("EdgeColorTint", Color) = (1, 1, 1, 1)



        [Space(10)]
        [Header(Other)]
        _AlphaClipThreshold ("AlphaClipThreshold", float) = 0.1
        [Toggle(UseInParticle)]UseInParticle ("UseInParticle", Float) = 1
        [Toggle(UseFresnel)]UseFresnel ("UseFresnel", Float) = 0
        _FresnelRange ("FresnelRange", float) = 1
        [Enum(UnityEngine.Rendering.CullMode)]  _Cull ("__Cull", float) = 2.0
        _ColorInt ("ColorInt", float) = 1
        // [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4

    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "UniversalForward" }
            // Blend SrcAlpha OneMinusSrcAlpha
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
            Blend One Zero, One Zero
            ZWrite On

            Offset 0, 0
            ColorMask RGBA
            Cull[_Cull]

            HLSLPROGRAM

            #define _ALPHATEST_ON 1
            #pragma shader_feature UseInParticle
            #pragma shader_feature UseFresnel
            // #pragma exclude_renderers gles gles3 glcore

            // GPU Instancing
            #pragma multi_compile_particles
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)

            half _DissolveEdge;
            half _DisturbUSpeed;
            half _DisturbVSpeed;
            half _DisturbUSpeed2;
            half _DisturbVSpeed2;
            half4 _BaseMap_ST;
            half _DisturbIntensity;
            half _DissolveMapTiling;
            half _DisturbMapTiling;
            half _DisturbIntensity2;
            half4 _Color;
            half _AlphaClipThreshold;
            half _BaseFlowSpeedU;
            half _BaseFlowSpeedV;
            half _FresnelRange;
            half _DissolveOp;
            half4 _EdgeColor;
            half _ColorInt;
            CBUFFER_END


            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_DissolveMap);SAMPLER(sampler_DissolveMap);
            struct Attributes
            {
                float4 vertex: POSITION;
                half4 normal: NORMAL;
                half2 texcoord0: TEXCOORD0;
                half4 texcoord1: TEXCOORD1;
                half4 texcoord2: TEXCOORD2;
            };
            struct Varyings
            {
                float4 pos: SV_POSITION;
                half2 uv0: TEXCOORD0;


                float4 Color: TEXCOORD1;
                float DissolveOp: TEXCOORD2;
                float3 BaseColor: TEXCOORD3;
                float UVDissolve: TEXCOORD4;
                float BaseColorInt: TEXCOORD5;
                float Fresnel: TEXCOORD6;
            };
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.uv0 = TRANSFORM_TEX(input.texcoord0, _BaseMap);
                output.pos = TransformObjectToHClip(input.vertex);
                #ifdef UseFresnel
                    float3 worldNormal = TransformObjectToWorldNormal(input.normal);
                    float3 worldPos = TransformObjectToWorld(input.vertex.xyz);
                    float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
                    output.Fresnel = dot(worldViewDir, worldNormal);
                #endif

                #ifdef UseInParticle
                    output.Color = input.texcoord1;
                    output.DissolveOp = input.texcoord2.r;
                    output.UVDissolve = input.texcoord2.g;
                    output.BaseColorInt = input.texcoord2.b;

                #endif

                return output;
            }
            half4 frag(Varyings input): SV_Target
            {


                half4 Time = _Time;
                half2 DisturbUV = (input.uv0 + half2((_DisturbUSpeed * Time.y), (Time.y * _DisturbVSpeed)));


                half DisturbMap2 = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, DisturbUV + half2((_DisturbUSpeed2 * Time.y), (Time.y * _DisturbVSpeed2))).b;

                half DisturbMap = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, DisturbUV * _DisturbMapTiling + half2(DisturbMap2 * _DisturbIntensity2, 0)).r;

                half DissolveMap = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, input.uv0 * _DissolveMapTiling).g;


                half4 BaseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv0 + half2(DisturbMap * _DisturbIntensity, 0));




                half Dissolve = step(DissolveMap, _DissolveOp);
                half Dissolve2 = step(DissolveMap, saturate(_DissolveOp - _DissolveEdge));
                BaseColor.rgb = (_EdgeColor.rgb) * saturate(1 - Dissolve2) + BaseColor.rgb * saturate(Dissolve2) * input.BaseColorInt * _Color ;

                #ifdef UseInParticle
                    Dissolve = step(DissolveMap, input.DissolveOp);
                    Dissolve2 = step(DissolveMap, saturate(input.DissolveOp - _DissolveEdge));

                    BaseColor.a *= step(input.uv0, input.UVDissolve);
                    BaseColor.rgb = (input.Color.rgb) * saturate(1 - Dissolve2) + BaseColor.rgb * saturate(Dissolve2) * input.BaseColorInt * _Color ;
                    DisturbMap.r = 0;
                #endif
                BaseColor.rgb = lerp(BaseColor.rgb, _EdgeColor, DisturbMap.r) ;

                BaseColor.a *= Dissolve;
                #ifdef UseFresnel
                    float Fresnel = (0.0 + 1.0 * pow(1.0 - input.Fresnel, _FresnelRange));
                    BaseColor.rgb = lerp(BaseColor.rgb, _EdgeColor, Fresnel) ;
                #endif
                clip(BaseColor.a - _AlphaClipThreshold);


                // BaseColor.rgb *= _ColorInt;
                BaseColor.rgb = clamp(BaseColor.rgb, 0, 2);

                return BaseColor;
            }
            ENDHLSL

        }
        // Pass
        // {
        //     Name "DepthOnly"
        //     Tags { "LightMode" = "DepthOnly" }

        //     ZWrite On
        //     ColorMask 0
        //     Cull[_Cull]

        //     HLSLPROGRAM

        //     #pragma vertex DepthOnlyVertex1
        //     #pragma fragment DepthOnlyFragment1

        //     // -------------------------------------
        //     // Material Keywords
        //     #pragma shader_feature_local_fragment _ALPHATEST_ON


        //     //--------------------------------------
        //     // GPU Instancing
        //     #pragma multi_compile_particles
        //     #pragma multi_compile_instancing
        //     #pragma multi_compile _ DOTS_INSTANCING_ON
        //     // #include "./Himiko/Shader/URP/Resources/Base/
        //     // #include "./HMK_DepthOnlyPass.hlsl"
        //     #include "./../Particle/HMK_Particle_DepthOnlyPass.hlsl"

        //     CBUFFER_START(UnityPerMaterial)

        //     half _DissolveEdge;
        //     half _DisturbUSpeed;
        //     half _DisturbVSpeed;
        //     half _DisturbUSpeed2;
        //     half _DisturbVSpeed2;
        //     half4 _BaseMap_ST;
        //     half _DisturbIntensity;
        //     half _DissolveMapTiling;
        //     half _DisturbMapTiling;
        //     half _DisturbIntensity2;
        //     half4 _Color;
        //     half _AlphaClipThreshold;
        //     half _BaseFlowSpeedU;
        //     half _BaseFlowSpeedV;
        //     half _FresnelRange;
        //     half _DissolveOp;
        //     half4 _EdgeColor;
        //     CBUFFER_END

        //     TEXTURE2D(_DissolveMap);SAMPLER(sampler_DissolveMap);



        //     Varyings DepthOnlyVertex1(Attributes input)
        //     {
        //         Varyings output = (Varyings)0;
        //         UNITY_SETUP_INSTANCE_ID(input);
        //         UNITY_TRANSFER_INSTANCE_ID(input, output);
        //         UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

        //         output.uv0 = TRANSFORM_TEX(input.texcoord0, _BaseMap);
        //         output.pos = TransformObjectToHClip(input.vertex);

        //         output.BaseColorInt = 1;

        //         #ifdef UseInParticle
        //             output.Color = input.texcoord1;
        //             output.DissolveOp = input.texcoord2.r;
        //             output.UVDissolve = input.texcoord2.g;
        //             output.BaseColorInt = input.texcoord2.b;

        //         #endif
        //         return output;
        //     }
        //     half4 DepthOnlyFragment1(Varyings input): SV_TARGET
        //     {
        //         UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        //         UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        //         half4 Time = _Time;
        //         half2 DisturbUV = (input.uv0 + half2((_DisturbUSpeed * Time.y), (Time.y * _DisturbVSpeed)));

        //         half DisturbMap = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, DisturbUV * _DisturbMapTiling).r;
        //         half DissolveMap = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, input.uv0 * _DissolveMapTiling).g;
        //         half MaskMap = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, DisturbUV).b;



        //         half4 BaseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, ((input.uv0 + half2(DisturbMap * _DisturbIntensity, 0) + half2(_Time.g * _BaseFlowSpeedU, _Time.g * _BaseFlowSpeedV)))) * input.BaseColorInt;


        //         half Dissolve = step(DissolveMap, _DissolveOp);
        //         half Dissolve2 = step(DissolveMap, saturate(_DissolveOp - _DissolveEdge));

        //         #ifdef UseInParticle
        //             Dissolve = step(DissolveMap, input.DissolveOp);
        //             Dissolve2 = step(DissolveMap, saturate(input.DissolveOp - _DissolveEdge));
        //             BaseColor.a *= step(input.uv0, input.UVDissolve);
        //         #endif


        //         BaseColor.a *= Dissolve;





        //         clip(BaseColor.a - _AlphaClipThreshold);





        //         return 0;
        //     }
        //     ENDHLSL

        // }

    }
}
