

Shader "HMK/StencilLit"
{
    Properties
    {
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Header(Base Color)]
        [MainColor]_BaseColor ("固有色", color) = (1, 1, 1, 1)
        [NoScaleOffset] _BaseMap ("BaseMap", 2D) = "white" { }
        [NoScaleOffset] _PBRMap ("PBR贴图 R:金属度 G:粗糙度 B:AO", 2D) = "white" { }
        _MetallicScale ("MetallicScale", range(0, 1)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 1)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 1)) = 1
        [NORMAL] [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" { }

        [Header(Option)]
        [HideInInspector] _AlphaClip ("__clip", Float) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)]  _Cull ("__Cull", float) = 2.0

        [Header(OutLine)]
        _Border ("Width", Float) = 5
        _OutlineColor ("OutLineColor", color) = (0, 0, 0, 0)
    }
    SubShader
    {

        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
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
            // Blend one Zero


            HLSLPROGRAM

            #pragma target 4.5


            // #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma vertex OutlineVertex
            #pragma fragment OutlineFrag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            CBUFFER_START(UnityPerMaterial)
            half4 _OutlineColor;
            half _Border;
            half _Cutoff;
            CBUFFER_END
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
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
                input.vertex.xyz += input.normal * 0.001 * _Border * step(0.1, input.vertexColor.b) / scale ;

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
                half4 color = _OutlineColor;
                color.rgb = MixFog(color.rgb, input.fogCoord);

                half4 Alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                clip(Alpha.a - _Cutoff);
                //return color;
                return float4(color.rgb, 1);
            }
            ENDHLSL

        }



        Pass
        {
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
            Blend one Zero
            ZTest LEqual
            ZWrite On
            Cull off
            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature _PBRMAP_ON
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "./HMK_Lit_Input.hlsl"
            #include "./HMK_Lit_ForwardPass.hlsl"

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
            
            #include "./HMK_Lit_Input.hlsl"
            #include "./HMK_ShadowCasterPass.hlsl"

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
            #pragma fragment DepthOnlyFragment1

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON


            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            // #include "./Himiko/Shader/URP/Resources/Base/
            // #include "./HMK_DepthOnlyPass.hlsl"
            #include "./../Character/HMK_Character_DepthOnlyPass.hlsl"
            CBUFFER_START(UnityPerMaterial)

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
                input.vertex.xyz += input.normal * 0.001 * _Border * input.vertexColor.b / scale;
                output.positionCS = TransformObjectToHClip(input.vertex.xyz);
                output.uv = input.uv;
                return output;
            }
            half4 DepthOnlyFragment1(Varyings input): SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                half4 var_Base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half alpha = var_Base.a;

                clip(alpha - 0.2);

                return 0;
            }
            ENDHLSL

        }
    }
    FallBack "Diffuse"
    // CustomEditor "HMKLitShaderGUI"

}
