Shader "XHH/DrawIndirect"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
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
            #include "./ComputeShader/XHH_GPUDriven_Struct.hlsl"

            StructuredBuffer<InstanceTRS> _InstanceTRSBuffer;
            StructuredBuffer<uint> _ArgsBuffer;
            StructuredBuffer<uint> _OutputDataBuffer;
            uniform uint _ArgsOffset;
            
            CBUFFER_START(UnityPerMaterial)


            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            
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
            };

            
            Varyings vert(Attributes input, uint instanceID: SV_InstanceID)
            {
                Varyings output;
                uint index = instanceID + _ArgsBuffer[_ArgsOffset];
                InstanceTRS data = _InstanceTRSBuffer[_OutputDataBuffer[index]];
                float3 perPivotPositionWS = data.position;
                float3 positionWS = input.positionOS + perPivotPositionWS;
                output.positionCS = TransformWorldToHClip(positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;


                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                return var_MainTex;
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}