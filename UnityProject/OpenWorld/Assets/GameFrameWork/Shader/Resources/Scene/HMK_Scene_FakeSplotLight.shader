

Shader "HMK/Scene/FakeSplotLight"
{
    Properties
    {
        _Color ("Main Color", Color) = (1, 1, 1, .5)
        _Intensity ("Intensity", Range(0, 5)) = 1
        _BlendDepth ("BlendDepth", float) = 5
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Transparent" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            // Cull OFF
            // Blend One One
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite OFF

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            half _Intensity, _BlendDepth;
            CBUFFER_END

            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
                float4 positionSS: TEXCOORD3;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float e: texcoord1;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionSS = ComputeScreenPos(output.positionCS);
                output.uv = input.uv;

                float e = 1 - (input.positionOS.y + 1) * 0.5;
                output.e = e;
                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                
                half4 finalColor = _Color;
                float3 viewDirWS = normalize(GetWorldSpaceViewDir(input.positionWS));
                float3 normalWS = normalize(input.normalWS);
                float VdotN = saturate(dot(viewDirWS, normalWS));
                float VdotN_revert = saturate(dot(viewDirWS, -normalWS));
                VdotN = max(VdotN, VdotN_revert);
                VdotN *= VdotN;
                // return VdotN;

                float2 screenUV = input.positionSS.xy / input.positionSS.w;
                float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                sceneZ = LinearEyeDepth(sceneZ, _ZBufferParams);

                half fre4 = (sceneZ - ComputeScreenPos(input.positionCS).w);
                // half fre4FF = clamp(fre4, 0, 1);

                half blendFactor = saturate(fre4 / _BlendDepth);
                // return blendFactor;
                // blendFactor = smoothstep(0.5, _BlendDepth, fre4);


                finalColor.a *= VdotN;
                finalColor *= pow(input.e, 2);
                finalColor *= _Intensity * blendFactor;
                return finalColor;
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
