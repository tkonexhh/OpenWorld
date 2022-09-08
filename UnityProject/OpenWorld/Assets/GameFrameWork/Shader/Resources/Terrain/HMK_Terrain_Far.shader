//远景shader
//只需要Albedo和法线就可以了
Shader "HMK/Terrain/Far"
{
    Properties
    {
        [NoScaleOffset]_AlbedoMap ("AlbedoMap", 2D) = "white" { }
        [NoScaleOffset] _NormalMap ("NormalMap", 2D) = "bump" { }
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            // -------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"

            CBUFFER_START(UnityPerMaterial)


            CBUFFER_END

            TEXTURE2D(_AlbedoMap);SAMPLER(sampler_AlbedoMap);
            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
            
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
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 positionWS: TEXCOORD1;
                half3 tangentWS: TEXCOORD3;
                half3 bitangentWS: TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            
            Varyings vert(Attributes input)
            {
                UNITY_SETUP_INSTANCE_ID(input);

                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                float3 tangentWS = cross(normalWS, float3(0, 0, 1));//TransformObjectToWorldDir(input.tangentOS);
                half tangentSign = -1;//input.tangentOS.w * unity_WorldTransformParams.w;
                float3 bitangentWS = cross(normalWS, tangentWS) * tangentSign;

                output.uv = input.uv;
                output.normalWS = normalWS;
                output.tangentWS = tangentWS;
                output.bitangentWS = bitangentWS;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);

                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                
                // half4 var_NormalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv) ;
                // float3 normalTS = UnpackNormal(var_NormalMap);
                // float3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                // float3 normalWS = normalTS;//mul(normalTS, TBN);

                // float3 normalWS = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv);
                // normalWS = normalize(normalWS * 2 - 1);
                // return half4(input.normalWS, 1);

                // Light mainLight = GetMainLight();
                // float nDotl = dot(input.normalWS, mainLight.direction);
                // return nDotl;
                
                half3 mainColor = SAMPLE_TEXTURE2D(_AlbedoMap, sampler_AlbedoMap, input.uv);
                

                HMKSurfaceData surfaceData = InitSurfaceData(mainColor, 1, 0, 1, 1);
                HMKLightingData lightingData = InitLightingData(input.positionWS, input.normalWS);


                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                
                // return half4(normalTS.rgb, 1);
                return half4(finalRGB, 1);
            }
            
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
            #pragma enable_cbuffer

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
