Shader "HMK/Scene/Sea"
{
    Properties
    {
        _Distortion ("Distortion", Range(0, 5)) = 2
        _FlowSpeed ("FlowSpeed", vector) = (0, 0, 0, 0)
        // _FlowSpeedY ("FlowSpeedY", Range(-10, 10)) = 0
        // [HideInInspector]_FoamColor ("FoamColor", Color) = (1, 1, 1, 1)
        [SingleLine]_FoamMap ("FoamMap", 2D) = "White" { }
        // [SingleLine]_FoamGrendientColor ("FoamGrendientColor ", 2D) = "White" { }
        [SingleLine]_CubeMap ("CubeMap ", cube) = "White" { }
        _FoamMapTiling ("FoamMapTiling", Range(0, 200)) = 1


        _NormalTiling ("NormalTiling", Range(0, 200)) = 0.5
        [SingleLine]_NormalMap ("NormalMap", 2D) = "bump" { }
        _normalScale ("NormalScale", float) = 1
        // _WaveSpeed ("FoamSpeed", Range(-5, 5)) = 1

        _BlendDepth ("BlendDepth", Range(0, 100)) = 1
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        [HDR] _BaseColorFar ("BaseColorFar", Color) = (1, 1, 1, 1)
        _CausticsColor ("CausticsColor", Color) = (1, 1, 1, 1)
        _CausticsTiling ("CausticsTiling", Range(0, 100)) = 10
        _CausticsSpeed ("CausticsSpeed", Float) = 1

        _SpecularExponent ("SpecularExp", vector) = (0, 0, 0, 0)
        _DepthOffset ("DepthOffset", vector) = (0, 0, 0, 1)
        // [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4

        // _UseRainnyNormal ("userainnyNormal", float) = 0
        _fresnelPow ("fresnelPow", float) = 1
        _fresnelBias ("fresnelBias", float) = 0
        _fresnelScale ("fresnelScale", float) = 1

        [SingleLine] _SSSLut ("SSSLut", 2D) = "white" { }
        _SubSurfaceSunFallOff ("SubSurfaceSunFallOff", float) = 1
        _SubSurfaceSun ("SubSurfaceSun", float) = 1
        _SubSurfaceBase ("SubSurfaceBase", float) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Geometry" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }
        LOD 300

        // ZTest [_ZTest]
        ZWrite Off

        Blend one OneMinusSrcAlpha

        Cull back

        Pass
        {
            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature UseHighlight
            // #pragma shader_feature UseRainnyNormal

            // Unity defined keywords
            // #pragma multi_compile_fog
            #pragma shader_feature _FOG_ON
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "./../HLSLIncludes/Common/Fog.hlsl"
            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            struct appdata
            {
                float4 positionOS: POSITION;
                float4 normal: NORMAL;
                float2 uv: TEXCOORD;
                float4 tangent: TANGENT;
            };

            struct v2f
            {
                float4 positionCS: SV_POSITION;
                float4 screenPos: TEXCOORD1;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD3;
                float3 normalWS: TEXCOORD4;
                half fogFactor: TEXCOORD5;
                float3 tangent: TEXCOORD6;
                float3 bitangent: TEXCOORD7;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _FlowSpeed;
            float _FlowSpeedX;
            float _FlowSpeedY;

            float4 _FoamMap_ST;

            float _Distortion;
            float _WaveSpeed;

            float _BlendDepth;
            half4 _BaseColor;
            half4 _FoamColor;
            half _NormalTiling;
            half _FoamColorFrequence;
            half4 _CausticsColor;
            half _CausticsSpeed;
            half _CausticsTiling;
            half _FoamFrequence;
            half _FoamDepth;
            half _FoamIntensity;
            half _FoamBlendDepth;
            half _FoamMapTiling;
            half4 _DepthOffset;
            half4 _SphereMaskPosition;
            half _RefAlpha;
            half4 _SpecularExponent;
            half _normalScale;

            half _fresnelBias, _fresnelPow, _fresnelScale;
            half4 _BaseColorFar;
            half _UseRainnyNormal;

            half _SubSurfaceSunFallOff;
            half _SubSurfaceBase, _SubSurfaceSun;
            CBUFFER_END
            SAMPLER(_CameraOpaqueTexture);

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            TEXTURE2D(_ReflectionTex);
            SAMPLER(sampler_ReflectionTex);


            TEXTURE2D(_FoamMap);
            SAMPLER(sampler_FoamMap);
            TEXTURECUBE(_CubeMap);
            SAMPLER(sampler_CubeMap);
            // TEXTURE2D(_FoamGrendientColor);
            // SAMPLER(sampler_FoamGrendientColor);
            TEXTURE2D(_SSSLut);
            SAMPLER(sampler_SSSLut);

            v2f vert(appdata v)
            {
                v2f output;
                output.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(v.positionOS);//   mul(unity_ObjectToWorld, v.vertex).xyz;
                output.screenPos = ComputeScreenPos(output.positionCS);
                output.uv = v.uv;
                output.normalWS = TransformObjectToWorldNormal(v.normal);
                half fogFactor = ComputeFogFactor(output.positionCS.z);

                output.fogFactor = fogFactor;


                output.tangent = TransformObjectToWorldDir(v.tangent.xyz);
                float vertexTangentSign = v.tangent.w * unity_WorldTransformParams.w;
                output.bitangent = cross(output.normalWS, output.tangent) * vertexTangentSign;

                return output;
            }
            float3 NormalFromHeight_World(float In, float Strength, float3 Position, float3x3 TangentMatrix)
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
                float3 Out = normalize(TangentMatrix[2].xyz - (Strength * surfGrad));
                return Out;
            }
            half3 Desaturation(float3 In, float Saturation)
            {
                float luma = dot(In, float3(0.2126729, 0.7151522, 0.0721750));
                return luma.xxx + Saturation.xxx * (In - luma.xxx);
            }

            //噪声图生成
            float2 rand(float2 st, int seed)
            {
                float2 s = float2(dot(st, float2(127.1, 311.7)) + seed, dot(st, float2(269.5, 183.3)) + seed);
                return -1 + 2 * frac(sin(s) * 43758.5453123);
            }


            half3 BlendNormals(half3 n1, half3 n2)
            {
                return normalize(half3(n1.xy * n2.z + n2.xy * n1.z, n1.z * n2.z));
            }



            float2 hash2(float2 p)//焦散

            {
                return frac(sin(float2(dot(p, float2(123.4, 748.6)), dot(p, float2(547.3, 659.3)))) * 5232.85324);
            }
            float hash(float2 p)//焦散

            {
                return frac(sin(dot(p, float2(43.232, 75.876))) * 4526.3257);
            }

            float voronoi_function(float2 p)//焦散

            {
                float2 n = floor(p);
                float2 f = frac(p);
                float md = 5.0;
                float2 m = 0;
                for (int i = -1; i <= 1; i++)
                {
                    for (int j = -1; j <= 1; j++)
                    {
                        float2 g = float2(i, j);
                        float2 o = hash2(n + g);
                        o = 0.5 + 0.5 * sin(_Time.y * _CausticsSpeed + 5.038 * o);
                        float2 r = g + o - f;
                        float d = dot(r, r);
                        if (d < md)
                        {
                            md = d;
                            m = n + g + o;
                        }
                    }
                }
                return md;
            }

            float ov(float2 p)//焦散

            {
                float v = 0.0;
                float a = 0.4;
                for (int i = 0; i < 2; i++)
                {
                    v += voronoi_function(p) * a;
                    p *= 1.8;
                    a *= 0.5;
                }
                return v;
            }
            float3 NormalReconstructZ(float2 In)
            {
                float reconstructZ = sqrt(1.0 - saturate(dot(In.xy, In.xy)));
                float3 normalVector = float3(In.x, In.y, reconstructZ);
                return normalize(normalVector);
            }
            float RandomRange_float(float2 Seed, float Min, float Max)
            {
                float randomno = frac(sin(dot(Seed, float2(12.9898, 78.233))) * 43758.5453);
                float Out = lerp(Min, Max, randomno);

                return Out;
            }
            float4 Unity_SampleGradient_float(Gradient Gradient, float Time)
            {
                float3 color = Gradient.colors[0].rgb;
                [unroll]
                for (int c = 1; c < 8; c++)
                {
                    float colorPos = saturate((frac(Time) - Gradient.colors[c - 1].w) / (Gradient.colors[c].w - Gradient.colors[c - 1].w)) * step(c, Gradient.colorsLength - 1);
                    color = lerp(color, Gradient.colors[c].rgb, lerp(colorPos, step(0.01, colorPos), Gradient.type));
                }
                #ifndef UNITY_COLORSPACE_GAMMA
                    color = SRGBToLinear(color);
                #endif
                float alpha = Gradient.alphas[0].x;
                [unroll]
                for (int a = 1; a < 8; a++)
                {
                    float alphaPos = saturate((frac(Time) - Gradient.alphas[a - 1].y) / (Gradient.alphas[a].y - Gradient.alphas[a - 1].y)) * step(a, Gradient.alphasLength - 1);
                    alpha = lerp(alpha, Gradient.alphas[a].x, lerp(alphaPos, step(0.01, alphaPos), Gradient.type));
                }
                float4 Out = float4(color, alpha);

                return Out;
            }
            real4 frag(v2f i): SV_Target
            {
                real4 col = 0;
                Light mainLight = GetMainLight();
                mainLight.color = clamp(Desaturate(mainLight.color, 0.9), 0.5, 1) ;
                mainLight.direction.xyz = normalize(_LightDir);
                half3 worldViewDir = _WorldSpaceCameraPos + half3(0, 10, 0) - i.positionWS;

                half normalizeFresnel = _fresnelScale + (1 - _fresnelScale) * pow(1 - dot(normalize(worldViewDir), normalize(i.normalWS)), _fresnelPow);
                normalizeFresnel = saturate(normalizeFresnel);

                half normalizeFresnelReflect = 0.02 + (1 - 0.02) * pow(1 - dot(normalize(worldViewDir), normalize(i.normalWS)), 10);
                normalizeFresnelReflect = saturate(normalizeFresnelReflect);
                float refractDis = -100;
                half normalizeFresnelRefrac = refractDis + (1 - refractDis) * pow(1 - dot(normalize(worldViewDir), normalize(i.normalWS)), 0.1);
                normalizeFresnelRefrac = saturate(normalizeFresnelRefrac);

                // half fresnel = 0.2 + saturate((1 - 0.2)) * pow(1 - dot(worldViewDir, i.normalWS), 1);
                //
                half reflectFact = reflect(worldViewDir, i.normalWS);

                half fresnel = pow((1 - max(0, dot(i.normalWS, normalize(worldViewDir)))), _fresnelBias) * 2;

                fresnel = saturate(fresnel);
                // half refractRatio = refract(worldViewDir, i.normalWS, _refractRatio);






                float3 worldTangent = i.tangent;
                float3 NormalWS = i.normalWS;
                float3 worldBitangent = i.bitangent;
                float3 tanToWorld0 = float3(worldTangent.x, worldBitangent.x, NormalWS.x);
                float3 tanToWorld1 = float3(worldTangent.y, worldBitangent.y, NormalWS.y);
                float3 tanToWorld2 = float3(worldTangent.z, worldBitangent.z, NormalWS.z);

                float distanceFadeFactor = saturate(i.positionCS.z * _ZBufferParams.z * 5) ;




                half2 uvPanner1 = (frac(_Time.y * _FlowSpeed.xy) + i.positionWS.xz / _NormalTiling);
                half2 uvPanner2 = (frac(_Time.y * _FlowSpeed.zw) + i.positionWS.xz / _NormalTiling * 0.5);

                float3 normalMap1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uvPanner1));
                float3 normalMap2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uvPanner2));

                half3 RainnyNormal = 0;
                float rippleShape = 0;

                if (_UseRainnyNormal != 0)
                {
                    Gradient _GradientColor = NewGradient(0, 3, 2, float4(1, 1, 1, 0.1906157), float4(0, 0, 0, 0.205803), float4(1, 1, 1, 0.2156542), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float2(1, 0), float2(1, 1), float2(0, 0), float2(0, 0), float2(0, 0), float2(0, 0), float2(0, 0), float2(0, 0));
                    float rippleTiling = 0.5;//_DepthOffset.w;
                    float2 randomMosaic = floor(i.positionWS.xz / rippleTiling);
                    float randomMosaic1 = RandomRange_float(randomMosaic, 0.3, 0.7);

                    float randomMosaic2 = RandomRange_float(randomMosaic + 1, 0.3, 0.7);

                    float2 randomMosaicCombine = float2(randomMosaic1, randomMosaic2);



                    float2 rippleMask = frac(i.positionWS.xz / rippleTiling);


                    rippleShape = distance(0.5, rippleMask) * randomMosaicCombine;


                    float randomFlowMask = frac(_Time.y) * 3;
                    float randomRippleMask2 = RandomRange_float(randomMosaic + 2, 0, 1);
                    float randomRippleMask = 1 - frac(RandomRange_float(randomMosaic + 2, 0, 1) + randomFlowMask);

                    rippleShape += randomRippleMask;

                    float4 rippleShapeColor = 0;
                    rippleShape = 1 - Unity_SampleGradient_float(_GradientColor, rippleShape);
                    rippleShape = min(rippleShape, pow(randomMosaic2, 2)) * step(distance(0.5, rippleMask), 0.5);
                }
                half3 worldNormal = BlendNormals(normalMap1, normalMap2);

                half3 specularNormal = worldNormal;
                _normalScale = lerp(_normalScale, 0, normalizeFresnel);
                worldNormal = lerp(normalize(half3(0, 0, 1)), worldNormal, _normalScale);




                float3 swelledNormal = float3(dot(tanToWorld0, worldNormal), dot(tanToWorld1, worldNormal), dot(tanToWorld2, worldNormal));
                float3 specularNormalDis = float3(dot(tanToWorld0, specularNormal), dot(tanToWorld1, specularNormal), dot(tanToWorld2, specularNormal));
                // swelledNormal = max(swelledNormal, RainnyNormal);
                // return float4(distanceFadeFactor.rrr, 1);

                float2 screenUV = i.screenPos.xy / i.screenPos.w;

                screenUV = float2((i.screenPos.x + swelledNormal.r * _Distortion * 100), i.screenPos.y) / i.screenPos.w;
                float2 screenUVRefrac = screenUV;// float2((i.screenPos.x + swelledNormal.r * _Distortion * 100), i.screenPos.y) / i.screenPos.w;


                float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);

                half pixelDepth = saturate(abs(i.positionCS.z - i.screenPos.w) / 500);

                // return float4(pixelDepth.rrr, 1);

                half2 sssUv = saturate(half2(pow(pixelDepth, 0.45), pixelDepth));


                half3 SSSColor = SAMPLE_TEXTURE2D(_SSSLut, sampler_SSSLut, sssUv);

                SSSColor = pow(SSSColor, 2.2);
                // return float4(SSSColor, 1);




                float3 reflDir = reflect(-worldViewDir, swelledNormal);

                half4 EnvReflectColor = SAMPLE_TEXTURECUBE(_CubeMap, sampler_CubeMap, reflDir);
                // half4 EnvReflectColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflDir, 0);

                // half3 RefracColor = DecodeHDREnvironment(EnvReflectColor, unity_SpecCube0_HDR);

                float4 reflectionColor = float4(EnvReflectColor.rgb, 1);
                // float4 reflectionColor = float4(EnvReflectColor.rgb, 1);
                // return reflectionColor;

                // float relectFresnel = smoothstep(_SpecularExponent.w, 1, saturate((worldViewDir.g - 7) / 2));
                // reflectionColor.rgb = Desaturate(reflectionColor.rgb, 1);

                float4 ndcPos = (i.screenPos / i.screenPos.w) * 2 - 1;
                float3 clipVec = float3(ndcPos.x, ndcPos.y, 1.0) * _ProjectionParams.z;
                float3 viewVec = mul(unity_CameraInvProjection, clipVec.xyzz).xyz;
                float sceneZ1 = Linear01Depth(sceneZ, _ZBufferParams);
                float3 viewPos = sceneZ1 * viewVec;
                float3 worldPos = mul(UNITY_MATRIX_I_V, float4(viewPos, 1.0)).xyz;//深度重构世界坐标
                sceneZ = LinearEyeDepth(sceneZ, _ZBufferParams) ;
                // float4 screenPosNorm = (i.screenPos / i.screenPos.w);
                // screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ?  screenPosNorm.z: screenPosNorm.z * 0.5 + 0.5;
                float depth = saturate(smoothstep(_DepthOffset.x, _DepthOffset.y, saturate(worldPos.y - _DepthOffset.z))) ;

                half CausticsDepth = 1 - saturate(smoothstep(_DepthOffset.x, _DepthOffset.y, saturate(worldPos.y - _DepthOffset.z + 6))) ;

                half FoamDepth = 1 - saturate(smoothstep(_DepthOffset.x, _DepthOffset.y, saturate(worldPos.y - _DepthOffset.z + 5))) ;
                float screenDepth = sceneZ ;
                // float distanceDepth = abs((screenDepth - LinearEyeDepth(screenPosNorm.z, _ZBufferParams)) / (_BlendDepth));
                // return float4(FoamDepth.rrr, 1);

                half DepthMask = (sceneZ - i.screenPos.w) ;


                half DepthMask2 = smoothstep(0, 0.5, DepthMask);//g

                DepthMask = smoothstep(0.5, 1, DepthMask);


                float foamMask = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, worldPos.xz / _FoamMapTiling - float2(_Time.y * 0.1, swelledNormal.g * 0.2)).r ;


                //foam


                // float cameraLength = length(_WorldSpaceCameraPos - i.positionWS);

                // cameraLength = smoothstep(0.5, 1, saturate(cameraLength / 20));
                // return float4(cameraLength.rrr, 1);
                // float foamGrendient = SAMPLE_TEXTURE2D(_FoamGrendientColor, sampler_FoamGrendientColor, float2(distanceDepth + frac(_Time.x * 4), 0)).r * saturate(1 - DepthMask2 - 0.2) * DepthMask2;// * smoothstep(saturate(0.3 - DepthMask), 0, 0.1);

                // float foamColor = (1 - saturate(sin(((sceneZ - i.screenPos.w) + _Time.x * 3) * _BlendDepth) * 1.5)) * (1 - DepthMask2 - 0.2) * DepthMask2 * 5 * FoamDepth * mainLight.color * foamMask;

                float foamDiff = saturate((sceneZ - i.screenPos.w)) + foamMask * 0.2 ;
                float foam = (foamDiff - (saturate(sin((foamDiff + _Time.y * 0.1) * _BlendDepth)) * (1.0 - foamDiff)) + foamMask) * (1 - DepthMask2) * DepthMask2 * 20 * FoamDepth * mainLight.color;// * foamMask;//* clamp(foamMask, 0.3, 1); // 1-foamDiff 为了让中间是空的和一些噪点
                float foamColor = saturate(foam);
                // return float4(foamColor.rrr, 1);







                //反射

                // float4 reflection = SAMPLE_TEXTURECUBE(_ReflectionTex, sampler_ReflectionTex, float2((i.screenPos.x + swelledNormal.r * _Distortion * 2000), i.screenPos.y) / i.screenPos.w);

                // reflection = lerp(reflection * _BaseColor, reflection * _BaseColorFar, normalizeFresnelReflect);



                // reflection.rgb = lerp(reflection.rgb, reflectionColor.rgb, relectFresnel)  ;





                // float4 reflectionMix = lerp(reflection, reflectionColor, relectFresnel);

                // reflectionMix = lerp(reflectionMix * _BaseColor, reflectionMix * _BaseColorFar, normalizeFresnelReflect);

                float4 reflectionMix = reflectionColor * half4(SSSColor, 1);


                reflectionMix = lerp(reflectionMix * _BaseColor, reflectionMix * _BaseColorFar, normalizeFresnelReflect) * half4(mainLight.color, 1);



                float4 colrefrac = tex2D(_CameraOpaqueTexture, screenUVRefrac);






                // return float4(1 - CausticsDepth.rrr, 1);


                float3 Caustics = float(smoothstep(0, 0.5, ov(worldPos.xz * _CausticsTiling / 100))) * mainLight.color * CausticsDepth / 2;

                float3 color = (reflectionMix.rgb + Caustics * (1 - saturate(sceneZ / 50))) + rippleShape ;// lerp(_BaseColor * mainLight.color, reflectionMix.rgb, saturate(normalizeFresnel)) * saturate(2 - depth);




                half3 specularLighting = 0;

                if (_UseRainnyNormal == 0)
                {
                    half3 halfDir = normalize(mainLight.direction + normalize(worldViewDir)) ;
                    specularLighting = _SpecularExponent.x * pow(max(0, dot(halfDir, specularNormalDis)), _SpecularExponent.y);
                    float perceptualRoughness = 1 - _SpecularExponent.y;
                    float roughness = perceptualRoughness * perceptualRoughness;
                    float squareRoughness = roughness * roughness;
                    float nh = max(saturate(dot(specularNormalDis, halfDir)), 0.000001);
                    float nl = max(saturate(dot(specularNormalDis, mainLight.direction.xyz)), 0.000001);
                    float nv = max(saturate(dot(specularNormalDis, normalize(worldViewDir))), 0.000001);
                    float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);
                    float D = lerpSquareRoughness / (pow((pow(nh, 2) * (lerpSquareRoughness - 1) + 1), 2) * 3.1416);
                    float kInDirectLight = pow(squareRoughness + 1, 2) / 8;
                    float kInIBL = pow(squareRoughness, 2) / 8;
                    float GLeft = nl / lerp(nl, 1, kInDirectLight);
                    float GRight = nv / lerp(nv, 1, kInDirectLight);
                    float G = GLeft * GRight;
                    float vh = max(saturate(dot(halfDir, worldViewDir)), 0.000001);
                    float3 F0 = reflectionColor.rgb;
                    float3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);
                    float spec = D * G * F / (nv * nl * 4);
                    specularLighting = spec * _SpecularExponent.x * mainLight.color.rgb;
                    specularLighting = half4(specularLighting * _SpecularExponent.z, 1);
                }



                color += specularLighting ;

                float RefracDepth = saturate(depth) ;


                half fresnelDepth = worldPos.y - _DepthOffset.z + 30 ;
                fresnelDepth = saturate(smoothstep(0, 30, fresnelDepth));

                fresnelDepth = saturate(1 - lerp(0, fresnelDepth, fresnelDepth));

                fresnelDepth = lerp(fresnelDepth, 1, saturate(pixelDepth));


                float refractMask = lerp(fresnelDepth, RefracDepth, fresnel);

                refractMask = saturate(refractMask * 2) * DepthMask;




                color = lerp(colrefrac.rgb, color, refractMask) + saturate(foamColor)    ;


                #if _FOG_ON
                    color.rgb = ApplyFog(color.rgb, i.positionWS);
                    // col.rgb = MixFog(col.rgb, i.fogFactor);
                    // return half4(i.positionWS, 1);
                #endif
                return float4(color.rgb, 1);







                return float4(col.rgb, 1);
            }

            ENDHLSL

        }
    }
}
