Shader "HMK/Terrain/Terrain_SplatMega"
{
    Properties
    {
        _Control ("Control (RGBA)", 2D) = "white" { }
        _SplatArray ("SplatArray", 2DArray) = "white" { }
        _NRAArray ("NRAArray", 2DArray) = "white" { }
        
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
            #include "./HMK_Terrain.hlsl"

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
            TEXTURE2D_ARRAY(_NRAArray);SAMPLER(sampler_NRAArray);

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
                // float4 tangentOS: TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                // float4 tangentWS: TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


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
                // output.tangentWS = input.tangentOS;
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = input.uv;
                float3 normalWS = normalize(input.normalWS);
                
                float2 uv_Top = (input.positionWS.xz * _UVScale);


                float deltaUV = _Control_TexelSize.x;
                float2 baseUV = uv;
                float2 rightUV = uv + float2(deltaUV, 0);
                float2 upUV = uv + float2(0, deltaUV);
                float2 rightUpUV = uv + float2(deltaUV, deltaUV);
                // return half4(baseUV, 0, 1);

                half3 var_Control_Base = SAMPLE_TEXTURE2D(_Control, sampler_Control, baseUV);
                half3 var_Control_Right = SAMPLE_TEXTURE2D(_Control, sampler_Control, rightUV);
                half3 var_Control_Up = SAMPLE_TEXTURE2D(_Control, sampler_Control, upUV);
                half3 var_Control_RightUp = SAMPLE_TEXTURE2D(_Control, sampler_Control, rightUpUV);

                int index_Base = var_Control_Base.r * 255;
                int index_Right = var_Control_Right.r * 255;
                int index_Up = var_Control_Up.r * 255;
                int index_RightUp = var_Control_RightUp.r * 255;

                half4 albedo_Base = SAMPLE_TEXTURE2D_ARRAY(_SplatArray, sampler_SplatArray, uv_Top, index_Base);
                half4 albedo_Right = SAMPLE_TEXTURE2D_ARRAY(_SplatArray, sampler_SplatArray, uv_Top, index_Right);
                half4 albedo_Up = SAMPLE_TEXTURE2D_ARRAY(_SplatArray, sampler_SplatArray, uv_Top, index_Up);
                half4 albedo_RightUp = SAMPLE_TEXTURE2D_ARRAY(_SplatArray, sampler_SplatArray, uv_Top, index_RightUp);

                return albedo_Right;
                
                
                // return float4(finalRGB, surfaceData.alpha);

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
