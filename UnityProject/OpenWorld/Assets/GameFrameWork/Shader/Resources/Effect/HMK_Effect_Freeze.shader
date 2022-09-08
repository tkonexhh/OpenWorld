

Shader "HMK/Effect/Freeze"
{
    Properties
    {
        _FreezeTex ("FreezeTex", 2D) = "white" { }
        _BlendAlpha ("BlendAlpha", Range(0, 1)) = 1
        [HDR]_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        _OutLineSpec ("OutLineSpec", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            // ZTest LEqual
            
            HLSLPROGRAM

            #pragma vertex FreezeVert
            #pragma fragment FreezeFrag

            #include "./HMK_Effect_Freeze_Include.hlsl"
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}
