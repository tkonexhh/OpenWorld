

Shader "HMK/RenderFeature/ScreenSpaceCloudShadow"
{
    Properties
    {
        _CloudTex ("CloudTex", 2D) = "white" { }
        _ShadowFactor ("XYZ:ColorMultiplier", Vector) = (1, 1, 1, 1)
        _CloudFactor ("XY:WindSpeed ZW:CloudTiling", Vector) = (0.05, 0.05, 2, 2)
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half3 _CloudFactor;
            half3 _ShadowColor;
            half _ShadowIntensity;
            half3 _FarPlaneWorldPos[4];
            half _Coverage, _Softness;
            half _DepthFade;
            CBUFFER_END

            TEXTURE2D(_CameraColorTexture);SAMPLER(sampler_CameraColorTexture);
            TEXTURE2D(_CloudTex);SAMPLER(sampler_CloudTex);
            // TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
            half4 _CameraDepthTexture_TexelSize;
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 ray: TEXCOORD1;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                // float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                // output.ray = positionWS - _WorldSpaceCameraPos;//云投影方向
                //获得四个角的世界坐标

                //用uv区分四个角，就四个点，if无所谓吧
                int index = 0;
                if (output.uv.x < 0.5 && output.uv.y > 0.5)
                    index = 0;
                // output.ray = float3(-500, -100, 500);
                else if (output.uv.x > 0.5 && output.uv.y > 0.5)
                    index = 1;
                // output.ray = float3(500, -100, 500);
                else if (output.uv.x < 0.5 && output.uv.y < 0.5)
                    index = 2;
                // output.ray = float3(-500, -100, -500);
                else
                    index = 3;
                // output.ray = float3(500, -100, -500);
                output.ray = _FarPlaneWorldPos[index];
                output.ray -= _WorldSpaceCameraPos;
                return output;
            }

            float4 frag(Varyings input): SV_Target
            {
                half4 var_CameraColor = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, input.uv);
                float var_Depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv);
                float depth = Linear01Depth(var_Depth, _ZBufferParams) ;

                float3 world = input.ray * depth + _WorldSpaceCameraPos;
                float2 world_uv = world.xz * _CloudFactor.z;
                float2 cloud_uv = world_uv * 0.005f; // 0.005 is some magic value.
                float2 cloud_wind = _CloudFactor.xy;
                float cloud_tiling = _CloudFactor.z;
                cloud_uv = (cloud_uv + cloud_wind) * cloud_tiling;
                
                float cloud = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, cloud_uv).r;		// use R channel only
                
                half stepValue = -_Softness + (1 - _Coverage) * (1 + (_Softness * 2));
                half coverageMin = stepValue - _Softness;
                half coverageMax = stepValue + _Softness;
                
                cloud = smoothstep(coverageMin, coverageMax, cloud);

                //添加距离遮罩
                half percent = lerp(1, 0, depth / _DepthFade);
                // return percent;
                float cloudMask = cloud * (1 - depth) * percent;		// fade by depth (don't render shadow to faraway skybox..)
                cloudMask = saturate(cloudMask);
                // return cloudMask;
                half3 cloudShadowColor = cloudMask * _ShadowColor ;
                half3 finalRGB = (1 - cloudMask * _ShadowIntensity) * var_CameraColor.rgb + cloudShadowColor * _ShadowIntensity ;
                // finalRGB *= percent;
                return half4(finalRGB, 1);
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
