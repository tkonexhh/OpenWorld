

Shader "Hidden/Terrain/FarComposite"
{
    Properties
    {
        _Control0 ("Control (RGBA)", 2D) = "black" { }
        _Control1 ("Control (RGBA)", 2D) = "black" { }
        _Splat0 ("Splat0 (R)", 2D) = "grey" { }
        _Splat1 ("Splat1 (G)", 2D) = "grey" { }
        _Splat2 ("Splat2 (B)", 2D) = "grey" { }
        _Splat3 ("Splat3 (A)", 2D) = "grey" { }
        _Splat4 ("Splat0 (R)", 2D) = "grey" { }
        _Splat5 ("Splat1 (G)", 2D) = "grey" { }
        _Splat6 ("Splat2 (B)", 2D) = "grey" { }
        _Splat7 ("Splat3 (A)", 2D) = "grey" { }

        _UVScale ("贴图 UVScale", Range(0.001, 1)) = 0.2
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
            float _UVScale;
            CBUFFER_END
            
            TEXTURE2D(_Control0);SAMPLER(sampler_Control0); TEXTURE2D(_Control1);
            TEXTURE2D(_Splat0);SAMPLER(sampler_Splat0);TEXTURE2D(_Splat1);TEXTURE2D(_Splat2);TEXTURE2D(_Splat3);TEXTURE2D(_Splat4);TEXTURE2D(_Splat5);TEXTURE2D(_Splat6);TEXTURE2D(_Splat7);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD1;
                float2 uv: TEXCOORD0;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = input.uv;


                return output;
            }


            half3 HeightBasedSplatModify(inout half4 splatControl0, inout half4 splatControl1, in half4 albedos[8])
            {
                // float heightBias = 0.2;
                half heights[8];
                heights[0] = albedos[0].a * splatControl0.r;
                heights[1] = albedos[1].a * splatControl0.g;
                heights[2] = albedos[2].a * splatControl0.b;
                heights[3] = albedos[3].a * splatControl0.a;
                heights[4] = albedos[4].a * splatControl1.r;
                heights[5] = albedos[5].a * splatControl1.g;
                heights[6] = albedos[6].a * splatControl1.b;
                heights[7] = albedos[7].a * splatControl1.a;

                half maxHeight = max(heights[0], max(heights[1], max(heights[2], max(heights[3], max(heights[4], max(heights[5], max(heights[6], heights[7]))))))) - 0.2;

                heights[0] = max(heights[0] - maxHeight, 0) * splatControl0.r;
                heights[1] = max(heights[1] - maxHeight, 0) * splatControl0.g;
                heights[2] = max(heights[2] - maxHeight, 0) * splatControl0.b;
                heights[3] = max(heights[3] - maxHeight, 0) * splatControl0.a;
                heights[4] = max(heights[4] - maxHeight, 0) * splatControl1.r;
                heights[5] = max(heights[5] - maxHeight, 0) * splatControl1.g;
                heights[6] = max(heights[6] - maxHeight, 0) * splatControl1.b;
                heights[7] = max(heights[7] - maxHeight, 0) * splatControl1.a;
                return
                (albedos[0].rgb * heights[0]
                + albedos[1].rgb * heights[1]
                + albedos[2].rgb * heights[2]
                + albedos[3].rgb * heights[3]
                + albedos[4].rgb * heights[4]
                + albedos[5].rgb * heights[5]
                + albedos[6].rgb * heights[6]
                + albedos[7].rgb * heights[7])
                / (heights[0] + heights[1] + heights[2] + heights[3] + heights[4] + heights[5] + heights[6] + heights[7]);
            }

            half4 frag(Varyings input): SV_Target
            {
                float2 uv = input.uv;
                half4 splatControl0 = SAMPLE_TEXTURE2D(_Control0, sampler_Control0, uv);
                half4 splatControl1 = SAMPLE_TEXTURE2D(_Control1, sampler_Control0, uv);

                
                float2 uv_Top = uv * 200;


                half4 albedos[8];


                
                albedos[0] = SAMPLE_TEXTURE2D(_Splat0, sampler_Splat0, uv_Top);
                albedos[1] = SAMPLE_TEXTURE2D(_Splat1, sampler_Splat0, uv_Top);
                albedos[2] = SAMPLE_TEXTURE2D(_Splat2, sampler_Splat0, uv_Top);
                albedos[3] = SAMPLE_TEXTURE2D(_Splat3, sampler_Splat0, uv_Top);
                albedos[4] = SAMPLE_TEXTURE2D(_Splat4, sampler_Splat0, uv_Top);
                albedos[5] = SAMPLE_TEXTURE2D(_Splat5, sampler_Splat0, uv_Top);
                albedos[6] = SAMPLE_TEXTURE2D(_Splat6, sampler_Splat0, uv_Top);
                albedos[7] = SAMPLE_TEXTURE2D(_Splat7, sampler_Splat0, uv_Top);

                half3 albedo = half3(0, 0, 0);
                // #ifdef _TERRAIN_BLEND_HEIGHT
                // albedo = HeightBasedSplatModify(splatControl0, splatControl1, albedos);
                // #else
                    albedo += albedos[0] * splatControl0.r ;
                albedo += albedos[1] * splatControl0.g ;
                albedo += albedos[2] * splatControl0.b ;
                albedo += albedos[3] * splatControl0.a ;

                albedo += albedos[4] * splatControl1.r ;
                albedo += albedos[5] * splatControl1.g ;
                albedo += albedos[6] * splatControl1.b ;
                albedo += albedos[7] * splatControl1.a ;
                // #endif
                //应用AntiTilling

                return half4(albedo, 1);
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
