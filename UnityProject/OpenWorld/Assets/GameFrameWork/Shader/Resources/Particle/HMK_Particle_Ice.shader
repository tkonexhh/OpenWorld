Shader "HMK/Particle/Ice"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _UvScale ("UvScale", vector) = (1, 1, 0, 0)
        [HDR]_ColorTint ("ColorTint", color) = (1, 1, 1, 1)
        _BumpTex ("BumpTex", 2D) = "white" { }
        [HDR]_BumpColorTint ("BumpColorTint", color) = (1, 1, 1, 1)
        _AlphaTex ("AlphaTex", 2D) = "white" { }
        _HeightOffset ("HeightOffset", range(-1, 1)) = 0
        _AlphaClip ("AlphaCLip", range(0, 1)) = 0
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


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _ColorTint;
            half4 _BumpColorTint;
            half _HeightOffset;
            half _AlphaClip;
            half4 _UvScale;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpTex);SAMPLER(sampler_BumpTex);
            TEXTURE2D(_AlphaTex);SAMPLER(sampler_AlphaTex);
            float2 ParallaxOffset(half h, half height, half3 viewDir)
            {
                h = h * height - height / 2.0;
                float3 v = normalize(viewDir);
                //单位指向相机向量.z +0.42
                v.z += 0.42;
                // 偏移.x = 高度*（单位指向相机向量的x / 单位指向相机向量的z）
                // 偏移.y = 高度*（单位指向相机向量的y / 单位指向相机向量的z）
                return h * (v.xy / v.z);
            }
            float2 ParallaxMapping(float2 texCoords, float3 viewDir)
            {
                float height = -1;
                float2 p = viewDir.xy * (height * float2(0.01, 0.02));
                return texCoords - p;
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
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 positionWS: TEXCOORD1;
            };



            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;

                output.positionWS = TransformObjectToWorld(input.positionOS);//   mul(unity_ObjectToWorld, v.vertex).xyz;
                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                half3 var_ViewDir = (input.positionWS - _WorldSpaceCameraPos);

                // float3 reflDir = reflect(-var_ViewDir, float3(0, 1, 0));

                // float4 reflectionColor = SAMPLE_TEXTURECUBE(unity_SpecCube0, samplerunity_SpecCube0, reflDir);

                half2 parallaxUV = ParallaxMapping(input.uv, var_ViewDir);

                half4 var_BumpTex = SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, parallaxUV);


                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.positionWS.xz * _UvScale.xy + float2(var_BumpTex.b * _UvScale.z, 0)) ;

                half4 var_AlphaTex = SAMPLE_TEXTURE2D(_AlphaTex, sampler_AlphaTex, input.uv) ;

                half4 FinalColor = lerp(var_BumpTex.r * _BumpColorTint, var_MainTex * _ColorTint, saturate(var_MainTex - _HeightOffset));

                half alpha = saturate((var_AlphaTex.r + var_AlphaTex.g) / 2) ;

                clip(alpha - _AlphaClip);


                return FinalColor;
            }

            ENDHLSL

        }
    }
    FallBack "Diffuse"
}