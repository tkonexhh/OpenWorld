

Shader "Hidden/Grass/Grass Bend Mesh"
{
    Properties
    {
        _Params ("Parameters", vector) = (1, 0, 0, 0)
    }


    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


    CBUFFER_START(UnityPerMaterial)
    float4 _Params;
    CBUFFER_END

    #define Strength _Params.x
    #define HeightOffset _Params.y
    #define ScaleMultiplier _Params.z
    #define PushStrength _Params.w

    struct Attributes
    {
        float4 positionOS: POSITION;
        float3 normalOS: NORMAL;
        
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };


    struct Varyings
    {
        float4 positionCS: SV_POSITION;
        float3 positionWS: TEXCOORD0;
        float3 normalWS: NORMAL;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };


    Varyings vert(Attributes input)
    {
        Varyings output = (Varyings)0;

        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output)
        
        input.positionOS *= ScaleMultiplier;

        output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
        output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
        output.normalWS = TransformObjectToWorldNormal(input.normalOS);

        return output;
    }


    float4 frag(Varyings input): SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        float mask = -input.normalWS.y * Strength;

        float height = input.positionWS.y + HeightOffset;//障碍物的世界坐标高度
        float2 dir = (input.normalWS.xz * PushStrength) * 0.5 + 0.5;

        return float4(dir.x, height, dir.y, mask);
    }


    ENDHLSL

    SubShader
    {
        Tags { "RenderType" = "GrassBender" "RenderPipeline" = "UniversalPipeline" "LightMode" = "GrassInteractive" }

        Pass
        {
            Blend Off
            ZWrite Off
            ZTest LEqual
            Cull Front
            
            HLSLPROGRAM

            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            ENDHLSL

        }

        Pass
        {
            Blend Off
            // Blend SrcAlpha  OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            Cull Front
            
            HLSLPROGRAM

            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            ENDHLSL

        }
    }
    FallBack "Hidden/InternalErrorShader"
}
