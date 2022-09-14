Shader "OpenWorld/Lit"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _MetallicScale ("MetallicScale", range(0, 1)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 1)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 1)) = 1

        [Header(Emission)]
        _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
        _EmissionScale ("Emission Scale", range(0, 1)) = 1

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

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            
            #include "Packages/RenderPipeline/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            #include "./LitInput.hlsl"
            #include "./LitForwardPass.hlsl"
            ENDHLSL

        }
    }
    FallBack "Diffuse"
}