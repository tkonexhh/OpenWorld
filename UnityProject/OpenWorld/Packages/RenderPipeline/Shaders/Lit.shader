﻿Shader "OpenWorld/Lit"
{
    Properties
    {
        [MainTexture] _BaseMap ("MainTex", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _MetallicScale ("MetallicScale", range(0, 1)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 1)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 1)) = 1

        [Toggle(_NORMALMAP)]_NormalMapToggle ("Use Normal map", float) = 0
        [Normal] _NormalMap ("Normal map", 2D) = "bump" { }
        _NormalScale ("Normal Scale", Range(0, 3)) = 1

        [Header(Emission)]
        _EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)
        _EmissionScale ("Emission Scale", range(0, 5)) = 1

        [Header(Setting)]
        [Toggle(_ALPHATEST_ON)] _AlphaClip ("AlphaClip", Float) = 0.0
        [HideInInspector] _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        [Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows ("Receive Shadows", Float) = 1
        [KeywordEnum(On, Off)]_Shadows ("Shadows", float) = 0
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
            Name "Forward"
            Tags { "LightMode" = "OpenWorldForward" }
            
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_CullMode]
            
            HLSLPROGRAM

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _RECEIVE_SHADOWS
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma shader_feature_local_fragment _NORMALMAP

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "./LitInput.hlsl"
            #include "./LitForwardPass.hlsl"
            
            ENDHLSL

        }


        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }


            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_CullMode]

            HLSLPROGRAM

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "./LitInput.hlsl"
            #include "./ShadowCasterPass.hlsl"
            
            ENDHLSL

        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull[_CullMode]

            HLSLPROGRAM

            // #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            #include "./LitInput.hlsl"
            #include "./DepthOnlyPass.hlsl"

            ENDHLSL

        }


        Pass
        {
            Name "Meta"
            Tags { "LightMode" = "Meta" }

            Cull Off

            HLSLPROGRAM

            #pragma target 3.5

            #pragma vertex MetaPassVertex
            #pragma fragment MetaPassFragment
            
            #include "./LitInput.hlsl"
            #include "./LitMetaPass.hlsl"

            ENDHLSL

        }
    }
    FallBack "Diffuse"
    CustomEditor "OpenWorld.RenderPipelines.ShaderGUI.LitShader"
}