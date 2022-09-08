Shader "HMK/Scene/Leaves_PBR"
{
    Properties
    {
        [Header(Option)]
        [Toggle(_ALPHATEST_ON)] _AlphaClip ("__clip", Float) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)]  _Cull ("__Cull", float) = 2.0


        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Header(Base Color)]
        [MainColor]_BaseColor ("固有色", color) = (1, 1, 1, 1)
        [NoScaleOffset] _BaseMap ("BaseMap", 2D) = "white" { }
        [NoScaleOffset]_NormalPBRMap ("RG:法线 B:粗糙度 A:AO", 2D) = "bump" { }
        _BumpScale ("Bump Scale", range(0, 3)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 3)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 3)) = 1



        [Header(Wind)]

        _WindSpeed ("WindSpeed", Range(0, 10)) = 0
        _WindIntensity ("WindIntensity", Range(0, 1)) = 1
        _PixelRange ("PixelRange", float) = 1024
        _SelfSpeed ("SelfSpeed ", float) = 0
        _WindStrengthScale ("WindStrengthScale", float) = 0.001
        _RotateOffset ("RotateOffset", range(-10, 10)) = 0
        _Uv2Offset ("Uv2Offset", range(-1, 1)) = 0
        _Alpha ("Alpha", float) = 1
    }

    HLSLINCLUDE

    #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
    #include "./Hidden/Wind.hlsl"
    #include "./../HLSLIncludes/Common/HMK_Dither.hlsl"


    CBUFFER_START(UnityPerMaterial)
    half4 _BaseColor;
    half _BumpScale;
    half _RoughnessScale, _OcclusionScale;
    half _Cutoff;
    half3 _EmissionColor;
    half _WindSpeed;
    half _WindIntensity;
    half _PixelRange;
    half _SelfSpeed;
    half _WindStrengthScale;
    half _Uv2Offset;
    half _Alpha;
    half _RotateOffset;
    CBUFFER_END

    float3 RotateAroundAxis(float3 center, float3 original, float3 u, float angle)
    {
        original -= center;
        float C = cos(angle);
        float S = sin(angle);
        float t = 1 - C;
        float m00 = t * u.x * u.x + C;
        float m01 = t * u.x * u.y - S * u.z;
        float m02 = t * u.x * u.z + S * u.y;
        float m10 = t * u.x * u.y + S * u.z;
        float m11 = t * u.y * u.y + C;
        float m12 = t * u.y * u.z - S * u.x;
        float m20 = t * u.x * u.z - S * u.y;
        float m21 = t * u.y * u.z + S * u.x;
        float m22 = t * u.z * u.z + C;
        float3x3 finalMatrix = float3x3(m00, m01, m02, m10, m11, m12, m20, m21, m22);
        return mul(finalMatrix, original) + center;
    }


    float3 GetWindOffSet(float3 positionOS)
    {


        float3 normalizedDirection = float3(1, 0, 0);//normalize(_WindDirection);
        float3 windFiled = (normalizedDirection * (-0.5 * (LeavesPRBOffset * _SelfSpeed)));
        float3 worldPos = TransformObjectToWorld(positionOS).xyz;

        float3 offsetDirection = abs(sin(windFiled + (worldPos / _PixelRange)));

        float angle = dot(normalizedDirection, offsetDirection) * offsetDirection;

        float3 angleDir = abs(sin(windFiled + worldPos / (_PixelRange * 5.0)));

        float3 u = cross(normalizedDirection, float3(0, 1, 0));
        float dis = distance(angleDir * angleDir, 0);
        float3 rotatedValue40_g11 = RotateAroundAxis(float3(0, _RotateOffset, 0), 0, u, angle + dis);
        float3 vertexValue = (((rotatedValue40_g11 * 1.0) * (_WindIntensity + _WindStrength * _WindStrengthScale)));

        return vertexValue;
    }



    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            Cull[_Cull]
            ZWrite On
            HLSLPROGRAM

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile_fog
            #pragma shader_feature _FOG_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON

            #pragma vertex vert
            #pragma fragment frag




            #include "./../HLSLIncludes/Common/HMK_Normal.hlsl"
            #include "./../HLSLIncludes/Common/Fog.hlsl"



            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalPBRMap);SAMPLER(sampler_NormalPBRMap);

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;

                float2 uv2: TEXCOORD1;
                #if defined(LIGHTMAP_ON)
                    float2 lightmapUV: TEXCOORD2;
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
                float2 uv2: TEXCOORD1;
                #if defined(LIGHTMAP_ON)
                    HMK_DECLARE_LIGHTMAP(lightmapUV, 7);
                #endif
                half3 normalWS: NORMAL;
                half3 tangentWS: TEXCOORD3;
                half3 bitangentWS: TEXCOORD4;
                half fogFactor: TEXCOORD5;
                float4 screenPos: TEXCOORD6;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            HMKLightingData InitLightingData(Varyings input, float2 normalXY)
            {
                //采样法线贴图
                float3 normalTS;
                NormalReconstructZ(normalXY, normalTS);

                // half3 normalTS = UnpackNormalScale(var_NormalMap, _BumpScale);
                half3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                float3 normalWS = TransformTangentToWorld(normalTS, TBN) ;
                #if defined(LIGHTMAP_ON)
                    return InitLightingData(input.positionWS, normalWS, input.lightmapUV);
                #else
                    return InitLightingData(input.positionWS, normalWS);
                #endif
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);



                output.uv = input.uv;
                input.uv2.y = saturate(input.uv2.y - _Uv2Offset);
                half3 PivotPoint = 0;
                float3 windDir = normalize(_WindDirection);
                float offsetAngle = sin(LeavesPRBOffset * _WindSpeed) * (_WindIntensity + _WindStrength * _WindStrengthScale) * input.uv2.y;
                // float offsetAngle = sin(_Time.y * _WindSpeed * _WindStrength) * _WindIntensity * input.uv2.y  ;

                float3 vertexPsitionRotate = RotateAroundAxis(PivotPoint, input.positionOS.xyz, windDir, offsetAngle);

                float3 vertexnormalRotate = RotateAroundAxis(PivotPoint, input.normalOS, windDir, offsetAngle);

                input.positionOS.xyz = vertexPsitionRotate;

                input.normalOS.xyz = vertexnormalRotate;

                float3 normalWS = normalize(TransformObjectToWorldNormal(input.normalOS));
                float3 tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
                half tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
                float3 bitangentWS = cross(normalWS, tangentWS) * tangentSign;






                output.positionWS = TransformObjectToWorld(input.positionOS.xyz) ;

                half TrunkMask = step(0.5, input.uv2.x);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz + GetWindOffSet(input.positionOS) * input.uv2.y * TrunkMask);



                // output.positionCS.xyz += ;
                output.screenPos = ComputeScreenPos(output.positionCS);
                output.normalWS = normalWS;
                output.tangentWS = tangentWS;
                output.uv2 = input.uv2;
                output.bitangentWS = bitangentWS;
                #if defined(LIGHTMAP_ON)
                    HMK_OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                #endif
                return output;
            }


            half4 frag(Varyings input): SV_Target
            {


                // return saturate(input.uv2.y);
                float2 uv = input.uv;
                half4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);



                half4 var_NormalPBRMap = SAMPLE_TEXTURE2D(_NormalPBRMap, sampler_NormalPBRMap, uv);

                float2 normalXY = (var_NormalPBRMap.rg);
                normalXY = normalXY * 2 - 1;
                half roughness = var_NormalPBRMap.b;
                half occlusion = var_NormalPBRMap.a;


                half3 albedo = var_BaseMap.rgb * _BaseColor.rgb;
                half alpha = var_BaseMap.a;
                half metallic = 0;
                occlusion = LerpWhiteTo(occlusion, _OcclusionScale);
                roughness = roughness * _RoughnessScale;
                HMKSurfaceData surfaceData = InitSurfaceData(albedo, alpha, metallic, roughness, occlusion);
                #if defined(_ALPHATEST_ON)
                    clip(surfaceData.alpha - _Cutoff);
                #endif
                float cameraLength = pow(saturate(length(_WorldSpaceCameraPos - input.positionWS) / _Alpha), 2);

                float dither = DitherOutputSS(input.screenPos);

                half TrunkMask = step(0.5, input.uv2.x);

                TrunkMask = lerp(1, cameraLength, TrunkMask);
                dither = step(dither, TrunkMask);





                clip(dither - _Cutoff);
                HMKLightingData lightingData = InitLightingData(input, normalXY);

                half3 finalRGB = ShadeAllLightPBR(surfaceData, lightingData);
                // finalRGB = ApplyFog(finalRGB, input.positionWS);
                return half4(finalRGB, surfaceData.alpha);
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
            Cull[_Cull] // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

            HLSLPROGRAM

            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);


            struct Attributes
            {
                float4 positionOS: POSITION;
                float3 normalOS: NORMAL;
                float2 texcoord: TEXCOORD0;
                float2 texcoord1: TEXCOORD1;
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

                output.uv = input.texcoord;//TRANSFORM_TEX(input.texcoord, _BaseMap);
                // input.positionOS.xyz += GetWindOffSet(input.positionOS);
                input.texcoord1.y = saturate(input.texcoord1.y - _Uv2Offset);

                half3 PivotPoint = 0;
                float3 windDir = normalize(_WindDirection);
                float offsetAngle = sin(LeavesPRBOffset * _WindSpeed) * (_WindIntensity + _WindStrength * _WindStrengthScale) * input.texcoord1.y;
                // float offsetAngle = sin(_Time.y * _WindSpeed * _WindStrength) * _WindIntensity * input.uv2.y  ;

                float3 vertexPsitionRotate = RotateAroundAxis(PivotPoint, input.positionOS.xyz, windDir, offsetAngle);

                float3 vertexnormalRotate = RotateAroundAxis(PivotPoint, input.normalOS, windDir, offsetAngle);

                input.positionOS.xyz = vertexPsitionRotate;

                input.normalOS.xyz = vertexnormalRotate;

                // output.positionCS = GetShadowPositionHClip(input.positionOS.xyz, input.normalOS);
                half TrunkMask = step(0.5, input.texcoord1.x);
                // output.positionCS.xyz += GetWindOffSet(input.positionOS) * input.texcoord1.y * TrunkMask;

                output.positionCS = GetShadowPositionHClip(input.positionOS.xyz, input.normalOS);
                return output;
            }




            half4 ShadowPassFragment(Varyings input): SV_TARGET
            {
                #if defined(_ALPHATEST_ON)
                    half4 var_Base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                    half alpha = var_Base.a;
                    clip(alpha - _Cutoff);
                #endif



                return 0;
            }


            ENDHLSL

        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            // Stencil
            // {
            //     Ref   2
            //     ReadMask 255
            //     WriteMask 255
            //     Comp Always
            //     pass replace
            //     Fail replace
            //     ZFail Keep
            //     //replace

            // }
            ZWrite On
            ColorMask 0
            Cull off
            HLSLPROGRAM

            // Required to compile gles 2.0 with standard srp library
            // #pragma prefer_hlslcc gles
            // #pragma exclude_renderers d3d11_9x
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);


            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 texcoord: TEXCOORD0;
                float2 texcoord1: TEXCOORD1;
                float3 normal: NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv: TEXCOORD0;

                float4 positionCS: SV_POSITION;

                float3 positionWS: TEXCOORD1;
                float4 screenPos: TEXCOORD2;

                float2 uv2: TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);

                output.uv = input.texcoord;
                input.texcoord1.y = saturate(input.texcoord1.y - _Uv2Offset);
                half3 PivotPoint = 0;
                float3 windDir = normalize(_WindDirection);
                float offsetAngle = sin(LeavesPRBOffset * _WindSpeed) * (_WindIntensity + _WindStrength * _WindStrengthScale) * input.texcoord1.y;
                // float offsetAngle = sin(_Time.y * _WindSpeed * _WindStrength) * _WindIntensity * input.uv2.y  ;

                float3 vertexPsitionRotate = RotateAroundAxis(PivotPoint, input.positionOS.xyz, windDir, offsetAngle);

                float3 vertexnormalRotate = RotateAroundAxis(PivotPoint, input.normal, windDir, offsetAngle);

                input.positionOS.xyz = vertexPsitionRotate;

                input.normal.xyz = vertexnormalRotate;

                output.uv2 = input.texcoord1.xy;
                half TrunkMask = step(0.5, input.texcoord1.x);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz + GetWindOffSet(input.positionOS) * input.texcoord1.y * TrunkMask);
                // output.positionCS.xyz += GetWindOffSet(input.positionOS) * input.texcoord1.y * TrunkMask;

                output.screenPos = ComputeScreenPos(output.positionCS);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                // output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input): SV_TARGET
            {

                float cameraLength = pow(saturate(length(_WorldSpaceCameraPos - input.positionWS) / _Alpha), 2);


                float dither = DitherOutputSS(input.screenPos);

                half TrunkMask = step(0.5, input.uv2.x);

                TrunkMask = lerp(1, cameraLength, TrunkMask);
                dither = step(dither, TrunkMask);





                #if defined(_ALPHATEST_ON)
                    half4 var_Base = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                    half alpha = var_Base.a;
                    clip(alpha - _Cutoff);
                #endif
                clip(dither - _Cutoff);
                return 0;
            }

            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
