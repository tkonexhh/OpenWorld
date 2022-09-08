

Shader "HMK/Scene/Decal"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _Tint ("Tint", Color) = (1, 1, 1, 1)

        [Header(Stencil)]
        [IntRange] _StencilRef ("Stencil Reference", Range(0, 255)) = 0
        [IntRange] _ReadMask ("     Read Mask", Range(0, 255)) = 255
        [IntRange] _WriteMask ("     Write Mask", Range(0, 255)) = 255
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Transparent+2" }

        Pass
        {
            Stencil
            {
                Ref  [_StencilRef]
                ReadMask [_ReadMask]
                WriteMask [_WriteMask]
                Comp Equal //[_StencilCompare]

            }

            Tags { "LightMode" = "UniversalForward" }
            
            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest Always
            Cull Front
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Tint;

            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float4 positionSS: TEXCOORD1;
                float3 positionWS: TEXCOORD2;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 ray: TEXCOORD3;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionSS = ComputeScreenPos(output.positionCS);
                output.ray = TransformWorldToView(TransformObjectToWorld(input.positionOS)).xyz * float3(-1, -1, 1);
                output.uv = input.uv;


                return output;
            }


            half4 frag(Varyings input): SV_Target
            {
                input.ray = input.ray * (_ProjectionParams.z / input.ray.z);

                float2 screenUV = input.positionSS.xy / input.positionSS.w;

                float sceneZ = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                float sceneZZ = LinearEyeDepth(sceneZ, _ZBufferParams);
                half fre4 = (sceneZZ - ComputeScreenPos(TransformWorldToHClip(input.positionWS)).w) ;
                fre4 = smoothstep(0.9, 1, fre4);

                float depth = Linear01Depth(sceneZ, _ZBufferParams);

                float4 vpos = float4(input.ray * depth, 1);


                float3 wpos = mul(unity_CameraToWorld, vpos).xyz;



                // float3 opos = mul(unity_WorldToObject, float4(wpos, 1)).xyz;
                float3 opos = mul(UNITY_MATRIX_I_M, float4(wpos, 1)).xyz;
                float2 texUV = opos.xz + 0.5;

                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, texUV);

                return col * _Tint;
            }
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
