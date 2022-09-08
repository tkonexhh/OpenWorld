

Shader "HMK/Utils/HeightToNormal"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _Strength ("Strength", float) = 1
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

            float _Strength;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;

                float4 tangentOS: TANGENT;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positiowWS: TEXCOORD1;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;

                float3 tangentWS: TEXCOORD2;
                float3 bitangentWS: TEXCOORD4;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positiowWS = TransformObjectToWorld(input.positionOS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;

                output.tangentWS = input.tangentOS;

                float crossSign = (input.tangentOS.w > 0.0 ? 1.0: - 1.0);
                float3 bitang = crossSign * cross(output.normalWS.xyz, output.tangentWS.xyz);
                output.bitangentWS = bitang;
                return output;
            }


            void Unity_NormalFromHeight_World_float(float In, float Strength, float3 Position, float3x3 TangentMatrix, out float3 Out)
            {
                float3 worldDerivativeX = ddx(Position);
                float3 worldDerivativeY = ddy(Position);

                float3 crossX = cross(TangentMatrix[2].xyz, worldDerivativeX);
                float3 crossY = cross(worldDerivativeY, TangentMatrix[2].xyz);
                float d = dot(worldDerivativeX, crossY);
                float sgn = d < 0.0 ?(-1.f): 1.f;
                float surface = sgn / max(0.00000000000001192093f, abs(d));

                float dHdx = ddx(In);
                float dHdy = ddy(In);
                float3 surfGrad = surface * (dHdx * crossY + dHdy * crossX);
                Out = normalize(TangentMatrix[2].xyz - (Strength * surfGrad));
            }

            float DecodeFloatRG(float2 enc)
            {
                float2 kDecodeDot = float2(1.0 / 255, 1.0);

                return dot(enc, kDecodeDot);
            }

            float4 frag(Varyings input): SV_Target
            {


                float3x3 _NormalFromHeight_2aa61d44f9d341d19d2921380b886fe8_TangentMatrix = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                float2 var_HeightMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).rg;

                float height = DecodeFloatRG(var_HeightMap.rg) * 416;

                half3 output;
                Unity_NormalFromHeight_World_float(height, _Strength, input.positiowWS, _NormalFromHeight_2aa61d44f9d341d19d2921380b886fe8_TangentMatrix, output);
                return half4(output, 1);
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
