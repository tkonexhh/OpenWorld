

Shader "OpenWorld/Unlit"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0.0
        [Enum(Off, 0, On, 1)]_ZWrite ("Z Write", float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode ("Cull Mode", float) = 2.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "OpenWorldForward" }
            
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_CullMode]
            
            HLSLPROGRAM

            #pragma multi_compile_instancing

            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            #include "Packages/RenderPipeline/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            #include "./UnlitInput.hlsl"
            #include "./UnlitForwardPass.hlsl"
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}