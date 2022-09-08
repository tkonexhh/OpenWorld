

Shader "HMK/Utils/ShowVertexColor"
{
    Properties
    {
        [Enum(HMK.Render.VertexColorChannel)]_Channel ("Channel", int) = 0
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
            int _Channel;

            CBUFFER_END

            
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                half4 color: COLOR;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                half4 color: COLOR;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                output.color = input.color;

                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                if (_Channel == 0)
                    return half4(input.color.rgb, 1.0);
                else if (_Channel == 1)
                    return input.color.r;
                else if (_Channel == 2)
                    return input.color.g;
                else if (_Channel == 3)
                    return input.color.b;
                else// if (_Channel == 4)
                    return input.color.a;
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
