Shader "XHH/DrawIndirect"
{
    Properties
    {
        _ColorTop ("ColorTop", color) = (0.5, 1, 0, 1)
        _ColorBottom ("ColorBottom", color) = (0, 1, 0, 1)
        _ColorRange ("ColorRange", range(-1, 1)) = 1.0
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
            StructuredBuffer<uint> _InstanceIDBuffer;
            uniform uint _ArgsOffset;
            
            CBUFFER_START(UnityPerMaterial)
            half4 _ColorTop, _ColorBottom;
            half _ColorRange;

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
                float3 color: COLOR;
            };

            
            Varyings vert(Attributes input, uint instanceID: SV_InstanceID)
            {
                Varyings output;
                uint index = instanceID + _ArgsBuffer[_ArgsOffset];
                InstanceTRS data = _InstanceTRSBuffer[_InstanceIDBuffer[index]];

                float3 perPivotPositionWS = data.position;
                float3 positionWS = input.positionOS + perPivotPositionWS;
                output.positionCS = TransformWorldToHClip(positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;

                half3 albedo = lerp(_ColorBottom, _ColorTop, saturate(input.positionOS.y + _ColorRange));
                output.color = albedo;
                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                
                return half4(input.color, 1);
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}