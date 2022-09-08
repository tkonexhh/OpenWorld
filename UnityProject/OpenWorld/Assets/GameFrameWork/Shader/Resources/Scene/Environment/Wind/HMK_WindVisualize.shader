

Shader "HMK/Environment/WindVisualize"
{
    Properties { }
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
            #include "./../../Hidden/Wind.hlsl"
            CBUFFER_START(UnityPerMaterial)


            CBUFFER_END
            
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
                output.uv = input.uv;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                // half4 var_Wind = SAMPLE_TEXTURE2D(_WindMap, sampler_WindMap, input.uv);
                // var_Wind.r = var_Wind.r * (var_Wind.g * 2.0h - 0.243h);
                float2 uv = GetWindMapUV(input.positionWS);
                float4 v = SAMPLE_TEXTURE2D_LOD(_WindMap, sampler_WindMap, uv, 0).rgba;
                // half var_Wind = SampleWindMap(input.positionWS);
                return v * _WindStrength;
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
