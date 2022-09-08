

Shader "Hidden/Grass/Grass Cutter"
{
    Properties
    {
        // _Params ("Parameters", vector) = (1, 0, 0, 0)

    }


    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "./Bending.hlsl"


    // CBUFFER_START(UnityPerMaterial)
    // float4 _Params;
    // CBUFFER_END

    // #define Strength _Params.x
    // #define HeightOffset _Params.y
    // #define ScaleMultiplier _Params.z
    // #define PushStrength _Params.w

    struct Attributes
    {
        float3 positionOS: POSITION;
        float4 uv: TEXCOORD0;
        float3 normalOS: NORMAL;
        // float4 tangentOS: TANGENT;
        float4 color: COLOR;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };


    struct Varyings
    {
        float4 positionCS: SV_POSITION;
        float3 uv: TEXCOORD0;
        float3 positionWS: TEXCOORD1;
        // float4 tangentWS: TEXCOORD2;
        // float3 bitangentWS: TEXCOORD3;
        float4 color: TEXCOORD4;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };


    Varyings vert(Attributes input)
    {
        Varyings output = (Varyings)0;

        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output)
        
        output.uv.xy = input.uv.xy;
        output.color = input.color;
        output.positionWS = TransformObjectToWorld(input.positionOS);
        output.positionCS = TransformWorldToHClip(output.positionWS);
        // float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
        // output.tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
        // output.bitangentWS = -TransformWorldToViewDir(cross(normalWS, output.tangentWS.xyz) * input.tangentOS.w);

        return output;
    }


    float4 frag(Varyings input): SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        

        float4 color = float4(1, 0, 0, 1);

        return color;
    }


    ENDHLSL

    SubShader
    {
        Tags { "RenderType" = "GrassBender" "RenderPipeline" = "UniversalPipeline" "LightMode" = "GrassInteractive" }

        Pass
        {
            ColorMask RA
            Blend Off
            ZWrite Off
            ZTest LEqual
            Cull Back
            
            HLSLPROGRAM

            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            ENDHLSL

        }

        Pass
        {
            ColorMask RA
            Blend SrcAlpha  OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            Cull Back
            
            HLSLPROGRAM

            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            ENDHLSL

        }
    }
    FallBack "Hidden/InternalErrorShader"
}
