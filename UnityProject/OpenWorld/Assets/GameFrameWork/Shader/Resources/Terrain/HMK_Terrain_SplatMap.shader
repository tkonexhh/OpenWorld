Shader "HMK/Terrain/Terrain_SplatMap"
{
    Properties
    {
        _Control0 ("Control (RGBA)", 2D) = "black" { }
        _Control1 ("Control (RGBA)", 2D) = "black" { }
        _Splat0 ("Splat0 (R)", 2D) = "grey" { }
        _Splat1 ("Splat1 (G)", 2D) = "grey" { }
        _Splat2 ("Splat2 (B)", 2D) = "grey" { }
        _Splat3 ("Splat3 (A)", 2D) = "grey" { }
        _Splat4 ("Splat0 (R)", 2D) = "grey" { }
        _Splat5 ("Splat1 (G)", 2D) = "grey" { }
        _Splat6 ("Splat2 (B)", 2D) = "grey" { }
        _Splat7 ("Splat3 (A)", 2D) = "grey" { }

        _NRA0 ("NRA0", 2D) = "bump" { }
        _NRA1 ("NRA1", 2D) = "bump" { }
        _NRA2 ("NRA2", 2D) = "bump" { }
        _NRA3 ("NRA3", 2D) = "bump" { }
        _NRA4 ("NRA4", 2D) = "bump" { }
        _NRA5 ("NRA5", 2D) = "bump" { }
        _NRA6 ("NRA6", 2D) = "bump" { }
        _NRA7 ("NRA7", 2D) = "bump" { }

        _RoughnessScale ("RoughnessScale", range(0, 3)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 3)) = 1
        _UVScale ("贴图 UVScale", Range(0.001, 1)) = 0.2

        [HideInInspector] [PerRendererData] _NumLayersCount ("Total Layer Count", Float) = 1.0
        [Toggle(_TERRAIN_BLEND_HEIGHT)] _EnableHeightBlend ("EnableHeightBlend", Float) = 0.0
        _HeightBias ("HeightBias", Range(0.1, 1.0)) = 0.2
        
        [Toggle(EnalbeCliffRender)]_EnableCliffRender ("开启峭壁三向渲染", float) = 0
        _CliffBlend ("Cliff Blend", Range(0, 1)) = 0.2
    }
    SubShader
    {
        Tags { "Queue" = "Geometry-100" "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Cull Back
            ZTest LEqual
            ZWrite On
            Blend One Zero

            HLSLPROGRAM

            #pragma target 4.5
            
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            //--------------------------------------
            // Shader Feature
            #pragma shader_feature _ EnableCliffRender
            #pragma shader_feature _TERRAIN_BLEND_HEIGHT

            #include "./../HLSLIncludes/Lighting/HMK_LightingEquation.hlsl"
            #include "./../HLSLIncludes/Common/HMK_Normal.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag

            #include "./HMK_TerrainLit_Input.hlsl"
            #include "./HMK_TerrainLit_LitPass.hlsl"
            
            
            ENDHLSL

        }

        // Pass
        // {
        //     Name "ShadowCaster"
        //     Tags { "LightMode" = "ShadowCaster" }

        //     ZWrite On // the only goal of this pass is to write depth!
        //     ZTest LEqual // early exit at Early-Z stage if possible
        //     ColorMask 0 // we don't care about color, we just want to write depth, ColorMask 0 will save some write bandwidth
        //     Cull front // support Cull[_Cull] requires "flip vertex normal" using VFACE in fragment shader, which is maybe beyond the scope of a simple tutorial shader

        //     HLSLPROGRAM

        //     #pragma target 4.5

        //     // -------------------------------------
        //     // Material Keywords
        //     #pragma shader_feature_local_fragment _ALPHATEST_ON
        //     #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        //     //--------------------------------------
        //     // GPU Instancing
        //     #pragma multi_compile_instancing
        //     #pragma multi_compile _ DOTS_INSTANCING_ON

        //     #pragma vertex ShadowPassVertex
        //     #pragma fragment ShadowPassFragment
        //     #pragma enable_cbuffer

        //     #include "./../Base/HMK_Lit_Input.hlsl"
        //     #include "./../Base/HMK_ShadowCasterPass.hlsl"

        //     ENDHLSL

        // }



        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM

            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            #pragma enable_cbuffer

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "./HMK_TerrainLit_Input.hlsl"
            #include "./HMK_TerrainLit_DepthPass.hlsl"


            // #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"

            ENDHLSL

        }
    }


    FallBack "Diffuse"
    CustomEditor "HMKTerrainShaderGUI"
}
