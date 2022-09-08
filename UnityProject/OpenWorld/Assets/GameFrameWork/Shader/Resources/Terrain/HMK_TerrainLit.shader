Shader "HMK/Terrain/Lit"
{
    Properties
    {
        [HideInInspector] _Control0 ("Control0 (RGBA)", 2D) = "red" { }
        [HideInInspector] _Control1 ("Control1 (RGBA)", 2D) = "red" { }
        [HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "grey" { }
        [HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "grey" { }
        [HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "grey" { }
        [HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "grey" { }
        [HideInInspector] _Splat4 ("Layer 5 (R)", 2D) = "grey" { }
        [HideInInspector] _Splat5 ("Layer 6 (G)", 2D) = "grey" { }
        [HideInInspector] _Splat6 ("Layer 6 (B)", 2D) = "grey" { }
        [HideInInspector] _Splat7 ("Layer 7 (A)", 2D) = "grey" { }

        [HideInInspector] _NRA0 ("NRA0", 2D) = "bump" { }
        [HideInInspector] _NRA1 ("NRA1", 2D) = "bump" { }
        [HideInInspector] _NRA2 ("NRA2", 2D) = "bump" { }
        [HideInInspector] _NRA3 ("NRA3", 2D) = "bump" { }
        [HideInInspector] _NRA4 ("NRA4", 2D) = "bump" { }
        [HideInInspector] _NRA5 ("NRA5", 2D) = "bump" { }
        [HideInInspector] _NRA6 ("NRA6", 2D) = "bump" { }
        [HideInInspector] _NRA7 ("NRA7", 2D) = "bump" { }
        
        _RoughnessScale ("RoughnessScale", range(0, 3)) = 1
        _OcclusionScale ("OcclusionScale", range(0, 3)) = 1
        _UVScale ("贴图 UVScale", Range(0.001, 1)) = 0.2

        [Toggle(_TERRAIN_BLEND_HEIGHT)] _EnableHeightBlend ("EnableHeightBlend", Float) = 0.0
        _HeightBias ("HeightBias", Range(0.1, 1.0)) = 0.2
        // Layer count is passed down to guide height-blend enable/disable, due
        // to the fact that heigh-based blend will be broken with multipass.
        [HideInInspector] [PerRendererData] _NumLayersCount ("Total Layer Count", Float) = 1.0


        // [HideInInspector] _TerrainHolesTexture ("Holes Map (RGB)", 2D) = "white" { }
        // [ToggleUI] _EnableInstancedPerPixelNormal ("Enable Instanced per-pixel normal", Float) = 1.0

    }

    HLSLINCLUDE

    #pragma multi_compile_fragment __ _ALPHATEST_ON

    ENDHLSL

    SubShader
    {
        Tags { "Queue" = "Geometry-100" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "False" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            // Cull Off

            HLSLPROGRAM

            #pragma target 3.0

            #pragma vertex vert
            #pragma fragment frag

            // #define _METALLICSPECGLOSSMAP 1
            // #define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            // #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            // #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #pragma shader_feature_local _TERRAIN_BLEND_HEIGHT
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _MASKMAP
            // Sample normal in pixel shader when doing instancing
            #pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            

            #include "./HMK_TerrainLit_Input.hlsl"
            #include "./HMK_TerrainLit_LitPass.hlsl"

            ENDHLSL

        }

        // Pass
        // {
        //     Name "ShadowCaster"
        //     Tags { "LightMode" = "ShadowCaster" }

        //     ZWrite On
        //     ColorMask 0

        //     HLSLPROGRAM

        //     #pragma target 2.0

        //     #pragma vertex ShadowPassVertex
        //     #pragma fragment ShadowPassFragment

        //     #pragma multi_compile_instancing
        //     #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
        //     ENDHLSL

        // }

        Pass
        {
            Name "GBuffer"
            Tags { "LightMode" = "UniversalGBuffer" }

            HLSLPROGRAM

            #pragma exclude_renderers gles
            #pragma target 3.0
            #pragma vertex SplatmapVert
            #pragma fragment SplatmapFragment

            #define _METALLICSPECGLOSSMAP 1
            #define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            //#pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #pragma shader_feature_local _TERRAIN_BLEND_HEIGHT
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _MASKMAP
            // Sample normal in pixel shader when doing instancing
            #pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL
            #define TERRAIN_GBUFFER 1

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
            ENDHLSL

        }

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

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "./HMK_TerrainLit_Input.hlsl"
            #include "./HMK_TerrainLit_DepthPass.hlsl"

            // #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"

            ENDHLSL

        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }

            ZWrite On

            HLSLPROGRAM

            #pragma target 2.0
            #pragma vertex DepthNormalOnlyVertex
            #pragma fragment DepthNormalOnlyFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
            ENDHLSL

        }

        Pass
        {
            Name "SceneSelectionPass"
            Tags { "LightMode" = "SceneSelectionPass" }

            HLSLPROGRAM

            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #define SCENESELECTIONPASS
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
            ENDHLSL

        }

        UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
    }
    Dependency "AddPassShader" = "Hidden/Universal Render Pipeline/Terrain/Lit (Add Pass)"
    Dependency "BaseMapShader" = "Hidden/Universal Render Pipeline/Terrain/Lit (Base Pass)"
    Dependency "BaseMapGenShader" = "Hidden/Universal Render Pipeline/Terrain/Lit (Basemap Gen)"

    // CustomEditor "UnityEditor.Rendering.Universal.TerrainLitShaderGUI"

    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
