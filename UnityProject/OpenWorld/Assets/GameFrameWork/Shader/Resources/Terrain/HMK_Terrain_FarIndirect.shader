

Shader "HMK/Terrain/FarIndirect"
{
    Properties
    {
        [NoScaleOffset] _HeightMap ("HeightMap", 2D) = "black" { }
        _MaxHeight ("MaxHeight", float) = 500
        [NoScaleOffset] _AlbedoMap ("AlbedoMap", 2D) = "white" { }
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    
    #define TERRAIN_GRID_COUNT 10
    #define TERRAIN_COUNT 2
    //2048/20 = 102.4
    #define TERRAIN_GRID_SIZE 102.4

    CBUFFER_START(UnityPerMaterial)
    float _MaxHeight;
    float3 _StartPosition;
    // float2 _TerrainPos;
    CBUFFER_END

    TEXTURE2D(_HeightMap);SAMPLER(sampler_HeightMap);
    TEXTURE2D(_AlbedoMap);SAMPLER(sampler_AlbedoMap);
    TEXTURE2D(_TerrainHoleMap);SAMPLER(sampler_TerrainHoleMap);

    float3 GetPositionWS(int x, int y)
    {
        return float3((x + 0.5) * TERRAIN_GRID_SIZE, 0, (y + 0.5) * TERRAIN_GRID_SIZE) + _StartPosition;
    }

    float2 GetUV(int x, int y, float2 uv)
    {
        float2 step = float2(x, y) / TERRAIN_GRID_COUNT;
        uv = uv / TERRAIN_GRID_COUNT + step;
        return uv;
    }

    // float2 GetTerrainHoleUV(float x, float y, float2 uv)
    // {
    //     float2 step = float2(x, y) / TERRAIN_GRID_COUNT;
    //     uv = step;//uv / TERRAIN_GRID_COUNT + step;
    //     // uv = uv * (1.0 / TERRAIN_COUNT) + _TerrainPos * (1.0 / TERRAIN_COUNT);
    //     // int tileSum = TERRAIN_GRID_COUNT * TERRAIN_COUNT;
    //     // uv = ceil(uv * tileSum) / tileSum;
    //     // 正确的是上面的 先给他算好了
    //     uv = uv * 0.5 + _TerrainPos * 0.5;
    //     // uv = ceil(uv * 20) / 20;
    //     return uv;
    // }

    ENDHLSL

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
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            
            
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
                float3 positionWS: TEXCOORD2;
            };
            
            Varyings vert(Attributes input, uint instanceID: SV_InstanceID)
            {
                //全地图是一个20*20的
                // 根据instanceID 转为二维坐标 拿到对应的格子坐标
                int x = instanceID / TERRAIN_GRID_COUNT;
                int y = instanceID % TERRAIN_GRID_COUNT;
                
                
                //采样挖洞图
                // float2 uv_TerrainHole = GetTerrainHoleUV(x + 0.01, y + 0.01, input.uv);
                // int terrainHole = SAMPLE_TEXTURE2D_LOD(_TerrainHoleMap, sampler_TerrainHoleMap, uv_TerrainHole, 0).r;
                // terrainHole = 1;
                // input.positionOS /= terrainHole;


                Varyings output;
                float2 uv = GetUV(x, y, input.uv);
                input.positionOS.y += SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, uv, 0).r * _MaxHeight;
                //直接得到世界坐标
                float3 positionWS = GetPositionWS(x, y) + input.positionOS.xyz;
                output.positionCS = TransformWorldToHClip(positionWS);
                // output.positionCS /= terrainHole;

                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = uv;
                output.positionWS = positionWS;
                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                // return half4(input.uv, 0, 1);
                // half4 var_MainTex = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, input.uv);
                // return var_MainTex;

                half3 mainColor = SAMPLE_TEXTURE2D(_AlbedoMap, sampler_AlbedoMap, input.uv);
                HMKSurfaceData surfaceData = InitSurfaceData(mainColor, 1, 0, 1, 1);
                HMKLightingData lightingData = InitLightingData(input.positionWS, input.normalWS);
                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                return half4(mainColor, 1);
            }
            
            ENDHLSL

        }


        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM

            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 positionWS: TEXCOORD2;
            };
            
            Varyings DepthOnlyVertex(Attributes input, uint instanceID: SV_InstanceID)
            {
                //全地图是一个20*20的
                // 根据instanceID 转为二维坐标 拿到对应的格子坐标
                int x = instanceID / TERRAIN_GRID_COUNT;
                int y = instanceID % TERRAIN_GRID_COUNT;
                
                
                //采样挖洞图
                // float2 uv_TerrainHole = GetTerrainHoleUV(x, y, input.uv);
                // int terrainHole = SAMPLE_TEXTURE2D_LOD(_TerrainHoleMap, sampler_TerrainHoleMap, uv_TerrainHole, 0).r;
                // input.positionOS /= terrainHole;


                Varyings output;
                float2 uv = GetUV(x, y, input.uv);
                input.positionOS.y += SAMPLE_TEXTURE2D_LOD(_HeightMap, sampler_HeightMap, uv, 0).r * _MaxHeight;
                //直接得到世界坐标
                float3 positionWS = GetPositionWS(x, y) + input.positionOS.xyz ;
                output.positionCS = TransformWorldToHClip(positionWS);
                // output.positionCS /= terrainHole;

                output.uv = uv;
                output.positionWS = positionWS;
                return output;
            }


            half4 DepthOnlyFragment(Varyings input): SV_Target
            {
                return 0;
            }
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
