

Shader "HMK/Lit"
{
    Properties
    {
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Header(Base Color)]
        [MainColor]_BaseColor ("固有色", color) = (1, 1, 1, 1)
        [NoScaleOffset] _BaseMap ("BaseMap", 2D) = "white" { }
        [NoScaleOffset] _PBRMap ("PBR贴图 R:金属度 G:粗糙度 B:AO", 2D) = "white" { }
        [NORMAL] [NoScaleOffset]_NormalMap ("法线贴图", 2D) = "bump" { }
        _BumpScale ("Bump Scale", range(0, 3)) = 1
        _MetallicScale ("MetallicScale", range(0, 3)) = 1
        _RoughnessScale ("RoughnessScale", range(0, 3)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 3)) = 1
        
        [Header(Emission)]
        _EmissionScale ("Emission Scale", range(0, 3)) = 0
        [HDR] _EmissionColor ("Emission Color", color) = (1, 1, 1)
        [Toggle(_EMISSION_BREATH_ON)]_Emission_Breath_On ("_Emission_Breath_On", Int) = 0
        _BreathSpeed ("_BreathSpeed", float) = 1

        [Header(Option)]
        // Blending state
        [HideInInspector] _Surface ("__surface", Float) = 0.0
        [HideInInspector] _Blend ("__blend", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _AlphaClip ("__clip", Float) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)]  _Cull ("__Cull", float) = 2.0

        _ReceiveShadows ("Receive Shadows", Float) = 1.0
    }
    SubShader
    {
        
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" "Queue" = "Transparent" }
            
            Cull[_Cull]
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            
            HLSLPROGRAM

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature _PBRMAP_ON

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//必须加上 影响主光源的shadowCoord
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            #include "./HMK_Lit_Input.hlsl"
            #include "./HMK_Lit_ForwardPass.hlsl"
            
            ENDHLSL

        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On // the only goal of this pass is to write depth!
            ZTest LEqual // early exit at Early-Z stage if possible
            ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
            Cull[_Cull] // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

            HLSLPROGRAM

            // #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "./HMK_Lit_Input.hlsl"
            #include "./HMK_ShadowCasterPass.hlsl"

            ENDHLSL

        }


        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "GBuffer"
            Tags { "LightMode" = "UniversalGBuffer" }

            ZWrite[_ZWrite]
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex LitGBufferPassVertex
            #pragma fragment LitGBufferPassFragment

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "./HMK_Lit_Input.hlsl"
            #include "./LitGBufferPass.hlsl"
            
            ENDHLSL

        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull[_Cull]

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
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "./HMK_Lit_Input.hlsl"
            #include "./HMK_DepthOnlyPass.hlsl"

            ENDHLSL

        }
    }
    FallBack "Diffuse"
    CustomEditor "HMKLitShaderGUI"
}
