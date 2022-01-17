Shader "HMK/Scene/Sea"
{
    Properties
    {
        _Distortion ("Distortion", Range(0, 5)) = 2
        _FlowSpeed ("FlowSpeed", Range(-5, 5)) = 1
        [HideInInspector]_FoamColor ("FoamColor", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_FoamMap ("FoamMap", 2D) = "White" { }
        _FoamMapTiling ("FoammapTiling", Range(0, 10)) = 8
        // _FoamColorFrequence ("FoamColorFrequence", Float) = 1
        _FoamFrequence ("FoamFrequence", Range(1, 100)) = 8
        [HideInInspector]_FoamDepth ("FoamDepth", Range(0, 1)) = 1
        [HideInInspector]_FoamBlendDepth ("FoamBlendDepth", Range(0, 1)) = 1
        [HideInInspector]_FoamIntensity ("FoamIntensity", Range(0, 1)) = 1
        _NormalTiling ("NormalTiling", Range(0, 10)) = 0.5

        _WaveSpeed ("FoamSpeed", Range(-5, 5)) = 1

        _BlendDepth ("BlendDepth", Range(0.1, 100)) = 1
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        [HDR]_CausticsColor ("CausticsColor", Color) = (1, 1, 1, 1)
        _CausticsTiling ("CausticsTiling", Range(0, 10)) = 10
        _CausticsSpeed ("CausticsSpeed", Float) = 1
        [NoScaleOffset]_CubeMap ("Cubemap", Cube) = "white" { }

        [Toggle(UseHighlight)] UseHighlight ("UseHighlight", Float) = 0
        _HighLightOffset ("HighLightOffset", vector) = (0, 0, 0, 1)
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        _SphereMaskPosition ("MaskPosition", vector) = (0, 0, 0, 0)
    }

    SubShader
    {
        Tags { "RenderType" = "Geometry" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }
        LOD 300

        // ZTest [_ZTest]
        ZWrite On

        Blend one OneMinusSrcAlpha

        Cull back

        Pass
        {
            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature UseHighlight
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"



            struct appdata
            {
                float4 positionOS: POSITION;
                float4 normal: NORMAL;
                float2 uv: TEXCOORD;
            };

            struct v2f
            {
                float4 positionCS: SV_POSITION;
                float4 screenPos: TEXCOORD1;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD3;
                float3 normalWS: TEXCOORD4;
                half fogFactor: TEXCOORD5;
            };

            CBUFFER_START(UnityPerMaterial)
            float _FlowSpeed;

            TEXTURE2D(_FoamMap);
            SAMPLER(sampler_FoamMap);
            TEXTURECUBE(_CubeMap);
            SAMPLER(sampler_CubeMap);

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
            half4 _HighLightOffset;
            half4 _SphereMaskPosition;
            CBUFFER_END
            SAMPLER(_CameraOpaqueTexture);

            // TEXTURE2D(_ReflectionTex);
            // SAMPLER(sampler_ReflectionTex);
            TEXTURE2D(_ReflectionTex);
            SAMPLER(sampler_ReflectionTex);
            // half4 reflection = SAMPLE_TEXTURE2D(_ReflectionTex, sampler_ReflectionTex, screenUV);



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
                return output;
            }
            //利用cos生成的渐变色，使用网站：https://sp4ghet.github.io/grad/
            real4 cosine_gradient(float x, real4 phase, real4 amp, real4 freq, real4 offset)
            {
                float TAU = 2. * 3.14159265;
                phase *= TAU;
                x *= TAU;

                return real4(
                    offset.r + amp.r * 0.5 * cos(x * freq.r + phase.r) + 0.5,
                    offset.g + amp.g * 0.5 * cos(x * freq.g + phase.g) + 0.5,
                    offset.b + amp.b * 0.5 * cos(x * freq.b + phase.b) + 0.5,
                    offset.a + amp.a * 0.5 * cos(x * freq.a + phase.a) + 0.5
                );
            }
            real3 toRGB(real3 grad)
            {
                return grad.rgb;
            }
            //噪声图生成
            float2 rand(float2 st, int seed)
            {
                float2 s = float2(dot(st, float2(127.1, 311.7)) + seed, dot(st, float2(269.5, 183.3)) + seed);
                return -1 + 2 * frac(sin(s) * 43758.5453123);
            }
            float noise(float2 st, int seed)
            {


                st.y += _Time.y * _FlowSpeed;


                float2 p = floor(st);
                float2 f = frac(st);

                float w00 = dot(rand(p, seed), f);
                float w10 = dot(rand(p + float2(1, 0), seed), f - float2(1, 0));
                float w01 = dot(rand(p + float2(0, 1), seed), f - float2(0, 1));
                float w11 = dot(rand(p + float2(1, 1), seed), f - float2(1, 1));

                float2 u = f * f * (3 - 2 * f);

                return lerp(lerp(w00, w10, u.x), lerp(w01, w11, u.x), u.y);
            }
            //海浪的涌起法线计算
            float3 swell(float3 pos, float anisotropy)
            {
                float3 normal;

                float height = noise(pos.xz * _NormalTiling, 0.1);

                height = height + noise(pos.xz * _NormalTiling * 0.5, 0.1);
                height = height + noise(pos.xz * _NormalTiling * 0.25, 0.1);
                height *= anisotropy / 0.5;//使距离地平线近的区域的海浪高度降低
                normal = normalize
                (cross(
                    float3(0, ddy(height), 1),
                    float3(1, ddx(height), 0)
                )//两片元间高度差值得到梯度
                );
                return normal;
            }

            // real4 blendSeaColor(real4 col1, real4 col2)
            // {
            //     real4 col = min(1, 1.5 - col2.a) * col1 + col2.a * col2;
            //     return col;
            // }

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



            real4 frag(v2f i): SV_Target
            {
                real4 col = (1, 1, 1, 1);
                float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, i.screenPos.xy / i.screenPos.w);
                float sceneZ1 = Linear01Depth(sceneZ, _ZBufferParams);
                sceneZ = LinearEyeDepth(sceneZ, _ZBufferParams);
                half fre4 = (sceneZ - ComputeScreenPos(TransformWorldToHClip(i.positionWS)).w);
                half fre4FF = clamp(fre4, 0, 1);

                half fre4F = fre4 / _FoamBlendDepth;
                float distanceFadeFactor = i.positionCS.z * _ZBufferParams.z * 20;

                // fre4 = fre4 / (_BlendDepth * distanceFadeFactor) ;

                fre4 = smoothstep(0, _BlendDepth, fre4);// * (1 - distanceFadeFactor);
                float partZ = i.screenPos.w;
                float diffZ = saturate((sceneZ - partZ) / 5);//片元深度与场景深度的差值
                // float ratioZ = sceneZ / partZ;//场景深度与片元深度的比值
                // const real4 phases = real4(0.28, 0.50, 0.07, 0);//周期
                // const real4 amplitudes = real4(4.02, 0.34, 0.65, 0);//振幅
                // const real4 frequencies = real4(0.3, 0.48, 0.08, 0) * _FoamColorFrequence;//频率
                // const real4 offsets = real4(0.00, 0.16, 0.00, 0);//相位
                // //按照距离海滩远近叠加渐变色
                // real4 cos_grad = cosine_gradient(saturate(1.5 - fre4), phases, amplitudes, frequencies, offsets);
                // cos_grad = clamp(cos_grad, 0, 1);
                // // col.rgb = toRGB(cos_grad);

                //海浪波动
                half3 worldViewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 v = i.positionWS - _WorldSpaceCameraPos;
                float anisotropy = saturate(1 / ddy(length(v.xz)) / 50) ;//通过临近像素点间摄像机到片元位置差值来计算哪里是接近地平线的部分
                float3 swelledNormal = swell(i.positionWS, anisotropy); //SAMPLE_TEXTURE2D(_WaterNormal, sampler_WaterNormal, i.uv * 5);




                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                // 反射天空盒
                half3 reflDir = reflect(-worldViewDir, swelledNormal);
                float4 reflectionColor = SAMPLE_TEXTURECUBE(_CubeMap, sampler_CubeMap, reflDir);


                half fresnel = pow(saturate(0.2 - dot(worldViewDir, i.normalWS)), 0.9) * 10 * distanceFadeFactor;
                float camLength = length(_WorldSpaceCameraPos - i.positionWS);

                //岸边浪花

                //缩放
                float3 objectScale = float3(length(unity_ObjectToWorld[ 0 ].xyz), length(unity_ObjectToWorld[ 1 ].xyz), length(unity_ObjectToWorld[ 2 ].xyz));


                half4 FoamMapCol = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, i.uv * _FoamMapTiling * objectScale.x);
                float foam = saturate(sin((fre4F + FoamMapCol.r * 0.3 - _Time.x * _WaveSpeed * - 1) * _FoamFrequence * 3.14159) * FoamMapCol.g);

                foam = foam * (1 - smoothstep(0, _FoamDepth, fre4F)) * smoothstep(0, 0.5, fre4F);




                // 菲涅尔反射
                float f0 = 0.02;
                float vReflect = f0 + (1 - f0) * pow(1 - dot(worldViewDir, swelledNormal), 2);
                vReflect = saturate(vReflect * 0.5);


                Light mainLight = GetMainLight();

                // 菲涅尔反射
                half3 specularLighting = 0;
                #ifdef UseHighlight
                    float3 lightColorAndAttenuation = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
                    half NdotL = saturate(dot(i.normalWS, mainLight.direction));
                    half3 specular = half3(1, 1, 1) * 10;
                    half normalizationTerm = 10 * 4.0h + 2.0h;
                    specularLighting = float3(0.5, 0.5, 1);

                    float3 halfDir = SafeNormalize(float3(_HighLightOffset.xyz) + float3(worldViewDir.x, 0.12, worldViewDir. z));
                    float NoH = saturate(dot(normalize(swelledNormal * float3(30, 2, 30)), halfDir));
                    half LoH = saturate(dot(mainLight.direction, halfDir));
                    float d = NoH * NoH * (0.001 - 1.h) + 1.0001f;
                    half LoH2 = LoH * LoH;
                    half specularTerm = 0.001 / ((d * d) * max(0.1h, LoH2) * normalizationTerm);

                    specularLighting = specularTerm * specular * lightColorAndAttenuation ;
                    specularLighting = specularLighting * NdotL * pow(FoamMapCol.r, _HighLightOffset.a) * 2 * distanceFadeFactor  ;
                #endif

                //地平线处边缘光，使海水更通透
                col += clamp(ddy(length(v.xz)) / 10, 0, 2);
                //接近海滩部分更透明W


                float4 ndcPos = (i.screenPos / i.screenPos.w) * 2 - 1;
                float3 clipVec = float3(ndcPos.x, ndcPos.y, 1.0) * _ProjectionParams.z;
                float3 viewVec = mul(unity_CameraInvProjection, clipVec.xyzz).xyz;
                float3 viewPos = sceneZ1 * viewVec;
                float3 worldPos = mul(UNITY_MATRIX_I_V, float4(viewPos, 1.0)).xyz;//深度重构世界坐标




                screenUV = float2((screenUV.x + swelledNormal.r * _Distortion * distanceFadeFactor * diffZ / i.screenPos.w), screenUV.y);
                //反射
                float4 reflection = SAMPLE_TEXTURECUBE(_ReflectionTex, sampler_ReflectionTex, float2((i.screenPos.x + swelledNormal.r * _Distortion * 100), i.screenPos.y) / i.screenPos.w);
                //   float3 finalspecColor = tex2D(_ReflectionTex, screenPos);

                float4 colrefrac = tex2D(_CameraOpaqueTexture, screenUV);




                //half foamMask = clamp(clamp(foam, 0, 1) * _FoamIntensity, 0, 0.67);


                half foamMask = saturate(foam) * 5 ;
                // float Caustics = float(lerp(0, 1, smoothstep(0, 0.7, ov(i.uv * _CausticsTiling * objectScale.x)))) * worldPos.z;
                float Caustics = float(lerp(0, 1, smoothstep(0, 0.7, ov(worldPos.xz * _CausticsTiling / 100 * objectScale.x)))) ;



                float3 colcau = Caustics * _CausticsColor.rgb * saturate(1 - fre4);

                half FoamMapCol2 = SAMPLE_TEXTURE2D(_FoamMap, sampler_FoamMap, i.uv * _FoamMapTiling).r;

                col.rgb += specularLighting * fresnel ;
                col.rgb = lerp(colrefrac.rgb, (col.rgb * _BaseColor - (saturate(FoamMapCol2) * 0.15) + colcau), clamp(fre4, 0, 1))  ;


                col.rgb = lerp(col.rgb, 1, foamMask * smoothstep(0.1, 0.2, clamp(camLength * 0.01, 0, 1)));


                col.rgb = lerp(col, max(lerp(reflectionColor, reflection.rgb, 0.5) - (saturate(FoamMapCol2) * 0.15), 0.1), vReflect * fre4FF) ;

                col.rgb = MixFog(col.rgb, i.fogFactor);
                // return float4(FoamMapCol2.rrr, 1);
                // return float4(saturate(1 - i.fogFactor.rrr), 1);

                half sphereMask = distance(i.uv, _SphereMaskPosition.xz);
                sphereMask = 1 - step(sphereMask, _SphereMaskPosition.w);
                clip(sphereMask - 0.1);
                return float4(col.rgb, sphereMask);
            }

            ENDHLSL

        }
    }
}