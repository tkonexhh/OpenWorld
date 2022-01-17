Shader "HMK/Particle/Decal"
{
    Properties
    {

        _MainTex ("MainTex", 2D) = "White" { }
        _CrackTex ("CrackTex", 2D) = "White" { }
        _CrackScale ("CrackScale", Range(0, 2)) = 1
        [HDR]_Tint ("ColorTint", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_NoiseTex ("NoiseTex", 2D) = "White" { }
        [HDR]_CrackColor ("CrackColor", Color) = (1, 1, 1, 1)

        _MovingSpeed ("MovingSpeed", Float) = 0
        _DecalIntensity ("DecalIntensity", Range(0, 1)) = 1
        _NoiseTiling ("NoiseTiling", Float) = 1
        _NoiseIntensity ("NoiseIntensity", Vector) = (0, 0, 0, 0)
        _DissolveInt ("DissolveInt", float) = 1
        // _Clip ("CLip", Vector) = (1, 1, 1, 1)
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4


        [Header(Stencil)]
        [Space(8)]
        [IntRange] _StencilRef ("Stencil Reference", Range(0, 255)) = 0
        [IntRange] _ReadMask ("     Read Mask", Range(0, 255)) = 255
        [IntRange] _WriteMask ("     Write Mask", Range(0, 255)) = 255
        //[Enum(UnityEngine.Rendering.CompareFunction)]
        //_StencilCompare ("Stencil Comparison", Int) = 3 // always

    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent+2" }
        LOD 100


        Pass
        {
            Stencil
            {
                Ref  [_StencilRef]
                ReadMask [_ReadMask]
                WriteMask [_WriteMask]
                Comp Equal //[_StencilCompare]

            }

            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest Always
            //  It is a decal!

            Cull Front
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"



            struct appdata
            {
                float4 vertex: POSITION;
                float4 normal: NORMAL;
                float2 uv: TEXCOORD;
            };

            struct v2f
            {

                float4 vertex: SV_POSITION;
                float4 screenPos: TEXCOORD0;
                float2 uv: TEXCOORD1;

                float3 ray: TEXCOORD2;
                float3 worldPos: TEXCOORD3;
            };
            CBUFFER_START(UnityPerMaterial)




            half4 _MainTex_ST;
            half _MovingSpeed;
            half _DecalIntensity ;
            half _NoiseTiling;
            half4 _NoiseIntensity;
            half _CrackScale;
            // half4 _Clip;
            half4 _Tint;
            half4 _CrackColor;
            half _DissolveInt;


            CBUFFER_END

            TEXTURE2D(_MainTex);

            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_CrackTex);
            SAMPLER(sampler_CrackTex);





            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ray = TransformWorldToView(TransformObjectToWorld(v.vertex)).xyz * float3(-1, -1, 1);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }



            real4 frag(v2f i): SV_Target
            {

                i.ray = i.ray * (_ProjectionParams.z / i.ray.z);

                float2 screenUV = i.screenPos.xy / i.screenPos.w;


                float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                float sceneZZ = LinearEyeDepth(sceneZ, _ZBufferParams);
                half fre4 = (sceneZZ - ComputeScreenPos(TransformWorldToHClip(i.worldPos)).w) ;
                fre4 = smoothstep(0.9, 1, fre4);

                float depth = Linear01Depth(sceneZ, _ZBufferParams);

                float4 vpos = float4(i.ray * depth, 1);


                float3 wpos = mul(unity_CameraToWorld, vpos).xyz;



                // float3 opos = mul(unity_WorldToObject, float4(wpos, 1)).xyz;
                float3 opos = mul(UNITY_MATRIX_I_M, float4(wpos, 1)).xyz;
                clip(float3(0.5, 0.5, 0.5) - abs(opos.xyz)) ;




                float2 texUV = opos.xz + 0.5;

                float4 Noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, float2(texUV.x + _Time.x * _MovingSpeed, texUV.y) * _NoiseTiling);


                float4 Crack = SAMPLE_TEXTURE2D(_CrackTex, sampler_CrackTex, (float2(texUV.x + Noise.r * _NoiseIntensity.x, texUV.y + Noise.g * _NoiseIntensity.y) / _CrackScale + 0.5 - (0.5 / _CrackScale)));

                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, texUV * _MainTex_ST.xy);

                float4 finalColor = lerp(col * _Tint, _CrackColor, Crack.a);

                half NoiseDissolve = step(Noise.g, _DissolveInt);


                return float4(finalColor.rgb, col.a * _DecalIntensity * NoiseDissolve);
            }

            ENDHLSL

        }
    }
}