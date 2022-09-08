

Shader "HMK/Effect/RenderFeature"
{
    Properties
    {


        [Header(Freeze)]
        _FreezeTex ("FreezeTex", 2D) = "white" { }
        _BlendAlpha ("BlendAlpha", Range(0, 1)) = 1
        [HDR]_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        _OutLineSpec ("OutLineSpec", Range(0, 1)) = 0
    }

    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        //占位Pass 0
        Pass
        {
            Tags { "LightMode" = "Hold" }
        }

        //冰冻效果
        Pass
        {
            Tags { "LightMode" = "Freeze" "Queue" = "Transparent" }
            
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            
            HLSLPROGRAM

            #pragma vertex FreezeVert
            #pragma fragment FreezeFrag
            

            #include "./HMK_Effect_Freeze_Include.hlsl"
            
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
