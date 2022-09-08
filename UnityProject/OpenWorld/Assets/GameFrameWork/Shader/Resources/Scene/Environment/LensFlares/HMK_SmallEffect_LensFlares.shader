

Shader "HMK/SmallEffect/LensFlares"
{
    Properties
    {
        _FlareTexture ("FlareTexture", 2D) = "white" { }
    }
    SubShader
    {
        Tags { "RenderType" = "Overlay" "Queue" = "Overlay" }
        LOD 100

        Pass
        {

            Tags { "LightMode" = "UniversalForward" }
            ZWrite off
            ZTest off
            Blend one OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag
            
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            struct appdata
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 positionHCS: SV_POSITION;
                //float4 pimf : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            TEXTURE2D(_FlareTexture);SAMPLER(sampler_FlareTexture);
            TEXTURE2D_X_FLOAT(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            
            float4 _SunPositionAndAspect;
            
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
            UNITY_DEFINE_INSTANCED_PROP(float4, _FlareTexture_ST)
            UNITY_DEFINE_INSTANCED_PROP(float4, _FlareColor)      //颜色
            UNITY_DEFINE_INSTANCED_PROP(float, _FlareDistance)    //与太阳距离
            UNITY_DEFINE_INSTANCED_PROP(float4, _FlareUV)         //UV偏移值
            UNITY_DEFINE_INSTANCED_PROP(float, _FlareSize)        //光斑尺寸
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)
            
            float4 _TexelSize;
            //x firstFlareSize
            //y lastFlareSize
            //z strength
            float4 _GlobalSettingsParam;
            float _FlareStrength;//光斑强度
            //float _FlareFirstSize;
            //float _FlareLastSize;

            static int _COUNT = 5;
            
            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FlareTexture_ST);
                o.uv = v.uv * baseST.xy + baseST.zw;
                float4 flareUV = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FlareUV);

                o.uv = - (o.uv * flareUV.xy + flareUV.zw);
                
                //float3 quadPivotPosOS = float3(0,0,0);
                //float3 quadPivotPosWS = TransformObjectToWorld(quadPivotPosOS);
                //float3 quadPivotPosVS = TransformWorldToView(quadPivotPosWS);

                //float3 worldPos = GetMainLight().direction * 1000 + _WorldSpaceCameraPos.xyz;

                float3 worldPos = _SunPositionAndAspect.xyz;
                float3 quadPivotPosVS = TransformWorldToView(worldPos);
                float4 sunScreenPosition = TransformWViewToHClip(quadPivotPosVS);
                float4 sunScreenUV = ComputeScreenPos(sunScreenPosition);

                //float _MinFlareSize = _FlareMinSize;
                //float _MaxFlareSize = _FlareMaxSize;
                
                float flareDistance = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FlareDistance);
                
                //float2 SCpos = _SunScreenPosition.xy * 2 - 1;
                float2 SCpos = (sunScreenUV.xy / sunScreenUV.w) * 2 - 1;
                float2 ECpos = -SCpos;
                float2 OffPos = ECpos - SCpos;
                OffPos.y /= _SunPositionAndAspect.w;
                
                float visibilityCount = 0;
                //光斑可见性测试
                for (int x = -_COUNT; x <= _COUNT; x++)
                {
                    for (int y = -_COUNT; y <= _COUNT; y++)
                    {
                        float3 testPosVS = quadPivotPosVS;
                        float4 PivotPosCS = mul(GetViewToHClipMatrix(), float4(testPosVS, 1));
                        float4 PivotScreenPos = ComputeScreenPos(PivotPosCS);
                        float2 screenUV = PivotScreenPos.xy / PivotScreenPos.w;
                        screenUV += float2(x, y) * _TexelSize.xy * 3;
                        if (screenUV.x > 1 || screenUV.x < 0 || screenUV.y > 1 || screenUV.y < 0)
                            continue;

                        float sampledScreenDepth = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV, 0).x;
                        float linearEyeDepthFromSceneDepthTexture = LinearEyeDepth(sampledScreenDepth, _ZBufferParams);
                        float linearEyeDepthFromSelfALU = PivotPosCS.w;
                        visibilityCount += linearEyeDepthFromSelfALU < linearEyeDepthFromSceneDepthTexture ? 1: 0;
                    }
                }
                float diviver = _COUNT * 2 + 1;
                float visibility = visibilityCount / (diviver * diviver);
                float FSize = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FlareSize) * visibility * _FlareStrength;
                FSize *= lerp(_GlobalSettingsParam.x, _GlobalSettingsParam.y, flareDistance);
                float2 cxy = normalize(float2(SCpos.x, SCpos.y));
                
                float2x2 rotMat = float2x2(cxy.y, cxy.x, -cxy.x, cxy.y);
                float2 bxy = mul(rotMat, v.positionOS.xy);
                float3 posVS = quadPivotPosVS + float3((((bxy * FSize) - (OffPos * flareDistance)) * quadPivotPosVS.z), 0);
                
                o.positionHCS = mul(GetViewToHClipMatrix(), float4(posVS, 1));
                return o;
            }

            
            
            float4 frag(v2f i): SV_Target
            {
                
                UNITY_SETUP_INSTANCE_ID(i);
                float4 col = SAMPLE_TEXTURE2D(_FlareTexture, sampler_FlareTexture, 1 - i.uv);
                float4 Scolor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FlareColor);
                col.rgb *= Scolor.rgb * Scolor.a * _GlobalSettingsParam.z;
                // col.a = col. r * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FlareStrength);
                col.a = col.r ;//* _FlareStrength;
                // return _FlareStrength;
                return col ;
            }
            ENDHLSL

        }
    }
}
