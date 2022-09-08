

Shader "HMK/Scene/PlaneFog"
{
    Properties
    {
        [NoScaleOffset]  _MainTex ("MainTex", 2D) = "white" { }
        _Tilling ("Tilling", float) = 1
        _BaseSpeed ("Speed", float) = 1
        _FadeRange ("Fade Range", float) = 1000
        _HeightFade ("Height Fade", float) = 5
        _BlendDepth ("BlendDepth", float) = 5
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }

        //这个shader中将使用两个pass，第一个pass用来计算深度，第二个pass用来着色 这样第二个pass就能拿到第一个pass的深度值;了
        pass
        {
            ZWrite On
            ColorMask 0
        }


        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite off
            Cull Back
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "./../../Hidden/Wind.hlsl"
            #include "./../../../HLSLIncludes/Common/Fog.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half _Tilling;
            half _BaseSpeed;
            half _FadeRange;
            half _HeightFade;
            half _BlendDepth;
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
                float3 positionWS: TEXCOORD1;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float4 positionSS: TEXCOORD2;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = input.uv;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionSS = ComputeScreenPos(output.positionCS);
                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                half2 windDir = _WindDirection.xz;
                float2 uv = input.uv * _Tilling ;
                uv += windDir * _Time.y * _BaseSpeed * 0.05;
                float distanceToCamera = distance(_WorldSpaceCameraPos, input.positionWS);
                float distanceFactor = saturate(distanceToCamera / _FadeRange);

                float yFactor = abs(_WorldSpaceCameraPos.y - input.positionWS.y) / _HeightFade;
                yFactor = max(saturate(yFactor), 0.0001);
                // return yFactor;
                float2 screenUV = input.positionSS.xy / input.positionSS.w;
                float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                sceneZ = LinearEyeDepth(sceneZ, _ZBufferParams);

                half fre4 = (sceneZ - ComputeScreenPos(input.positionCS).w);
                // half fre4FF = clamp(fre4, 0, 1);

                half blendFactor = fre4 / _BlendDepth;
                blendFactor = smoothstep(0.5, _BlendDepth, fre4);
                // return blendFactor;
                //岸边边缘淡化
                // return half4(uv, 0, 1);

                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                //边缘模糊

                half3 finalRGB = lerp(var_MainTex.rrr * _FogColor, _FogColor, distanceFactor);
                // return finalRGB.r;
                return half4(finalRGB, finalRGB.r * yFactor * blendFactor);
            }
            
            ENDHLSL

        }
    }
    // FallBack "Diffuse"

}
