

Shader "HMK/AmplifyImpostor/BakeLit"
{
    Properties
    {
        [MainColor]_BaseColor ("固有色", color) = (1, 1, 1, 1)
        [NoScaleOffset] _BaseMap ("BaseMap", 2D) = "white" { }
        [NoScaleOffset] _PBRMap ("PBR贴图 R:金属度 G:粗糙度 B:AO", 2D) = "white" { }
        [NORMAL] [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" { }

        _BumpScale ("Bump Scale", range(0, 3)) = 1
        _MetallicScale ("MetallicScale", range(0, 3)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 3)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 3)) = 1
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
            HLSLPROGRAM

            #pragma exclude_renderers gles gles3 glcore
            #pragma target 5.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature _PBRMAP_ON
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            // --------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _BumpScale;
            half _MetallicScale, _RoughnessScale, _OcclusionScale;
            half _Cutoff;

            CBUFFER_END

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_PBRMap);SAMPLER(sampler_PBRMap);
            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
                half4 tangentOS: TANGENT;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 tangentWS: TEXCOORD2;
                float3 bitangentWS: TEXCOORD3;
                float eyeDepth: TEXCOORD4;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;

                float3 tangentWS = TransformObjectToWorldDir(input.tangentOS);
                half tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
                float3 bitangentWS = cross(normalWS, tangentWS) * tangentSign;

                float3 positionWS = TransformObjectToWorld(input.positionOS);

                float3 positiosVS = TransformWorldToView(positionWS);
                float eyeDepth = -positiosVS.z;

                output.normalWS = normalWS;
                output.tangentWS = tangentWS;
                output.bitangentWS = bitangentWS;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.eyeDepth = eyeDepth;
                return output;
            }


            void frag(Varyings input,
            out half4 outGBuffer0: SV_Target0,
            out half4 outGBuffer1: SV_Target1,
            out half4 outGBuffer2: SV_Target2,
            out half4 outGBuffer3: SV_Target3,
            out half4 outGBuffer4: SV_Target4,
            out half4 outGBuffer5: SV_Target5,
            out half4 outGBuffer6: SV_Target6,
            out half4 outGBuffer7: SV_Target7,
            out float outDepth: SV_Depth)
            {
                half4 var_MainTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half4 appendResult = half4(var_MainTex.rgb, 1);
                


                outGBuffer0 = appendResult;
                outGBuffer1 = 0;
                outGBuffer2 = 0;
                outGBuffer3 = 0;
                outGBuffer4 = 0;
                outGBuffer5 = 0;
                outGBuffer6 = 0;
                outGBuffer7 = 0;

                float alpha = var_MainTex.a - _Cutoff;
                clip(alpha);

                outDepth = 0;
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
