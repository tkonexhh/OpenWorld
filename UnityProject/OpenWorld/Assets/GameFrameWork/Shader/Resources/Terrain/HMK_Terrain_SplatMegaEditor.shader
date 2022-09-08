

Shader "HMK/Terrain/Terrain_SplatMegaEditor"
{
    Properties
    {
        _AlbedoArray ("AlbedoArray", 2D) = "white" { }
        _IndexMap ("IndexMap RGB", 2D) = "white" { }
        
        
        _NRAArray ("NRAArray", 2D) = "white" { }


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


            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "./HMK_Terrain.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float _UVScale;

            CBUFFER_END

            TEXTURE2D(_IndexMap);SAMPLER(sampler_IndexMap);
            TEXTURE2D(_AlbedoArray);SAMPLER(sampler_AlbedoArray);
            TEXTURE2D(_NRAArray);SAMPLER(sampler_NRAArray);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 tangentWS: TANGENT;
                float3 bitangentWS: TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                // float3 tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
                // half tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
                float3 tangentWS = cross(normalWS, float3(0, 0, 1));//TransformObjectToWorldDir(input.tangentOS);
                half tangentSign = -1;
                float3 bitangentWS = cross(normalWS, tangentWS) * tangentSign;
                output.normalWS = normalWS;
                output.tangentWS = tangentWS;
                output.bitangentWS = bitangentWS;
                output.uv = input.uv;
                // output.fogFactor = ComputeFogFactor(output.positionCS.z);

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                float2 uv = input.uv;
                float3 normalWS = normalize(input.normalWS);
                
                float2 uv_Top = (input.positionWS.xz * _UVScale);
                // return float4(frac(uv_Top), 0, 1);


                half3 albedo = 0;
                half metallic = 0;
                half roughness = 0;
                half occlusion = 1;
                half3 normalTS = 0;
                half4 blend = 0;
                
                
                half4 var_Control = SAMPLE_TEXTURE2D(_IndexMap, sampler_IndexMap, uv);
                
                float2 twoVerticalIndices = floor((var_Control.xy * 9.0));
                float2 twoHorizontalIndices = (floor((var_Control.xy * 256.0)) - (9.0 * twoVerticalIndices));

                float4 decodedIndices;
                decodedIndices.x = twoHorizontalIndices.x;
                decodedIndices.y = twoVerticalIndices.x;
                decodedIndices.z = twoHorizontalIndices.y;
                decodedIndices.w = twoVerticalIndices.y;
                decodedIndices = floor(decodedIndices / 3) / 3;

                
                float2 worldScale = (input.positionWS.xz * _UVScale);
                float2 worldUv = 0.234375 * frac(worldScale) + 0.0078125; // 0.0078125 ~ 0.2421875, the range of a block
                float2 dx = clamp(0.234375 * ddx(worldScale), -0.0078125, 0.0078125);
                float2 dy = clamp(0.234375 * ddy(worldScale), -0.0078125, 0.0078125);


                float2 uv0 = worldUv.xy + decodedIndices.xy;
                float2 uv1 = worldUv.xy + decodedIndices.zw;
                
                // Sample the two texture
                float4 col0 = SAMPLE_TEXTURE2D_GRAD(_AlbedoArray, sampler_AlbedoArray, uv0, dx, dy);
                float4 col1 = SAMPLE_TEXTURE2D_GRAD(_AlbedoArray, sampler_AlbedoArray, uv1, dx, dy);
                // Blend the two textures
                float4 col = lerp(col0, col1, var_Control.z);
                return col;

                
                float3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                normalWS = TransformTangentToWorld(normalTS, TBN);

                //ANTI Tilling
                //高度混合
                

                HMKSurfaceData surfaceData = InitSurfaceData(albedo, 1, metallic, roughness, occlusion);
                HMKLightingData lightingData = InitLightingData(input.positionWS, normalWS);

                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                
                
                return float4(albedo, surfaceData.alpha);
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
