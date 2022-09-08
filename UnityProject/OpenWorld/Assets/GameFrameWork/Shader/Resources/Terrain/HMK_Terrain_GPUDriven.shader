Shader "HMK/Terrain/GPUDriven"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _UVScale ("UV Scale", Range(0, 1)) = 0.2
        [NoScaleOffset]_HeightMap ("Texture", 2D) = "white" { }
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "IgnoreProjector" = "True" "UniversalMaterialType" = "Lit" }
        LOD 100
        Pass
        {
            // Name "TerrainForward"
            Tags { "LightMode" = "UniversalForward" "Queue" = "Geometry" }
            ZWrite On
            Cull Back

            HLSLPROGRAM

            //Keywords
            #pragma shader_feature ENABLE_LOD_DEBUG
            #pragma shader_feature ENABLE_PATCH_DEBUG
            #pragma shader_feature ENABLE_NODE_DEBUG


            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "./../ComputeShader/Terrain/TerrainInput.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            uniform float3 _WorldSize;//世界大小
            float _UVScale;
            CBUFFER_END
            
            
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            sampler2D _HeightMap;

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                uint instanceID: SV_InstanceID;
                float3 normalOS: NORMAL;
            };

            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD3;
                float4 color: TEXCOORD1;
                float height: TEXCOORD2;
                float normalWS: NORMAL;
            };

            

            StructuredBuffer<RenderPatch> PatchList;//这个StructuredBuffer在大部分手机上都不支持 但是要切到Vulkan

            #if ENABLE_LOD_DEBUG
                //用于Mipmap的调试颜色
                static half3 debugColorForMip[6] = {
                    half3(0, 1, 0),
                    half3(0, 0, 1),
                    half3(1, 0, 0),
                    half3(1, 1, 0),
                    half3(0, 1, 1),
                    half3(1, 0, 1),
                };
            #endif
            
            #if ENABLE_NODE_DEBUG
                //在Node之间留出缝隙供Debug
                float3 ApplyNodeDebug(RenderPatch patch, float3 vertex)
                {
                    uint nodeCount = (uint) (5 * pow(2, 5 - patch.lod));
                    float nodeSize = _WorldSize.x / nodeCount;
                    uint2 nodeLoc = floor((patch.position + _WorldSize.xz * 0.5) / nodeSize);
                    float2 nodeCenterPosition = -_WorldSize.xz * 0.5 + (nodeLoc + 0.5) * nodeSize ;
                    vertex.xz = nodeCenterPosition + (vertex.xz - nodeCenterPosition) * 0.95;
                    return vertex;
                }
            #endif
            
            //LOD 相差两级以上 目前会有问题
            //修复接缝
            void FixLODConnectSeam(inout float4 vertex, inout float2 uv, RenderPatch patch)
            {

                uint4 lodTrans = patch.lodTrans;//四个方向上的差值
                //模型空间坐标原先范围是(-PATCH_MESH_SIZE * 0.5,PATCH_MESH_SIZE * 0.5) 先转到(0,PATCH_MESH_SIZE)之间
                //然后再 /PATCH_MESH_GRID_SIZE 得到是顶点坐标顺序 vertexIndex 范围是0-16
                uint2 vertexIndex = floor((vertex.xz + PATCH_MESH_SIZE * 0.5 + 0.01) / PATCH_MESH_GRID_SIZE);

                float uvGridStrip = 1.0 / PATCH_MESH_GRID_COUNT;//单位Grid的UV值

                uint lodDelta = lodTrans.x;//处理左侧接缝
                //如果是最左边的点 并且只处理Lod上升的情况 避免多次执行
                if (lodDelta > 0 && vertexIndex.x == 0)
                {
                    uint gridStripCount = pow(2, lodDelta);//间隔的不需要处理的顶点
                    uint modIndex = vertexIndex.y % gridStripCount;//如果不是需要处理的顶点
                    if (modIndex != 0)
                    {
                        vertex.z -= PATCH_MESH_GRID_SIZE * modIndex;//下移到下方 那个不需要处理的定点位置
                        uv.y -= uvGridStrip * modIndex;//同时改变UV
                        return;
                    }
                }

                lodDelta = lodTrans.y;//处理下侧接缝
                //如果是最下边的点
                if (lodDelta > 0 && vertexIndex.y == 0)
                {
                    uint gridStripCount = pow(2, lodDelta);
                    uint modIndex = vertexIndex.x % gridStripCount ;
                    if (modIndex != 0)
                    {
                        vertex.x -= PATCH_MESH_GRID_SIZE * modIndex;
                        uv.x -= uvGridStrip * modIndex;
                        return;
                    }
                }

                lodDelta = lodTrans.z;//处理右侧接缝
                //如果是最右侧的点
                if (lodDelta > 0 && vertexIndex.x == PATCH_MESH_GRID_COUNT)
                {
                    uint gridStripCount = pow(2, lodDelta);
                    uint modIndex = vertexIndex.y % gridStripCount;
                    if (modIndex != 0)
                    {
                        vertex.z += PATCH_MESH_GRID_SIZE * (gridStripCount - modIndex);
                        uv.y += uvGridStrip * (gridStripCount - modIndex);
                        return;
                    }
                }

                lodDelta = lodTrans.w;//处理上侧接缝
                //如果是最上侧的点
                if (lodDelta > 0 && vertexIndex.y == PATCH_MESH_GRID_COUNT)
                {
                    uint gridStripCount = pow(2, lodDelta);
                    uint modIndex = vertexIndex.x % gridStripCount;
                    if (modIndex != 0)
                    {
                        vertex.x += PATCH_MESH_GRID_SIZE * (gridStripCount - modIndex);
                        uv.x += uvGridStrip * (gridStripCount - modIndex);
                        return;
                    }
                }
            }

            // HMKLightingData InitLightingData(Varyings input)
            // {
            //     HMKLightingData lightingData;
            //     lightingData.normalWS = saturate(input.normalWS);
            //     // lightingData.positionWS = input.positionWS;
            //     lightingData.viewDirWS = GetWorldSpaceViewDir(input.positionWS);//  SafeNormalize(GetCameraPositionWS() - lightingData.positionWS);
            //     return lightingData;
            // }


            Varyings vert(appdata v)
            {
                Varyings output;
                float4 inVertex = v.vertex;
                RenderPatch patch = PatchList[v.instanceID];
                FixLODConnectSeam(inVertex, v.uv, patch);//修复接缝

                uint lod = patch.lod;
                float scale = pow(2, lod);
                inVertex.xz *= scale;

                #if ENABLE_PATCH_DEBUG
                    inVertex.xz *= 0.9;
                #endif

                inVertex.xz += patch.position;

                #if ENABLE_NODE_DEBUG
                    inVertex.xyz = ApplyNodeDebug(patch, inVertex.xyz);
                #endif

                //这里的UV是如何处理的？
                float2 heightUV = (inVertex.xz + (_WorldSize.xz * 0.5) + 0.5) / (_WorldSize.xz + 1);
                float height = tex2Dlod(_HeightMap, float4(heightUV, 0, 0)).r;
                output.height = height;
                inVertex.y = height * _WorldSize.y;
                
                output.positionCS = TransformObjectToHClip(inVertex.xyz);
                output.positionWS = TransformObjectToWorld(inVertex.xyz);
                output.uv = v.uv * scale * PATCH_COUNT_PER_NODE;//*8是为什么
                output.color = height;
                output.normalWS = TransformObjectToWorldNormal(v.normalOS);

                #if ENABLE_LOD_DEBUG
                    uint4 lodColorIndex = lod + patch.lodTrans;
                    output.color.xyz *= (debugColorForMip[lodColorIndex.x] +
                    debugColorForMip[lodColorIndex.y] +
                    debugColorForMip[lodColorIndex.z] +
                    debugColorForMip[lodColorIndex.w]) * 0.25;
                #endif
                

                return output;
            }
            

            half4 frag(Varyings input): SV_Target
            {
                #if ENABLE_LOD_DEBUG
                    return input.color;
                #endif
                
                float3 positionWS = input.positionWS;
                float3 normalWS = normalize(input.normalWS);
                float2 uv_Tex = positionWS.xz * _UVScale;
                half4 var_main = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_Tex);

                //ControlMap RGBA

                HMKSurfaceData surfaceData;
                surfaceData.albedo = var_main.rgb;
                surfaceData.alpha = 1;
                surfaceData.metallic = 0;
                surfaceData.roughness = 0;
                surfaceData.occlusion = 1;
                surfaceData.emission = 0;

                HMKLightingData lighingtData = InitLightingData(positionWS, normalWS);

                // Light mainLight = GetMainLight();
                half3 finalRGB = ShadeAllLightPBR(surfaceData, lighingtData);
                return half4(finalRGB, 1);
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

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
            ENDHLSL

        }
    }
}
