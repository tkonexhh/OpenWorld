Shader "HMK/Scene/BlendTerrain"
{
    Properties
    {

        [Header(Base Properties)]
        [MainColor]_BaseColor ("ColorTint", color) = (1, 1, 1, 1)
        [SingleLine]_BaseMap ("DetailMap", 2D) = "white" { }
        [SingleLine]_BaseNormalPBRMap ("RG:法线 B:顶部遮罩 A:AO", 2D) = "bump" { }
        [SingleLine]_DetailNormalPBRMap ("DetailNormalPBRMap", 2D) = "bump" { }
        

        // _MetallicScale ("MetallicScale", range(0, 1)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 1)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 1)) = 1
        _DetailMapScale ("DetailMapScale", range(0, 100)) = 1
        // [Header(VertexBlend Properties)]
        // [Toggle(UseDetailBlend)]UseDetailBlend ("UseDetailBlend", Float) = 0
        // [Toggle(UseAlphaMask)] UseAlphaMask ("UseAlphaMask", Float) = 0
        // [Toggle(UseAlphaMaskAlbedo)] UseAlphaMaskAlbedo ("UseAlphaMaskAlbedo", Float) = 0
        // _BlendRangeMin ("BlendRangeMin", range(0, 1)) = 0
        // _BlendRangeMax ("BlendRangeMax", range(0, 1)) = 1
        // _BlendMapTiling ("BlendMapTiling", range(0.001, 100)) = 1

        [SingleLine]_BlendColorMap ("BlendBaseMap", 2D) = "white" { }
        [SingleLine]_BlendNormalMap ("BlendNormalMap", 2D) = "bump" { }

        // _BumpScale ("BumpScale", range(0, 10)) = 1.0
        
        // _PixelDepthOffset ("PixelDepthOffset", float) = 0

        // _MinMaxRange ("MinMaxRange", vector) = (0, 0, 0, 0)

    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

    CBUFFER_START(UnityPerMaterial)


    half4 _BaseColor, _BlendDepthColor, _BlendColor;
    half _MetallicScale, _RoughnessScale, _OcclusionScale, _DetailMapScale;


    CBUFFER_END

    sampler2D _BaseMap;
    TEXTURE2D(_BaseNormalPBRMap);SAMPLER(sampler_BaseNormalPBRMap);
    TEXTURE2D(_CameraTerrainColor);SAMPLER(sampler_CameraTerrainColor);


    sampler2D _BlendNormalMap;
    sampler2D _BlendColorMap;
    sampler2D _DetailNormalPBRMap;

    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry-100" }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Blend one zero
            ZWrite on
            Cull Back

            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            //#pragma multi_compile  _GIMAP_ON
            // #pragma shader_feature UseDetailBlend
            // #pragma shader_feature UseBlend
            // #pragma shader_feature UseAlphaMask
            // #pragma shader_feature UseAlphaMaskAlbedo
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag


            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Normal.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                #if defined(LIGHTMAP_ON)
                    float2 lightmapUV: TEXCOORD1;
                #endif
                half3 normalOS: NORMAL;
                half4 tangentOS: TANGENT;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD0;
                #if defined(LIGHTMAP_ON)
                    HMK_DECLARE_LIGHTMAP(lightmapUV, 1);
                #endif
                half3 normalWS: NORMAL;
                half3 tangentWS: TEXCOORD3;
                half3 bitangentWS: TEXCOORD4;

                // half ObjectScale: TEXCOORD6;
                float4 screenPos: TEXCOORD7;
                // float4 screenPosOffset: TEXCOORD8;


                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            float3 NormalReconstructZ_float(float2 In)
            {
                float reconstructZ = sqrt(1.0 - saturate(dot(In.xy, In.xy)));
                float3 normalVector = float3(In.x, In.y, reconstructZ);
                float3 Out = normalize(normalVector);
                return Out;
            }
            float3 NormalBlend_float(float3 A, float3 B)
            {
                float3 Out = SafeNormalize(float3(A.rg + B.rg, A.b * B.b));
                // float3 Out = normalize(A + B);
                return Out;
            }


            // float3 NormalFromHeight_Tangent_float(float In, float Strength, float3 Position, float3x3 TangentMatrix)
            // {
            //     float3 worldDerivativeX = ddx(Position);
            //     float3 worldDerivativeY = ddy(Position);

            //     float3 crossX = cross(TangentMatrix[2].xyz, worldDerivativeX);
            //     float3 crossY = cross(worldDerivativeY, TangentMatrix[2].xyz);
            //     float d = dot(worldDerivativeX, crossY);
            //     float sgn = d < 0.0 ?(-1.f): 1.f;
            //     float surface = sgn / max(0.00000000000001192093f, abs(d));

            //     float dHdx = ddx(In);
            //     float dHdy = ddy(In);
            //     float3 surfGrad = surface * (dHdx * crossY + dHdy * crossX);
            //     float3 Out = normalize(TangentMatrix[2].xyz - (Strength * surfGrad));
            //     Out = TransformWorldToTangent(Out, TangentMatrix);
            //     return Out;
            // }


            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = input.uv;

                // float3 cameraVec = normalize(_WorldSpaceCameraPos - output.positionWS);

                // float3 normalVS = mul((float3x3)UNITY_MATRIX_IT_MV, input.normalOS) ;
                // float2 ProjNormal = (mul((float2x2)UNITY_MATRIX_P, normalVS));
                output.normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));

                // float4 positionCsOffset=TransformObjectToHClip(input.positionOS.xyz+);

                output.screenPos = ComputeScreenPos(output.positionCS);

                // float4 positionCs = (output.positionCS);
                // positionCs.xy += ProjNormal * _MinMaxRange.w ;

                float3 tangentWS = TransformObjectToWorldDir(input.tangentOS);
                half tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
                float3 bitangentWS = cross(output.normalWS, tangentWS) * tangentSign;


                // output.screenPosOffset = ComputeScreenPos(positionCs);
                output.tangentWS = tangentWS;
                output.bitangentWS = bitangentWS;

                // float scale = length(float3(UNITY_MATRIX_M[0].x, UNITY_MATRIX_M[1].x, UNITY_MATRIX_M[2].x));
                // output.ObjectScale = scale;


                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                float2 uv = input.uv;

                half4 var_BaseNormalPBRMap = SAMPLE_TEXTURE2D(_BaseNormalPBRMap, sampler_BaseNormalPBRMap, uv);

                float3 BaseNormal = NormalReconstructZ_float(var_BaseNormalPBRMap.rg * 2 - 1);//Base normal
                // return half4(BaseNormal, 1);

                half roughness;
                half occlusion;
                half3 albedo;


                float2 uv_Top = input.positionWS.xy * 0.2;
                float2 uv_Left = input.positionWS.yz * 0.2;
                float2 uv_Right = input.positionWS.xz * 0.2;//

                half4 TopNormalBlendColor1 = tex2D(_BlendNormalMap, uv_Top);
                half4 TopNormalBlendColor2 = tex2D(_BlendNormalMap, uv_Left);
                half4 TopNormalBlendColor3 = tex2D(_BlendNormalMap, uv_Right);
                half4 TopNormalBlend = lerp(TopNormalBlendColor2, TopNormalBlendColor1, abs(input.normalWS.z));
                TopNormalBlend = lerp(TopNormalBlend, TopNormalBlendColor3, saturate(abs(input.normalWS.y)));

                float3 TopNormal = NormalReconstructZ_float(TopNormalBlend.rg * 2 - 1);//Grass Normal


                half4 normalBlendMap = TopNormalBlend;

                half4 ToplBlendColor1 = tex2D(_BlendColorMap, uv_Top);
                half4 ToplBlendColor2 = tex2D(_BlendColorMap, uv_Left);
                half4 ToplBlendColor3 = tex2D(_BlendColorMap, uv_Right);
                half4 ToplBlendColor = lerp(ToplBlendColor2, ToplBlendColor1, abs(input.normalWS.z));
                ToplBlendColor = lerp(ToplBlendColor, ToplBlendColor3, saturate(abs(input.normalWS.y)));
                float TopMask = var_BaseNormalPBRMap.b;

                half4 BaseMap = tex2D(_BaseMap, uv * _DetailMapScale);//细节颜色

                half4 DetailNormalPBRMap = tex2D(_DetailNormalPBRMap, uv * _DetailMapScale);

                float3 DetailNormal = NormalReconstructZ_float(DetailNormalPBRMap.rg * 2 - 1);//Detail  Normal

                float3 normalBlend = NormalBlend_float(DetailNormal, BaseNormal);

                normalBlend = lerp(normalBlend, TopNormal, TopMask);

                normalBlend = mul(normalBlend, float3x3(input.tangentWS, input.bitangentWS, input.normalWS));//final normal

                // return half4(normalBlend, 1);
                roughness = saturate(lerp(DetailNormalPBRMap.b, TopNormalBlend.b, TopMask) * _RoughnessScale);


                occlusion = min(var_BaseNormalPBRMap.a, (DetailNormalPBRMap.a));
                occlusion = lerp(occlusion, TopNormalBlend.a, TopMask);
                occlusion = LerpWhiteTo(occlusion, _OcclusionScale);


                albedo = (TopMask) * ToplBlendColor + (1 - TopMask) * BaseMap * _BaseColor ;


                HMKSurfaceData surfaceData = InitSurfaceData(albedo, 1, 0, roughness, occlusion, 0);
                HMKLightingData lightingData = InitLightingData(input.positionWS.xyz, normalBlend);
                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);

                // return half4(lightingData.normalWS, 1);

                // finalRGB = lerp(finalRGB, var_cameraTerrainColor, saturate(sceneZ * saturate(sceneZ)));
                return half4(finalRGB, 1);
            }

            ENDHLSL

        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            Cull back
            // Cull[_Cull] // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature_local_fragment _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Shadow.hlsl"

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            struct Attributes
            {
                float4 positionOS: POSITION;
                float3 normalOS: NORMAL;
                float2 texcoord: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float4 positionCS: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };




            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                output.uv = input.texcoord;
                output.positionCS = GetShadowPositionHClip(input.positionOS, input.normalOS);// + _ShadowOffset;
                return output;
            }

            half4 ShadowPassFragment(Varyings input): SV_TARGET
            {
                return 0;
            }

            ENDHLSL

        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" "Queue" = "1990" }

            ZWrite On
            ColorMask 0
            Cull Off
            HLSLPROGRAM

            #pragma target 4.5
            #pragma shader_feature UseBlend
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


            struct Attributes
            {
                float4 position: POSITION;
                // float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                // float2 uv: TEXCOORD0;
                float4 positionCS: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);


                output.positionCS = TransformObjectToHClip(input.position.xyz) ;
                // output.uv = input.uv;//TRANSFORM_TEX(input.texcoord, _BaseMap);

                return output;
            }

            half4 DepthOnlyFragment(Varyings input): SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                return 0;
            }

            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
