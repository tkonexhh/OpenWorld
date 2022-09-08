//顶点流custom1.x 控制溶解
//custom1.yz 控制mainTex offset

Shader "HMK/Particle/Uber"
{
    Properties
    {
        [Header(MainTex)]
        [HDR]_MainColor ("MainColor", color) = (1, 1, 1, 1)
        _MainTex ("MainTex", 2D) = "white" { }

        //是否使用平移功能
        [Space(10)]
        [Toggle(_PANNER_ON)]_Panner_On ("Panner_On", int) = 0
        _MainTex_PannerSpeedU ("MainTex_PannerSpeedU", float) = 0.1
        _MainTex_PannerSpeedV ("MainTex_PannerSpeedV", float) = 0.1

        //Mask遮罩
        [Space(10)]
        [Toggle(_MASK_ON)]_Mask_On ("Mask_ON", int) = 0
        _MaskTex ("MaskTex", 2D) = "white" { }
        
        //扰动
        [Space(10)]
        [Toggle(_NOISE_ON)]_Noise_On ("Noise_On", int) = 0
        _NoiseTex ("NoiseTex", 2D) = "white" { }
        _NoiseIntensity ("NoiseIntensity", range(0, 5)) = 0.5
        _NoiseTex_PannerSpeedU ("NoiseTex_PannerSpeedU", float) = 0
        _NoiseTex_PannerSpeedV ("NoiseTex_PannerSpeedV", float) = 0
        
        //溶解
        [Space(10)]
        [Toggle(_DISSOLVE_ON)]_Dissolve_On ("Dissolve_On", int) = 0
        // [Toggle(ReverseDissolve)]_ReverseDissolve ("ReverseDissolve", Int) = 0
        _DissolveTex ("DissolveTex", 2D) = "white" { }
        _DissolveFactor ("DissolveFactor", Range(0, 1)) = 0.5
        _HardnessFactor ("HardnessFactor", Range(0, 1)) = 0.9
        _DissolveWidth ("DissolveWidth", Range(0, 1)) = 0.1
        [HDR]_DissolveWidthColor ("DissolveWidthColor", Color) = (1, 1, 1, 1)

        //边缘光
        [Space(10)]
        [Toggle(_FRESNEL_ON)]_Fresnel_On ("Fresnel_On", Int) = 0//是否开启Fresnel
        [HDR]_FresnelColor ("FresnelColor", Color) = (1, 1, 1, 1)
        _FresnelWidth ("FresnelWidth", Range(0, 1)) = 0.5

        //折射
        // [Space(10)]
        // [Toggle(_REFRACT_ON)]_Refract_On ("_Refract_On", Int) = 0
        // _RefractTex ("DissolveTex", 2D) = "bump" { }
        // _RefractStrength ("RefractStrength", range(0, 200)) = 1

        //深度混合
        [space(10)]
        [Toggle(_BLENDDEPTH_ON)]_BlendDepth_On ("_BlendDepth_On", Int) = 0
        _BlendDepth ("BlendDepth", float) = 5



        //部分特效物体算场景物体 又因为是透明的 需要进行雾效支持
        [Space(10)]
        [Toggle(_APPLY_FOG)]_Fog_On ("Fog_On", Int) = 0//是否开启接收雾

        [Toggle(_APPLY_LIGHT)]_Light_On ("Light_On", Int) = 0//是否开启接收光照

        [Space(10)]
        [Header(Options)]
        //深度写入,提出模式，深度测试，混合模式，
        [Enum(Off, 0, On, 1)]_ZWrite ("ZWrite", Int) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode ("CullMode", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest ("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendModeSrc ("BlendModeSrc", Int) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendModeDst ("BlendModeDst", Int) = 10
        [Toggle(_CLIP_ON)]_Clip_On ("Clip_On", Int) = 0//是否开启剪裁
        // [Toggle(UNITY_UI_CLIP_RECT)]_UseUIClipRect ("Use UI Clip Rect", Int) = 0//是否开启剪裁
        [HideInInspector]_ClipRect ("Clip Rect", vector) = (-100000, -100000, 100000, 100000)

        // Editmode props
        [HideInInspector] _QueueOffset ("Queue offset", Float) = 0.0
        [HideInInspector] _RenderMode ("Render Mode", Int) = 0.0

        // [Space(10)]
        // [Header(Stencil)]
        // _Stencil ("StencilRef", Int) = 0
        // _StencilReadMask ("StencilReadMask", Int) = 255
        // _StencilWriteMask ("StencilWriteMask", Int) = 255
        // _StencilComp ("StencilComp", float) = 8
        // _StencilOp ("StencilOp", float) = 0

    }


    HLSLINCLUDE
    
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    CBUFFER_START(UnityPerMaterial)
    //MainTex
    half4 _MainColor;
    float4 _MainTex_ST, _MaskTex_ST, _NoiseTex_ST, _DissolveTex_ST;

    //_PANNER_ON
    float _MainTex_PannerSpeedU, _MainTex_PannerSpeedV;

    //扰动
    float _NoiseIntensity;
    float _NoiseTex_PannerSpeedU, _NoiseTex_PannerSpeedV;

    //溶解
    // int _ReverseDissolve;
    float _DissolveFactor;
    float _HardnessFactor;
    float _DissolveWidth;
    half3 _DissolveWidthColor;


    //边缘光 Fresnel
    half4 _FresnelColor;
    float _FresnelWidth;

    //折射
    half _RefractStrength;
    float4 _CameraColorTexture_TexelSize;
    float4 _CameraOpaqueTexture_TexelSize;

    //深度混合
    half _BlendDepth;

    //控制变量
    //int _ParticleModeTemp01, _ParticleModeTemp02;

    float4 _ClipRect;
    CBUFFER_END

    TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);//主贴图
    TEXTURE2D(_MaskTex);SAMPLER(sampler_MaskTex);//Mask贴图
    TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);//扰动贴图
    TEXTURE2D(_DissolveTex);SAMPLER(sampler_DissolveTex);//溶解贴图
    // TEXTURE2D(_RefractTex);SAMPLER(sampler_RefractTex);//折射贴图

    //屏幕颜色 用于折射
    // TEXTURE2D(_CameraColorTexture);SAMPLER(sampler_CameraColorTexture);
    // TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
    //深度 用于深度混合
    TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);


    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }

        Cull  [_CullMode]
        Blend [_BlendModeSrc] [_BlendModeDst]
        ZTest [_ZTest]
        ZWrite [_ZWrite]

        // Stencil
        // {
        //     Ref  [_Stencil]
        //     ReadMask [_StencilReadMask]
        //     WriteMask [_StencilWriteMask]
        //     Comp Equal //[_StencilCompare]

        // }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile __ _MASK_ON
            #pragma multi_compile __ _APPLY_FOG
            #pragma multi_compile __ _APPLY_LIGHT
            #pragma multi_compile __ _PANNER_ON
            #pragma multi_compile __ _NOISE_ON
            #pragma multi_compile __ _DISSOLVE_ON
            #pragma multi_compile __ _FRESNEL_ON
            // #pragma multi_compile __ _REFRACT_ON
            #pragma multi_compile __ _CLIP_ON
            #pragma multi_compile __ _BLENDDEPTH_ON
            
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #pragma multi_compile __ UNITY_UI_ALPHACLIP
            
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "./../HLSLIncludes/Common/Fog.hlsl"
            #include "./../HLSLIncludes/UI/HMKUI.hlsl"



            //smoothstep函数去掉平滑部分
            inline float Smoothstep_Simple(float c, float minValue, float maxValue)
            {
                c = (c - minValue) / (maxValue - minValue);
                c = saturate(c);
                return c ;
            }
            //单层溶解函数
            inline half4 DissolveFunction(half4 rgba, float dissolveTex, float dissolve, float hardness)
            {
                hardness = clamp(hardness, 0.00001, 0.999999);
                dissolveTex += dissolve * (2 - hardness);
                dissolveTex = 2 - dissolveTex;
                dissolveTex = Smoothstep_Simple(dissolveTex, hardness, 1);
                rgba.a *= dissolveTex;
                return rgba;
            }
            //双层溶解函数
            inline float4 DoubleDissolveFunction(half4 rgba, float dissolveTex, float dissolve, float hardness, float width, half3 WidthColor)
            {
                hardness = clamp(hardness, 0.00001, 999999);
                dissolve *= (1 + width);
                float hardnessFactor = 2 - hardness;
                float dissolve01 = dissolve * hardnessFactor + dissolveTex;
                dissolve01 = Smoothstep_Simple((2 - dissolve01), hardness, 1);
                float dissolve02 = (dissolve - width) * hardnessFactor + dissolveTex;
                dissolve02 = Smoothstep_Simple((2 - dissolve02), hardness, 1);
                rgba.rgb = lerp(WidthColor, rgba.rgb, dissolve01);
                rgba.a *= dissolve02;
                return rgba;
            }


            struct Attributes
            {
                float4 positionOS: POSITION;
                float3 normalOS: NORMAL;
                half4 color: COLOR;//UI 的颜色是靠顶点色
                float4 uv: TEXCOORD0;
                float4 customData1: TEXCOORD1;
                // float4 customData2: TEXCOORD2;
                // #ifdef _REFRACT_ON
                //     float4 tangentOS: TANGENT;
                // #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
                float4 uv1: TEXCOORD0;
                float4 uv2: TEXCOORD1;
                // float4 uv3: TEXCOORD4;
                float3 normalWS: NORMAL;
                half4 color: COLOR;

                float4 customData1: TEXCOORD3;
                // float4 customData2: TEXCOORD4;

                // #ifdef _REFRACT_ON
                //     float3 tangentWS: TANGENT;
                //     float3 bitangentWS: TEXCOORD5;
                // #endif


                #ifdef _BLENDDEPTH_ON
                    float4 positionSS: TEXCOORD6;
                #endif
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                float2 uv_Main = TRANSFORM_TEX(input.uv, _MainTex);
                float2 uv_Mask = TRANSFORM_TEX(input.uv, _MaskTex);
                float2 uv_Noise = TRANSFORM_TEX(input.uv, _NoiseTex);
                float2 uv_Dissolve = TRANSFORM_TEX(input.uv, _DissolveTex);
                // float2 uv_Refract = TRANSFORM_TEX(input.uv, _RefractTex);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.color = input.color;


                //平移操作
                #ifdef _PANNER_ON
                    {
                        uv_Main += _Time.y * float2(_MainTex_PannerSpeedU, _MainTex_PannerSpeedV);
                        uv_Noise += _Time.y * float2(_NoiseTex_PannerSpeedU, _NoiseTex_PannerSpeedV);
                    }
                #endif

                output.uv1.xy = uv_Main;
                output.uv1.zw = uv_Mask;
                output.uv2.xy = uv_Noise;
                output.uv2.zw = uv_Dissolve;
                // output.uv3.xy = uv_Refract;

                output.customData1 = input.customData1;


                // #ifdef _REFRACT_ON
                //     //获取法线
                //     output.tangentWS = normalize(TransformObjectToWorldDir(input.tangentOS.xyz));
                //     int sign = input.tangentOS.w * unity_WorldTransformParams.w;
                //     output.bitangentWS = cross(output.normalWS, output.tangentWS) * sign;
                // #endif

                #ifdef _BLENDDEPTH_ON
                    output.positionSS = ComputeScreenPos(output.positionCS);
                #endif

                // output.customData2 = input.customData2;
                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                half4 finalColor;
                
                float2 uv_Main = input.uv1.xy;
                float2 uv_Mask = input.uv1.zw;
                float2 uv_Noise = input.uv2.xy;
                float2 uv_Dissolve = input.uv2.zw;
                // float2 uv_Refract = input.uv3.xy;

                float dissolve = input.customData1.x;
                // return dissolve;
                float2 uv_MainOffset = input.customData1.yz;
                uv_Main += uv_MainOffset;

                //是否开启扰动
                #ifdef _NOISE_ON
                    {
                        half4 var_NoiseTex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uv_Noise);
                        var_NoiseTex = (var_NoiseTex * 2 - 1) * _NoiseIntensity;
                        uv_Main += var_NoiseTex;
                        // uv_Dissolve += var_NoiseTex;
                        // uv_Mask += var_NoiseTex;
                        uv_Noise += var_NoiseTex;
                    }
                #endif

                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv_Main);

                finalColor = var_MainTex * _MainColor * input.color;

                //是否开启溶解
                #ifdef _DISSOLVE_ON
                    {
                        half var_DissolveTex = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, uv_Dissolve);
                        var_DissolveTex = 1 - var_DissolveTex;//lerp(var_DissolveTex, 1 - var_DissolveTex, _ReverseDissolve);
                        _DissolveFactor = _DissolveFactor * dissolve;//lerp(_DissolveFactor, dissolve, _ParticleModeTemp02);
                        finalColor = DoubleDissolveFunction(finalColor, var_DissolveTex, _DissolveFactor, _HardnessFactor, _DissolveWidth, _DissolveWidthColor);
                    }
                #endif



                //是否打开Mask
                #ifdef _MASK_ON
                    {
                        half4 var_MaskTex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uv_Mask);
                        finalColor.a *= var_MaskTex.r;
                    }
                #endif

                //是否开启折射
                // #ifdef _REFRACT_ON
                //     {
                //         half4 var_RefractTex = SAMPLE_TEXTURE2D(_RefractTex, sampler_RefractTex, uv_Refract);
                //         float3 normalTS = UnpackNormalScale(var_RefractTex, _RefractStrength);
                //         float3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                //         float3 normalWS = mul(normalTS, TBN);
                //         float2 uv_SS = input.positionCS.xy / _ScreenParams.xy;//获取屏幕空间UV
                //         float2 bias_SS = normalWS.xy * _CameraOpaqueTexture_TexelSize;
                //         half3 screenBiasColor = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, uv_SS + bias_SS);
                //         return half4(screenBiasColor, finalColor.a);
                //     }
                // #endif

                //是否启用clip
                #ifdef _CLIP_ON
                    {
                        clip(finalColor.a - 0.5);
                    }
                #endif


                //边缘光
                #ifdef _FRESNEL_ON
                    {
                        float3 viewDir = normalize(_WorldSpaceCameraPos - input.positionWS);
                        float3 normalWS = normalize(input.normalWS);
                        half VDotN = dot(viewDir, normalWS);
                        VDotN = 1 - saturate(VDotN);
                        VDotN = Smoothstep_Simple(VDotN, (1 - _FresnelWidth), 1);
                        half4 fresnelColor = _FresnelColor * VDotN;
                        finalColor.rgb += fresnelColor.rgb;
                        finalColor.a = finalColor.a * (lerp(VDotN, 1, _FresnelColor.a));
                        // return VDotN;

                    }
                #endif

                #ifdef _BLENDDEPTH_ON
                    {
                        float2 screenUV = input.positionSS.xy / input.positionSS.w;
                        float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                        sceneZ = LinearEyeDepth(sceneZ, _ZBufferParams);

                        half fre4 = (sceneZ - ComputeScreenPos(input.positionCS).w);
                        // half fre4FF = clamp(fre4, 0, 1);

                        half blendFactor = fre4 / _BlendDepth;
                        blendFactor = smoothstep(0.5, _BlendDepth, fre4);
                        finalColor.a = lerp(0, finalColor.a, blendFactor);
                        // return finalColor.a ;

                    }
                #endif

                


                //UI相关
                //rect mask
                #ifdef UNITY_UI_CLIP_RECT
                    finalColor.a *= UnityGet2DClipping(input.positionWS.xy, _ClipRect);
                #endif
                //sprite mask
                #ifdef UNITY_UI_ALPHACLIP
                    clip(finalColor.a - 0.001);
                #endif

                #ifdef _APPLY_LIGHT
                    Light mainLight = GetMainLight();
                    mainLight.color = clamp(mainLight.color, 0.1, 1.2);
                    half LightInt = mainLight.color.r * 0.299 + mainLight.color.g * 0.581 + mainLight.color.b * 0.114;
                    finalColor.rgb *= LightInt;
                #endif

                #ifdef _APPLY_FOG
                    finalColor.rgb = ApplyFog(finalColor.rgb, input.positionWS);
                #endif

                return finalColor;
            }
            
            ENDHLSL

        }
    }
    // FallBack "Diffuse"
    CustomEditor "ParticleUberShaderGUI"
}
